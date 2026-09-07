import { ForbiddenException, Injectable, Logger, NotFoundException, Optional } from '@nestjs/common';
import { NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SseConnectionsService } from './sse-connections.service';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { NotificationsQueryDto } from './dto';

/** شكل الصف الواحد كما يُعاد للعميل — بدون بيانات حساسة */
const NOTIFICATION_SELECT = {
  id: true,
  type: true,
  title: true,
  body: true,
  link: true,
  entityType: true,
  entityId: true,
  isRead: true,
  readAt: true,
  createdAt: true,
} satisfies Prisma.NotificationSelect;

export type NotificationRow = Prisma.NotificationGetPayload<{
  select: typeof NOTIFICATION_SELECT;
}>;

/** مدخل إشعار عام — يُستخدم داخليًا ومن وحدات الأعمال */
export interface NotifyEntry {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
  entityType?: string;
  entityId?: string;
}

/**
 * خدمة الإشعارات — الغراء الذي يربط دورة العمل كاملة.
 * لا يعلم الموظف أنه كُلِّف، ولا المدير أن مسودة بانتظار اعتماده،
 * إلا من خلال هذه الوحدة.
 *
 * قاعدة التصميم (مطابقة لخدمة التدقيق):
 *  فشل إرسال الإشعار يُسجَّل كخطأ ولا يرمي استثناءً أبدًا —
 *  حتى لا يتعطل عمل المستخدم الأساسي بسبب فشل التنبيه.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger('Notifications');

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly sse?: SseConnectionsService,
  ) {}

  /**
   * نقطة تحويل مركزية واحدة: تعيد الوكيل النشط إن وجد تفويض سارٍ، وإلا المستخدم نفسه
   */
  async resolveRecipient(userId: string): Promise<string> {
    try {
      const now = new Date();
      const delegation = this.prisma.delegation
        ? await this.prisma.delegation.findFirst({
            where: {
              delegatorId: userId,
              active: true,
              startsAt: { lte: now },
              endsAt: { gte: now },
            },
            select: { delegateId: true },
          })
        : null;
      return delegation ? delegation.delegateId : userId;
    } catch {
      return userId;
    }
  }

  /**
   * تحويل قائمة مستلمين مع استبدال المفوِّضين بوكلائهم وإزالة التكرار
   */
  async resolveRecipients(userIds: string[]): Promise<string[]> {
    const resolved = await Promise.all(userIds.map((id) => this.resolveRecipient(id)));
    return [...new Set(resolved.filter(Boolean))];
  }

  // ─────────────── الكتابة — من وحدات الأعمال ───────────────

  /** إرسال إشعار واحد — لا يفشل العملية التجارية أبدًا + بث SSE مع التحويل للوكيل إن وجد */
  async notify(entry: NotifyEntry): Promise<void> {
    try {
      const targetUserId = await this.resolveRecipient(entry.userId);
      const created = await this.prisma.notification.create({
        data: {
          ...entry,
          userId: targetUserId,
        },
      });

      // بث فوري عبر SSE إن توفر
      if (this.sse) {
        this.sse.sendToUser(targetUserId, 'new-notification', created);
        this.broadcastUnreadCount(targetUserId);
      }
    } catch (e) {
      this.logger.error(
        `تعذّر إرسال إشعار (${entry.type}) إلى ${entry.userId}: ${(e as Error).message}`,
      );
    }
  }

  /** إرسال نفس الإشعار لعدة مستلمين — مع إزالة التكرار وتجاهل الفارغ + بث SSE */
  async notifyMany(userIds: string[], entry: Omit<NotifyEntry, 'userId'>): Promise<void> {
    const unique = await this.resolveRecipients(userIds);
    if (unique.length === 0) return;
    try {
      await this.prisma.notification.createMany({
        data: unique.map((userId) => ({ ...entry, userId })),
      });

      // بث فوري لكل مستلم عبر SSE
      if (this.sse) {
        for (const userId of unique) {
          this.sse.sendToUser(userId, 'new-notification', {
            type: entry.type,
            title: entry.title,
            body: entry.body,
            link: entry.link,
            entityType: entry.entityType,
            entityId: entry.entityId,
            isRead: false,
            createdAt: new Date().toISOString(),
          });
          this.broadcastUnreadCount(userId);
        }
      }
    } catch (e) {
      this.logger.error(
        `تعذّر إرسال إشعارات (${entry.type}) إلى ${unique.length} مستلم: ${(e as Error).message}`,
      );
    }
  }

  /** بث عدد غير المقروء الحالي عبر SSE */
  private async broadcastUnreadCount(userId: string): Promise<void> {
    if (!this.sse) return;
    try {
      const count = await this.prisma.notification.count({
        where: { userId, isRead: false },
      });
      this.sse.sendToUser(userId, 'unread-count', { count });
    } catch {}
  }

  // ─────────────── إشعارات دورة العمل (نقاط التكامل) ───────────────

  /** وصلتك إحالة جديدة — عند إحالة المدير العام المراسلة إليك */
  async notifyReferralReceived(params: {
    toUserId: string;
    actorName: string;
    refNumber: string;
    subject: string;
    correspondenceId: string;
    note?: string | null;
    dueDate?: Date | null;
  }): Promise<void> {
    const body = [
      `أحال إليك ${params.actorName} المراسلة ${params.refNumber}: «${params.subject}»`,
      params.note ? `ملاحظة الإحالة: ${params.note}` : null,
      params.dueDate
        ? `الموعد النهائي: ${params.dueDate.toLocaleDateString('ar')}`
        : null,
    ]
      .filter(Boolean)
      .join('\n');
    await this.notify({
      userId: params.toUserId,
      type: NotificationType.NEW_REFERRAL,
      title: 'إحالة جديدة بانتظارك',
      body,
      link: `/correspondences/${params.correspondenceId}`,
      entityType: 'Correspondence',
      entityId: params.correspondenceId,
    });
  }

  /** وصلك تكليف جديد — عند تكليفك بإعداد رد أو إنجاز عمل */
  async notifyTaskAssigned(params: {
    toUserId: string;
    actorName: string;
    taskTitle: string;
    refNumber: string;
    correspondenceId: string;
    dueDate?: Date | null;
  }): Promise<void> {
    const body = [
      `كلّفك ${params.actorName} بـ«${params.taskTitle}» على المراسلة ${params.refNumber}`,
      params.dueDate
        ? `الموعد النهائي: ${params.dueDate.toLocaleDateString('ar')}`
        : null,
    ]
      .filter(Boolean)
      .join('\n');
    await this.notify({
      userId: params.toUserId,
      type: NotificationType.NEW_TASK,
      title: 'تكليف جديد بانتظارك',
      body,
      link: `/correspondences/${params.correspondenceId}`,
      entityType: 'Task',
      entityId: params.correspondenceId,
    });
  }

  /** أُلغي تكليف كان مسندًا إليك */
  async notifyTaskCancelled(params: {
    toUserId: string;
    actorName: string;
    taskTitle: string;
    correspondenceId: string;
  }): Promise<void> {
    await this.notify({
      userId: params.toUserId,
      type: NotificationType.TASK_CANCELLED,
      title: 'أُلغي تكليف',
      body: `ألغى ${params.actorName} التكليف «${params.taskTitle}»`,
      link: `/correspondences/${params.correspondenceId}`,
      entityType: 'Task',
      entityId: params.correspondenceId,
    });
  }

  /**
   * مسودة رد مرفوعة للاعتماد — يُنبَّه من يملك الاعتماد أو بانتظار النتيجة:
   *  منشئ التكليف + مُحوِّلو الإحالات المفتوحة (مع إزالة التكرار واستثناء الكاتب)
   */
  async notifyReplySubmitted(params: {
    recipientIds: string[];
    authorName: string;
    refNumber: string;
    subject: string;
    correspondenceId: string;
    replyId: string;
  }): Promise<void> {
    await this.notifyMany(params.recipientIds, {
      type: NotificationType.REPLY_SUBMITTED,
      title: 'رد بانتظار الاعتماد',
      body: `رفع ${params.authorName} مسودة رد على المراسلة ${params.refNumber}: «${params.subject}»`,
      link: `/replies/${params.replyId}`,
      entityType: 'Reply',
      entityId: params.replyId,
    });
  }

  /** اعتُمد رد أعددته — جاهز للإرسال من البريد الرسمي */
  async notifyReplyApproved(params: {
    toUserId: string;
    approverName: string;
    refNumber: string;
    correspondenceId: string;
    replyId: string;
  }): Promise<void> {
    await this.notify({
      userId: params.toUserId,
      type: NotificationType.REPLY_APPROVED,
      title: 'اعتُمد ردك',
      body: `اعتمد ${params.approverName} ردك على المراسلة ${params.refNumber}`,
      link: `/replies/${params.replyId}`,
      entityType: 'Reply',
      entityId: params.replyId,
    });
  }

  /** رُفض رد أعددته — يعود إليك مسودة مع سبب الرفض */
  async notifyReplyRejected(params: {
    toUserId: string;
    reviewerName: string;
    refNumber: string;
    note: string;
    correspondenceId: string;
    replyId: string;
  }): Promise<void> {
    await this.notify({
      userId: params.toUserId,
      type: NotificationType.REPLY_REJECTED,
      title: 'رُفض ردك — يحتاج تعديلًا',
      body: `رفض ${params.reviewerName} ردك على المراسلة ${params.refNumber}\nسبب الرفض: ${params.note}`,
      link: `/replies/${params.replyId}`,
      entityType: 'Reply',
      entityId: params.replyId,
    });
  }

  /** أُرسل للعميل رد مرتبط بعملك — من بريد الشركة الموحد */
  async notifyReplySent(params: {
    recipientIds: string[];
    outRefNumber: string;
    inRefNumber: string;
    toEmail: string;
    correspondenceId: string;
  }): Promise<void> {
    await this.notifyMany(params.recipientIds, {
      type: NotificationType.REPLY_SENT,
      title: 'أُرسل الرد للعميل',
      body: `أُرسل الرد ${params.outRefNumber} على المراسلة ${params.inRefNumber} إلى ${params.toEmail} من بريد الشركة الرسمي`,
      link: `/correspondences/${params.correspondenceId}`,
      entityType: 'Correspondence',
      entityId: params.correspondenceId,
    });
  }

  /** مراسلة واردة جديدة سُجلت — يُنبَّه المدير العام (إن لم يكن هو المسجل) */
  async notifyIncomingRegistered(params: {
    recipientIds: string[];
    refNumber: string;
    senderName: string;
    subject: string;
    priority: string;
    correspondenceId: string;
  }): Promise<void> {
    const urgent = ['HIGH', 'URGENT'].includes(params.priority);
    await this.notifyMany(params.recipientIds, {
      type: NotificationType.NEW_INCOMING,
      title: urgent ? 'مراسلة واردة عاجلة' : 'مراسلة واردة جديدة',
      body: `${params.refNumber} من «${params.senderName}»: «${params.subject}»`,
      link: `/correspondences/${params.correspondenceId}`,
      entityType: 'Correspondence',
      entityId: params.correspondenceId,
    });
  }

  // ─────────────── صندوق الإشعارات — خدمات ذاتية ───────────────

  /** إشعاراتي — الأحدث أولًا، مع تصفية (غير المقروء / النوع) */
  async findMine(
    dto: NotificationsQueryDto,
    user: AuthUser,
  ): Promise<Paginated<NotificationRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    const where: Prisma.NotificationWhereInput = {
      userId: user.id,
      ...(dto.unreadOnly ? { isRead: false } : {}),
      ...(dto.type ? { type: dto.type } : {}),
    };

    const [total, data] = await this.prisma.$transaction([
      this.prisma.notification.count({ where }),
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: NOTIFICATION_SELECT,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  /** عدد الإشعارات غير المقروءة — لشارة الجرس في الواجهة */
  async unreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }

  /** وسم إشعار واحد كمقروء — صاحبه فقط (العملية متكررة الأمان idempotent) */
  async markRead(id: string, user: AuthUser): Promise<NotificationRow> {
    const owned = await this.prisma.notification.findUnique({
      where: { id },
      select: { userId: true, isRead: true },
    });
    if (!owned) throw new NotFoundException('الإشعار غير موجود');
    if (owned.userId !== user.id) {
      throw new ForbiddenException('هذا الإشعار لا يخصك');
    }

    if (owned.isRead) {
      // مقروء سابقًا — لا خطأ، نعيد الصف كما هو (idempotent)
      return this.prisma.notification.findUniqueOrThrow({
        where: { id },
        select: NOTIFICATION_SELECT,
      });
    }

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true, readAt: new Date() },
      select: NOTIFICATION_SELECT,
    });
  }

  /** وسم كل إشعاراتي كمقروءة — زر «تحديد الكل كمقروء» */
  async markAllRead(user: AuthUser): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { userId: user.id, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
    return { updated: result.count };
  }
}
