import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditAction, NotificationType, ReferralStatus, ReplyStatus, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { AuthUser } from '../common/types';
import { CreateDelegationDto } from './dto/create-delegation.dto';

@Injectable()
export class DelegationService {
  private readonly logger = new Logger('DelegationService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * إنشاء تفويض جديد مع فحص كافة القيود:
   * 1. المفوِّض من (GM / DEPUTY_GM / DEPT_MANAGER)
   * 2. المفوَّل إليه بدور مسموح وفق مصفوفة الأدوار
   * 3. منع التفويض للنفس
   * 4. منع التفويض الدائري
   * 5. منع تداخل فترتين نشطتين لنفس المفوِّض
   */
  async create(dto: CreateDelegationDto, user: AuthUser) {
    const delegatorId =
      user.role === Role.ADMIN && dto.delegatorId ? dto.delegatorId : user.id;

    if (delegatorId === dto.delegateId) {
      throw new BadRequestException('لا يمكن تفويض الصلاحيات لنفسك');
    }

    const delegator = await this.prisma.user.findUnique({
      where: { id: delegatorId },
    });
    if (!delegator || !delegator.isActive) {
      throw new NotFoundException('المستخدم المفوِّض غير موجود أو غير نشط');
    }

    const allowedDelegatorRoles: Role[] = [Role.GM, Role.DEPUTY_GM, Role.DEPT_MANAGER];
    if (!allowedDelegatorRoles.includes(delegator.role)) {
      throw new BadRequestException('فقط الإدارة العليا ومدراء الأقسام يملكون صلاحية التفويض');
    }

    const delegate = await this.prisma.user.findUnique({
      where: { id: dto.delegateId },
    });
    if (!delegate || !delegate.isActive) {
      throw new BadRequestException('المستخدم المفوَّل إليه غير موجود أو غير نشط');
    }

    // التحقق من مصفوفة الأدوار المسموح بها للتفويض
    this.assertAllowedDelegateRole(delegator.role, delegate.role, delegator.departmentId, delegate.departmentId);

    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);

    if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime())) {
      throw new BadRequestException('صيغة التواريخ غير صحيحة');
    }

    if (startsAt >= endsAt) {
      throw new BadRequestException('تاريخ انتهاء التفويض يجب أن يكون بعد تاريخ البدء');
    }

    // منع التفويض الدائري (المفوَّل إليه لديه تفويض نشط للمفوِّض)
    const circular = await this.prisma.delegation.findFirst({
      where: {
        delegatorId: dto.delegateId,
        delegateId: delegatorId,
        active: true,
        endsAt: { gte: new Date() },
      },
    });
    if (circular) {
      throw new BadRequestException('لا يمكن إنشاء تفويض دائري متبادل بين نفس المستخدمين');
    }

    // منع تداخل فترتين نشطتين لنفس المفوِّض
    const overlapping = await this.prisma.delegation.findFirst({
      where: {
        delegatorId,
        active: true,
        startsAt: { lte: endsAt },
        endsAt: { gte: startsAt },
      },
    });
    if (overlapping) {
      throw new BadRequestException('يوجد تفويض نشط آخر يتداخل مع هذه الفترة لنفس المفوِّض');
    }

    const delegation = await this.prisma.delegation.create({
      data: {
        delegatorId,
        delegateId: dto.delegateId,
        startsAt,
        endsAt,
        reason: dto.reason,
        active: true,
      },
      include: {
        delegator: { select: { id: true, name: true, role: true, email: true } },
        delegate: { select: { id: true, name: true, role: true, email: true } },
      },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Delegation',
      entityId: delegation.id,
      summary: `تفويض صلاحيات من «${delegator.name}» إلى «${delegate.name}»`,
      metadata: {
        delegatorId,
        delegateId: dto.delegateId,
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        reason: dto.reason,
      },
    });

    // إشعار الوكيل بالتفويض الجديد
    await this.notifications.notify({
      userId: dto.delegateId,
      type: NotificationType.NEW_TASK,
      title: `تم تفويضك رسميًا من «${delegator.name}»`,
      body: `تم تفويضك للقيام بمهام «${delegator.name}» في الفترة من ${startsAt.toLocaleDateString('ar-SA')} إلى ${endsAt.toLocaleDateString('ar-SA')}`,
      link: `/delegations/for-me`,
      entityType: 'Delegation',
      entityId: delegation.id,
    });

    return delegation;
  }

  /** إنهاء التفويض مبكرًا */
  async terminate(id: string, user: AuthUser) {
    const delegation = await this.prisma.delegation.findUnique({
      where: { id },
      include: {
        delegator: { select: { id: true, name: true, email: true } },
        delegate: { select: { id: true, name: true, email: true } },
      },
    });
    if (!delegation) throw new NotFoundException('التفويض غير موجود');

    if (user.role !== Role.ADMIN && delegation.delegatorId !== user.id) {
      throw new ForbiddenException('فقط المفوِّض أو مسؤول النظام يمكنه إنهاء التفويض');
    }

    const updated = await this.prisma.delegation.update({
      where: { id },
      data: { active: false },
      include: {
        delegator: { select: { id: true, name: true, email: true } },
        delegate: { select: { id: true, name: true, email: true } },
      },
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Delegation',
      entityId: id,
      summary: `إنهاء تفويض «${delegation.delegate.name}» نيابة عن «${delegation.delegator.name}»`,
      metadata: { delegationId: id, terminatedBy: user.email },
    });

    // إرسال ملخص إداري للمفوِّض بالعمليات التي نُفِّذت
    await this.sendDelegationSummary(delegation);

    return updated;
  }

  /** استعراض التفويضات الممنوحة مني */
  async findMy(user: AuthUser) {
    return this.prisma.delegation.findMany({
      where: { delegatorId: user.id },
      include: {
        delegate: { select: { id: true, name: true, role: true, email: true, jobTitle: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** استعراض التفويضات الممنوحة لي (أنا الوكيل فيها) */
  async findForMe(user: AuthUser) {
    const now = new Date();
    return this.prisma.delegation.findMany({
      where: {
        delegateId: user.id,
        active: true,
        endsAt: { gte: now },
      },
      include: {
        delegator: { select: { id: true, name: true, role: true, email: true, jobTitle: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** استعراض كافة التفويضات — للأدمن */
  async findAll(user: AuthUser) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('فقط مسؤول النظام يمكنه استعراض سجل كافة التفويضات');
    }
    return this.prisma.delegation.findMany({
      include: {
        delegator: { select: { id: true, name: true, role: true, email: true } },
        delegate: { select: { id: true, name: true, role: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** فحص انتهاء الصلاحية وإرسال الإشعار التلخيصي دوريًا */
  @Cron(CronExpression.EVERY_HOUR)
  async handleExpiredDelegations() {
    const now = new Date();
    const expired = await this.prisma.delegation.findMany({
      where: {
        active: true,
        endsAt: { lte: now },
      },
      include: {
        delegator: { select: { id: true, name: true, email: true } },
        delegate: { select: { id: true, name: true, email: true } },
      },
    });

    for (const d of expired) {
      try {
        await this.prisma.delegation.update({
          where: { id: d.id },
          data: { active: false },
        });
        await this.sendDelegationSummary(d);
      } catch (e) {
        this.logger.error(`فشل إنهاء التفويض منتهي الصلاحية ${d.id}: ${(e as Error).message}`);
      }
    }
  }

  /** إرسال إشعار تلخيصي للمفوِّض عند انتهاء فترة الوكالة */
  async sendDelegationSummary(d: {
    id: string;
    delegatorId: string;
    delegateId: string;
    startsAt: Date;
    endsAt: Date;
    delegator: { name: string };
    delegate: { name: string };
  }) {
    // 1. عدد الردود التي اعتمدها الوكيل نيابة عن المفوِّض
    const approvedCount = await this.prisma.auditLog.count({
      where: {
        action: AuditAction.APPROVE,
        entityType: 'Reply',
        createdAt: { gte: d.startsAt },
        metadata: {
          path: ['delegatorId'],
          equals: d.delegatorId,
        },
      },
    });

    // 2. عدد المسودات المعلقة بانتظار الاعتماد المتبقية
    const pendingRepliesCount = await this.prisma.reply.count({
      where: {
        status: ReplyStatus.SUBMITTED,
      },
    });

    const summaryText = `اعتمد «${d.delegate.name}» نيابة عنك ${approvedCount} ردود، وبقيت ${pendingRepliesCount} مسودة بانتظارك`;

    await this.notifications.notify({
      userId: d.delegatorId,
      type: NotificationType.NEW_TASK,
      title: 'انتهاء فترة التفويض وعودة الصلاحيات',
      body: summaryText,
      link: '/dashboard',
      entityType: 'Delegation',
      entityId: d.id,
    });
  }

  /** التحقق من مطابقة الدور لمصفوفة الصلاحيات */
  private assertAllowedDelegateRole(
    delegatorRole: Role,
    delegateRole: Role,
    delegatorDeptId?: string | null,
    delegateDeptId?: string | null,
  ) {
    if (delegatorRole === Role.GM) {
      if (delegateRole !== Role.DEPUTY_GM && delegateRole !== Role.DEPT_MANAGER) {
        throw new BadRequestException('المدير العام يفوِّض نائبه أو أحد مدراء الأقسام فقط');
      }
    } else if (delegatorRole === Role.DEPUTY_GM) {
      if (delegateRole !== Role.DEPT_MANAGER && delegateRole !== Role.GM) {
        throw new BadRequestException('نائب المدير العام يفوِّض مدراء الأقسام فقط');
      }
    } else if (delegatorRole === Role.DEPT_MANAGER) {
      if (delegateRole === Role.EMPLOYEE) {
        if (delegatorDeptId && delegateDeptId && delegatorDeptId !== delegateDeptId) {
          throw new BadRequestException('مدير القسم يفوِّض موظفًا من نفس قسمه فقط');
        }
      } else if (delegateRole !== Role.DEPT_MANAGER) {
        throw new BadRequestException('مدير القسم يفوِّض مدير قسم آخر أو موظفًا من قسمه فقط');
      }
    }
  }
}
