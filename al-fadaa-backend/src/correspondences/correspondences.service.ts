import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  Prisma,
  Priority,
  Role,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser, Paginated } from '../common/types';
import {
  CorrespondencesQueryDto,
  CreateIncomingDto,
  CreateInternalDto,
  UpdateCorrespondenceDto,
} from './dto';
import { RefNumberService } from './ref-number.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CorrespondenceDetailRow,
  CorrespondenceListRow,
  DETAIL_INCLUDE,
  LIST_INCLUDE,
  USER_BRIEF,
} from './correspondences.constants';
import { CorrespondencesQueryService } from './correspondences-query.service';

export {
  USER_BRIEF,
  LIST_INCLUDE,
  DETAIL_INCLUDE,
  CorrespondenceListRow,
  CorrespondenceDetailRow,
} from './correspondences.constants';

@Injectable()
export class CorrespondencesService {
  private readonly queryService: CorrespondencesQueryService;

  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() queryService?: CorrespondencesQueryService,
  ) {
    this.queryService = queryService ?? new CorrespondencesQueryService(this.prisma);
  }

  // ─────────────── الإنشاء ───────────────

  /** تسجيل مراسلة واردة وصلت إلى بريد الشركة الموحد */
  async createIncoming(dto: CreateIncomingDto, user: AuthUser) {
    const refNumber = await this.refNumbers.generate('INC');
    const corr = await this.prisma.correspondence.create({
      data: {
        refNumber,
        type: CorrespondenceType.INCOMING,
        subject: dto.subject.trim(),
        body: dto.body ?? '',
        priority: dto.priority ?? Priority.NORMAL,
        status: CorrespondenceStatus.RECEIVED,
        senderName: dto.senderName.trim(),
        senderEmail: dto.senderEmail?.toLowerCase().trim(),
        senderPhone: dto.senderPhone,
        receivedAt: dto.receivedAt ? new Date(dto.receivedAt) : new Date(),
        createdById: user.id,
        messageId: dto.messageId ?? undefined,
        channel: dto.channel ?? undefined,
      },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `تسجيل مراسلة واردة ${refNumber} من «${corr.senderName}»`,
      metadata: {
        subject: corr.subject,
        senderEmail: corr.senderEmail,
        priority: corr.priority,
        messageId: dto.messageId,
      },
    });

    // تنبيه جميع مدراء العموم النشطين فعليًا بالوارد الجديد دون استثناء
    const gmUsers = await this.prisma.user.findMany({
      where: { role: Role.GM, isActive: true },
      select: { id: true },
    });
    const gmRecipients = gmUsers.map((g) => g.id);
    if (gmRecipients.length > 0) {
      await this.notifications.notifyIncomingRegistered({
        recipientIds: gmRecipients,
        refNumber,
        senderName: corr.senderName ?? '',
        subject: corr.subject,
        priority: corr.priority,
        correspondenceId: corr.id,
      });
    }

    return corr;
  }

  /** إنشاء تعميم داخلي بين الأقسام — ينشر فورًا دون دورة اعتماد */
  async createInternal(dto: CreateInternalDto, user: AuthUser) {
    const refNumber = await this.refNumbers.generate('INT');
    const corr = await this.prisma.correspondence.create({
      data: {
        refNumber,
        type: CorrespondenceType.INTERNAL,
        subject: dto.subject.trim(),
        body: dto.body,
        priority: dto.priority ?? Priority.NORMAL,
        status: CorrespondenceStatus.SENT,
        sentAt: new Date(),
        createdById: user.id,
        departmentId:
          user.role === 'DEPT_MANAGER' ? (user.departmentId ?? null) : null,
      },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `إنشاء تعميم داخلي ${refNumber}: ${corr.subject}`,
    });
    return corr;
  }

  // ─────────────── تفويض الاستعراض والفحص ───────────────

  /** استعراض المراسلات الجذرية بنطاق الرؤية والفلترة والترقيم */
  findAll(
    dto: CorrespondencesQueryDto,
    user: AuthUser,
  ): Promise<Paginated<CorrespondenceListRow>> {
    return this.queryService.findAll(dto, user);
  }

  /** تفاصيل مراسلة — مع فرض نطاق الرؤية نفسه */
  findOne(id: string, user: AuthUser): Promise<CorrespondenceDetailRow> {
    return this.queryService.findOne(id, user);
  }

  /** فحص صلاحية الاطلاع على مراسلة محددة (تُستخدم أيضًا من وحدات أخرى) */
  canView(
    corr: { id: string; departmentId: string | null },
    user: AuthUser,
  ): Promise<boolean> {
    return this.queryService.canView(corr, user);
  }

  // ─────────────── التعديل والإدارة ───────────────

  /** تعديل البيانات الأساسية — مسموح قبل بدء الإحالة فقط */
  async update(
    id: string,
    dto: UpdateCorrespondenceDto,
    user: AuthUser,
  ): Promise<CorrespondenceDetailRow> {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    if (
      corr.status !== CorrespondenceStatus.RECEIVED &&
      corr.status !== CorrespondenceStatus.UNDER_REVIEW
    ) {
      throw new BadRequestException(
        'لا يمكن تعديل بيانات المراسلة بعد بدء الإحالة — التعديلات تتم من الرد',
      );
    }

    const data: Prisma.CorrespondenceUpdateInput = {};
    if (dto.subject) data.subject = dto.subject.trim();
    if (dto.body !== undefined) data.body = dto.body;
    if (dto.priority) data.priority = dto.priority;
    if (dto.senderName !== undefined) data.senderName = dto.senderName;
    if (dto.senderEmail !== undefined) data.senderEmail = dto.senderEmail;
    if (dto.senderPhone !== undefined) data.senderPhone = dto.senderPhone;
    if (
      dto.status === CorrespondenceStatus.UNDER_REVIEW &&
      corr.status === CorrespondenceStatus.RECEIVED
    ) {
      data.status = CorrespondenceStatus.UNDER_REVIEW;
    }

    const updated = await this.prisma.correspondence.update({
      where: { id },
      data,
      include: DETAIL_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Correspondence',
      entityId: id,
      summary: `تعديل بيانات المراسلة ${corr.refNumber}`,
      metadata: { updatedFields: Object.keys(dto) },
    });
    return updated;
  }

  /** إغلاق المراسلة (بدون رد أو بعد اكتمال المعالجة) */
  async close(id: string, user: AuthUser) {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    const closable: CorrespondenceStatus[] = [
      CorrespondenceStatus.RECEIVED,
      CorrespondenceStatus.UNDER_REVIEW,
      CorrespondenceStatus.SENT,
    ];

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.correspondence.updateMany({
        where: { id, status: { in: closable } },
        data: { status: CorrespondenceStatus.CLOSED, closedAt: new Date() },
      });
      if (res.count === 0) {
        const current = await tx.correspondence.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('المراسلة غير موجودة');
        throw new BadRequestException(
          `لا يمكن إغلاق المراسلة — حالتها الحالية «${current.status}» ونُفِّذت للتو عملية أخرى عليها`,
        );
      }
      return tx.correspondence.findUniqueOrThrow({
        where: { id },
        include: DETAIL_INCLUDE,
      });
    });

    await this.audit.log({
      action: AuditAction.CLOSE,
      entityType: 'Correspondence',
      entityId: id,
      summary: `إغلاق المراسلة ${corr.refNumber}`,
    });
    return updated;
  }

  /** أرشفة المراسلة — الخطوة الأخيرة في دورة الحياة */
  async archive(id: string, user: AuthUser) {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    const archivable: CorrespondenceStatus[] = [
      CorrespondenceStatus.RECEIVED,
      CorrespondenceStatus.UNDER_REVIEW,
      CorrespondenceStatus.SENT,
      CorrespondenceStatus.CLOSED,
    ];

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.correspondence.updateMany({
        where: { id, status: { in: archivable } },
        data: { status: CorrespondenceStatus.ARCHIVED },
      });
      if (res.count === 0) {
        const current = await tx.correspondence.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('المراسلة غير موجودة');
        throw new BadRequestException(
          `لا يمكن أرشفة المراسلة — حالتها الحالية «${current.status}» ونُفِّذت للتو عملية أخرى عليها`,
        );
      }
      return tx.correspondence.findUniqueOrThrow({
        where: { id },
        include: DETAIL_INCLUDE,
      });
    });

    await this.audit.log({
      action: AuditAction.ARCHIVE,
      entityType: 'Correspondence',
      entityId: id,
      summary: `أرشفة المراسلة ${corr.refNumber}`,
    });
    return updated;
  }
}
