import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AuditAction,
  CorrespondenceStatus,
  Prisma,
  ReplyStatus,
  Role,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CorrespondenceAction,
  assertTransition,
  getNextStatus,
} from '../workflow/correspondence-state-machine';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import {
  CreateReplyDto,
  DirectReplyDto,
  RejectReplyDto,
  RepliesQueryDto,
  UpdateReplyDto,
} from './dto';
import { REPLY_INCLUDE, ReplyRow, USER_BRIEF } from './replies.constants';
import { RepliesApprovalService } from './replies-approval.service';
import { RepliesSendService } from './replies-send.service';

export { USER_BRIEF, REPLY_INCLUDE, ReplyRow } from './replies.constants';

@Injectable()
export class RepliesService {
  private readonly approvalService: RepliesApprovalService;
  private readonly sendService: RepliesSendService;

  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly correspondences: CorrespondencesService,
    private readonly mail: MailService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
    @Optional() approvalService?: RepliesApprovalService,
    @Optional() sendService?: RepliesSendService,
  ) {
    this.approvalService =
      approvalService ??
      new RepliesApprovalService(this.prisma, this.audit, this.notifications);
    this.sendService =
      sendService ??
      new RepliesSendService(
        this.prisma,
        this.refNumbers,
        this.correspondences,
        this.mail,
        this.audit,
        this.notifications,
        this.config,
      );
  }

  // ─────────────── إنشاء وتعديل المسودات ───────────────

  /** إنشاء مسودة رد — بعد التحقق من نطاق رؤية المراسلة وصلاحية صياغتها */
  async create(dto: CreateReplyDto, user: AuthUser): Promise<ReplyRow> {
    await this.correspondences.findOne(dto.correspondenceId, user); // 404 / 403
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: dto.correspondenceId },
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    assertTransition(corr.status, CorrespondenceAction.START_DRAFT);

    let taskId: string | null = dto.taskId ?? null;
    if (taskId) {
      const task = await this.prisma.task.findUnique({ where: { id: taskId } });
      if (!task || task.correspondenceId !== corr.id) {
        throw new BadRequestException('التكليف المحدد لا ينتمي لهذه المراسلة');
      }
      if (task.assignedToId !== user.id && user.role === Role.EMPLOYEE) {
        throw new ForbiddenException('يمكنك إعداد الرد لتكليفاتك فقط');
      }
    }

    const reply = await this.prisma.reply.create({
      data: {
        correspondenceId: corr.id,
        taskId,
        authorId: user.id,
        body: dto.body,
      },
      include: REPLY_INCLUDE,
    });

    // أول مسودة → المراسلة تدخل مرحلة «جاري إعداد الرد»
    if (corr.status === CorrespondenceStatus.REFERRED) {
      const nextStatus = getNextStatus(corr.status, CorrespondenceAction.START_DRAFT);
      if (nextStatus) {
        await this.prisma.correspondence.update({
          where: { id: corr.id },
          data: { status: nextStatus },
        });
      }
    }

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Reply',
      entityId: reply.id,
      summary: `إنشاء مسودة رد على المراسلة ${corr.refNumber}`,
      metadata: { correspondenceRef: corr.refNumber },
    });
    return reply;
  }

  /** تعديل المسودة — صاحبها فقط، وفي حالتي DRAFT أو REJECTED (بعد الرفض) */
  async update(id: string, dto: UpdateReplyDto, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: REPLY_INCLUDE,
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    if (reply.authorId !== user.id) {
      throw new ForbiddenException('فقط صاحب المسودة يمكنه تعديلها');
    }
    if (reply.status !== ReplyStatus.DRAFT && reply.status !== ReplyStatus.REJECTED) {
      throw new BadRequestException('لا يمكن تعديل رد مرفوع للاعتماد أو معتمد');
    }

    const updated = await this.prisma.reply.update({
      where: { id },
      data: {
        body: dto.body,
        status: ReplyStatus.DRAFT,
        version: { increment: 1 },
        submittedAt: null,
        reviewedById: null,
        reviewNote: null,
      },
      include: REPLY_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Reply',
      entityId: id,
      summary: `تعديل مسودة الرد (الإصدار ${updated.version}) على المراسلة ${reply.correspondence.refNumber}`,
    });
    return updated;
  }

  // ─────────────── تفويض دورة الاعتماد ───────────────

  /** رفع المسودة للاعتماد — صاحبها فقط */
  submit(id: string, user: AuthUser): Promise<ReplyRow> {
    return this.approvalService.submit(id, user);
  }

  /** اعتماد الرد — لا يجوز اعتماد رد صاغه المعتمد بنفسه */
  approve(id: string, user: AuthUser): Promise<ReplyRow> {
    return this.approvalService.approve(id, user);
  }

  /** رفض الرد مع سبب — يعود للموظف لتعديله */
  reject(id: string, dto: RejectReplyDto, user: AuthUser): Promise<ReplyRow> {
    return this.approvalService.reject(id, dto, user);
  }

  // ─────────────── تفويض الإرسال ───────────────

  /** الإرسال النهائي — حصري للمدير العام (صلاحية CORR_SEND) */
  send(id: string, user: AuthUser): Promise<{ success: boolean; sent: true; refNumber: string }> {
    return this.sendService.send(id, user);
  }

  /** إرسال رد مباشر وفوري للعميل عبر البريد الإلكتروني */
  sendDirect(
    dto: DirectReplyDto,
    user: AuthUser,
  ): Promise<{ success: boolean; sent: true; refNumber: string; reply: ReplyRow }> {
    return this.sendService.sendDirect(dto, user);
  }

  // ─────────────── الاستعراض ───────────────

  /** ردودي أو ردود مراسلة محددة (مع فرض نطاق الرؤية) */
  async findAll(dto: RepliesQueryDto, user: AuthUser): Promise<Paginated<ReplyRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    let where: Prisma.ReplyWhereInput = {};
    if (dto.correspondenceId) {
      await this.correspondences.findOne(dto.correspondenceId, user);
      where = { correspondenceId: dto.correspondenceId };
    } else {
      where = { authorId: user.id };
    }
    if (dto.status) where.status = dto.status;

    const [total, data] = await this.prisma.$transaction([
      this.prisma.reply.count({ where }),
      this.prisma.reply.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: REPLY_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  async findOne(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: REPLY_INCLUDE,
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    if (reply.authorId !== user.id) {
      await this.correspondences.findOne(reply.correspondenceId, user);
    }
    return reply;
  }
}
