import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
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
import { buildPageMeta } from '../common/types';
import {
  CorrespondencesQueryDto,
  CreateIncomingDto,
  CreateInternalDto,
  UpdateCorrespondenceDto,
} from './dto';
import { RefNumberService } from './ref-number.service';
import { NotificationsService } from '../notifications/notifications.service';

const USER_BRIEF = { id: true, name: true, email: true } as const;

/** حقول القائمة المختصرة */
const LIST_INCLUDE = {
  department: { select: { id: true, name: true } },
  createdBy: { select: { id: true, name: true } },
  children: {
    select: { id: true, refNumber: true, createdAt: true, body: true },
    orderBy: { createdAt: 'desc' },
    take: 1,
  },
  _count: {
    select: {
      referrals: true,
      tasks: true,
      replies: true,
      attachments: true,
      children: true,
    },
  },
} satisfies Prisma.CorrespondenceInclude;

/** حقول التفاصيل الكاملة — تعرض سلسلة المحادثة كاملة بالتسلسل الزمني */
const DETAIL_INCLUDE = {
  department: { select: { id: true, name: true } },
  createdBy: { select: { id: true, name: true } },
  parent: {
    select: {
      id: true,
      refNumber: true,
      subject: true,
      body: true,
      priority: true,
      status: true,
      type: true,
      senderName: true,
      senderEmail: true,
      senderPhone: true,
      receivedAt: true,
      sentAt: true,
      createdAt: true,
      messageId: true,
      sourceReplyId: true,
      attachments: true,
    },
  },
  children: {
    select: {
      id: true,
      refNumber: true,
      subject: true,
      body: true,
      priority: true,
      status: true,
      type: true,
      senderName: true,
      senderEmail: true,
      senderPhone: true,
      receivedAt: true,
      sentAt: true,
      createdAt: true,
      messageId: true,
      sourceReplyId: true,
      attachments: true,
    },
    orderBy: { createdAt: 'asc' },
  },
  referrals: {
    include: { fromUser: { select: USER_BRIEF }, toUser: { select: USER_BRIEF } },
  },
  tasks: {
    include: {
      assignedTo: { select: USER_BRIEF },
      assignedBy: { select: USER_BRIEF },
    },
  },
  replies: {
    include: {
      author: { select: USER_BRIEF },
      reviewedBy: { select: USER_BRIEF },
      approvedBy: { select: USER_BRIEF },
      attachments: true,
    },
    orderBy: { createdAt: 'asc' },
  },
  attachments: true,
} satisfies Prisma.CorrespondenceInclude;

export type CorrespondenceListRow = Prisma.CorrespondenceGetPayload<{
  include: typeof LIST_INCLUDE;
}>;
export type CorrespondenceDetailRow = Prisma.CorrespondenceGetPayload<{
  include: typeof DETAIL_INCLUDE;
}>;

@Injectable()
export class CorrespondencesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

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

  // ─────────────── الاستعراض (بنطاق حسب الدور) ───────────────

  /**
   * نطاق الرؤية:
   *  - ADMIN / GM / DEPUTY_GM : كل المراسلات
   *  - DEPT_MANAGER           : مراسلات قسمه + ما أُحيل إليه + ما كوّن تكليفاته
   *  - EMPLOYEE               : ما كُلّف به أو أُحيل إليه أو صاغ ردوده فقط
   */
  private buildScope(user: AuthUser): Prisma.CorrespondenceWhereInput {
    if (user.role === 'ADMIN' || user.role === 'GM' || user.role === 'DEPUTY_GM') {
      return {};
    }
    if (user.role === 'DEPT_MANAGER') {
      const or: Prisma.CorrespondenceWhereInput[] = [
        { referrals: { some: { toUserId: user.id } } },
        { tasks: { some: { assignedById: user.id } } },
      ];
      if (user.departmentId) or.push({ departmentId: user.departmentId });
      return { OR: or };
    }
    // EMPLOYEE
    return {
      OR: [
        { tasks: { some: { assignedToId: user.id } } },
        { referrals: { some: { toUserId: user.id } } },
        { replies: { some: { authorId: user.id } } },
      ],
    };
  }

  async findAll(
    dto: CorrespondencesQueryDto,
    user: AuthUser,
  ): Promise<Paginated<CorrespondenceListRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    const filters: Prisma.CorrespondenceWhereInput[] = [this.buildScope(user)];
    // حصر القائمة في المحادثات الجذرية فقط حتى لا تتكرر الردود في صندوق البريد كبنود منفصلة
    filters.push({ parentId: null });

    if (dto.type) filters.push({ type: dto.type });
    if (dto.status) filters.push({ status: dto.status });
    if (dto.priority) filters.push({ priority: dto.priority });
    if (dto.departmentId) filters.push({ departmentId: dto.departmentId });
    if (dto.q) {
      filters.push({
        OR: [
          { subject: { contains: dto.q, mode: 'insensitive' } },
          { refNumber: { contains: dto.q, mode: 'insensitive' } },
          { senderName: { contains: dto.q, mode: 'insensitive' } },
        ],
      });
    }
    const where: Prisma.CorrespondenceWhereInput = { AND: filters };

    const [total, data] = await this.prisma.$transaction([
      this.prisma.correspondence.count({ where }),
      this.prisma.correspondence.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: LIST_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  /** تفاصيل مراسلة — مع فرض نطاق الرؤية نفسه */
  async findOne(id: string, user: AuthUser): Promise<CorrespondenceDetailRow> {
    const corr = await this.prisma.correspondence.findUnique({
      where: { id },
      include: DETAIL_INCLUDE,
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');
    if (!(await this.canView(corr, user))) {
      throw new ForbiddenException('ليست لديك صلاحية الاطلاع على هذه المراسلة');
    }
    return corr;
  }

  /** فحص صلاحية الاطلاع على مراسلة محددة (تُستخدم أيضًا من وحدات أخرى) */
  async canView(
    corr: { id: string; departmentId: string | null },
    user: AuthUser,
  ): Promise<boolean> {
    if (user.role === 'ADMIN' || user.role === 'GM' || user.role === 'DEPUTY_GM') {
      return true;
    }
    const [assigned, referred, replied] = await Promise.all([
      this.prisma.task.count({
        where: { correspondenceId: corr.id, assignedToId: user.id },
      }),
      this.prisma.referral.count({
        where: { correspondenceId: corr.id, toUserId: user.id },
      }),
      this.prisma.reply.count({
        where: { correspondenceId: corr.id, authorId: user.id },
      }),
    ]);
    if (assigned + referred + replied > 0) return true;

    if (user.role === 'DEPT_MANAGER') {
      if (corr.departmentId && corr.departmentId === user.departmentId) return true;
      const createdByMe = await this.prisma.task.count({
        where: { correspondenceId: corr.id, assignedById: user.id },
      });
      return createdByMe > 0;
    }
    return false;
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
