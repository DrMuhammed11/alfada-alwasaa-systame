import { Injectable, Logger, NotFoundException, OnModuleDestroy, OnModuleInit, Optional } from '@nestjs/common';
import { AuditAction, NotificationType, OutboxMail, OutboxMailStatus, Role } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import type { SendReplyOptions } from './mail.service';

export interface QueuedMail {
  id: string;
  opts: SendReplyOptions;
  attempts: number;
  maxAttempts: number;
  lastError: string;
  nextRetryAt: Date;
  createdAt: Date;
}

/**
 * خدمة استرداد وإعادة محاولة إرسال البريد الصادر —
 * تحمي النظام من فقدان الردود الرسمية للعملاء عند حدوث انقطاع مؤقت في خادم SMTP.
 * مدعومة بجدول قاعدة بيانات دائم (OutboxMail) للتوزيع والمقاومة ضد انهيار الخادم،
 * مع تطبيق خوارزمية التراجع الأسي (Exponential Backoff):
 *  - المحاولة الأولى: بعد دقيقة واحدة
 *  - المحاولة الثانية: بعد 5 دقائق
 *  - المحاولة الثالثة: بعد 15 دقيقة (الحد الأقصى الافتراضي: 3 محاولات)
 * وفي حال الفشل النهائي بعد استنفاد المحاولات:
 *  - يتم إرسال إشعار عاجل للمدير العام (GM)
 *  - توثيق الفشل النهائي في سجل التدقيق غير القابل للتعديل
 */
@Injectable()
export class MailRetryService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('MailRetry');
  private readonly queue = new Map<string, QueuedMail>();
  private retryTimer: NodeJS.Timeout | null = null;
  private isProcessing = false;
  private senderFn: ((opts: SendReplyOptions) => Promise<boolean>) | null = null;

  /** فترات التراجع الأسي (بالميلي ثانية) */
  private readonly BACKOFF_INTERVALS_MS = [
    60 * 1000,        // المحاولة 1: بعد دقيقة
    5 * 60 * 1000,    // المحاولة 2: بعد 5 دقائق
    15 * 60 * 1000,   // المحاولة 3: بعد 15 دقيقة
  ];

  constructor(
    @Optional() private readonly prisma?: PrismaService,
    @Optional() private readonly notifications?: NotificationsService,
    @Optional() private readonly audit?: AuditService,
  ) {}

  onModuleInit(): void {
    // فحص دوري لقائمة الانتظار كل 30 ثانية
    this.retryTimer = setInterval(() => {
      this.processQueue().catch((err) => {
        this.logger.error(`خطأ أثناء معالجة قائمة استرداد البريد: ${(err as Error).message}`);
      });
    }, 30000);
  }

  onModuleDestroy(): void {
    if (this.retryTimer) {
      clearInterval(this.retryTimer);
      this.retryTimer = null;
    }
    this.queue.clear();
  }

  /** تسجيل دالة الإرسال الفعلية من MailService */
  registerSender(fn: (opts: SendReplyOptions) => Promise<boolean>): void {
    this.senderFn = fn;
  }

  /**
   * إدراج رسالة فاشلة في قائمة الاسترداد لإعادة المحاولة.
   * تحفظ في الذاكرة وفي قاعدة البيانات الدائمة (OutboxMail).
   */
  async enqueue(opts: SendReplyOptions, error: string, maxAttempts = 3): Promise<void> {
    const key = opts.refNumber || `${opts.to}-${Date.now()}`;
    const existing = this.queue.get(key);

    // 1. تحديث قائمة الذاكرة (للتوافق الفوري مع الاختبارات والعمليات السريعة)
    if (existing) {
      existing.attempts += 1;
      existing.lastError = error;
      if (existing.attempts >= existing.maxAttempts) {
        this.logger.error(
          `وصل البريد ${opts.refNumber} للحد الأقصى من محاولات الإرسال (${existing.maxAttempts}) — تم إلغاء المحاولات. الخطأ: ${error}`,
        );
        this.queue.delete(key);
      } else {
        const backoffIndex = Math.min(existing.attempts - 1, this.BACKOFF_INTERVALS_MS.length - 1);
        const delay = this.BACKOFF_INTERVALS_MS[backoffIndex];
        existing.nextRetryAt = new Date(Date.now() + delay);
        this.logger.warn(
          `إعادة جدولة البريد ${opts.refNumber} (المحاولة ${existing.attempts + 1} من ${existing.maxAttempts}) بعد ${delay / 1000} ثانية`,
        );
      }
    } else {
      const delay = this.BACKOFF_INTERVALS_MS[0];
      const item: QueuedMail = {
        id: key,
        opts,
        attempts: 1,
        maxAttempts,
        lastError: error,
        nextRetryAt: new Date(Date.now() + delay),
        createdAt: new Date(),
      };
      this.queue.set(key, item);
      this.logger.warn(
        `تم حفظ البريد ${opts.refNumber} في قائمة الاسترداد لإعادة المحاولة الأولى بعد ${delay / 1000} ثانية (السبب: ${error})`,
      );
    }

    // 2. الحفظ الدائم في جدول OutboxMail إذا كانت Prisma متوفرة
    if (this.prisma) {
      try {
        await this.persistEnqueue(opts, error, maxAttempts);
      } catch (e) {
        this.logger.error(`فشل حفظ البريد في جدول OutboxMail: ${(e as Error).message}`);
      }
    }
  }

  /**
   * حفظ أو تحديث حالة الرسالة في جدول OutboxMail
   */
  private async persistEnqueue(opts: SendReplyOptions, error: string, maxAttempts: number): Promise<void> {
    if (!this.prisma) return;
    const now = new Date();
    const delay = this.BACKOFF_INTERVALS_MS[0];
    const nextRetryAt = new Date(now.getTime() + delay);

    // البحث عن رسالة موجودة قيد الانتظار لنفس رقم المرجع
    const existing = opts.refNumber
      ? await this.prisma.outboxMail.findFirst({
          where: {
            refNumber: opts.refNumber,
            status: { in: [OutboxMailStatus.QUEUED, OutboxMailStatus.PAUSED] },
          },
          orderBy: { createdAt: 'desc' },
        })
      : null;

    if (existing) {
      const attempts = existing.attempts + 1;
      const targetMax = existing.maxAttempts || maxAttempts;

      if (attempts >= targetMax) {
        await this.prisma.outboxMail.update({
          where: { id: existing.id },
          data: {
            attempts,
            status: OutboxMailStatus.FAILED,
            lastError: error,
          },
        });
        await this.notifyFailure(existing.refNumber, existing.to, error, existing.id);
      } else {
        const backoffIndex = Math.min(attempts - 1, this.BACKOFF_INTERVALS_MS.length - 1);
        const backoffDelay = this.BACKOFF_INTERVALS_MS[backoffIndex];
        await this.prisma.outboxMail.update({
          where: { id: existing.id },
          data: {
            attempts,
            lastError: error,
            nextRetryAt: new Date(now.getTime() + backoffDelay),
            status: OutboxMailStatus.QUEUED,
          },
        });
      }
    } else {
      await this.prisma.outboxMail.create({
        data: {
          replyId: opts.replyId ?? null,
          refNumber: opts.refNumber || 'UNKNOWN',
          to: opts.to ?? '',
          subject: opts.subject,
          body: opts.body,
          html: opts.html ?? null,
          attachments: opts.attachments ? (opts.attachments as any) : undefined,
          attempts: 1,
          maxAttempts,
          nextRetryAt,
          status: OutboxMailStatus.QUEUED,
          lastError: error,
        },
      });
    }
  }

  /**
   * معالجة كافة الرسائل المستحقة لإعادة المحاولة.
   * يدعم التوزيع المتعدد (Multi-Instance Concurrency) بأقفال تفاؤلية آمنة.
   */
  async processQueue(): Promise<void> {
    if (this.isProcessing || !this.senderFn) return;
    this.isProcessing = true;

    try {
      if (this.prisma) {
        await this.processDatabaseQueue();
      } else {
        await this.processMemoryQueue();
      }
    } finally {
      this.isProcessing = false;
    }
  }

  /** معالجة القائمة الدائمة من قاعدة البيانات مع أقفال التوزيع المتعدد */
  private async processDatabaseQueue(): Promise<void> {
    if (!this.prisma || !this.senderFn) return;
    const now = new Date();

    const candidates = await this.prisma.outboxMail.findMany({
      where: {
        status: OutboxMailStatus.QUEUED,
        nextRetryAt: { lte: now },
      },
      take: 20,
      orderBy: { nextRetryAt: 'asc' },
    });

    for (const candidate of candidates) {
      // قفل تفاؤلي آمن: تأجيل وقت المحاولة مؤقتاً لتجنب قيام مثيل آخر بمعالجة نفس الرسالة
      const claim = await this.prisma.outboxMail.updateMany({
        where: {
          id: candidate.id,
          status: OutboxMailStatus.QUEUED,
          nextRetryAt: candidate.nextRetryAt,
        },
        data: {
          nextRetryAt: new Date(Date.now() + 5 * 60 * 1000), // حجز لـ 5 دقائق
        },
      });

      if (claim.count === 0) {
        // تم حجزها من قِبل عامل آخر
        continue;
      }

      const opts: SendReplyOptions = {
        to: candidate.to,
        subject: candidate.subject ?? '',
        body: candidate.body ?? '',
        refNumber: candidate.refNumber,
        replyId: candidate.replyId ?? undefined,
        html: candidate.html ?? undefined,
        attachments: candidate.attachments as any,
      };

      try {
        const success = await this.senderFn(opts);
        if (success) {
          await this.prisma.outboxMail.update({
            where: { id: candidate.id },
            data: {
              status: OutboxMailStatus.SENT,
              sentAt: new Date(),
            },
          });
          this.logger.log(`نجحت إعادة إرسال البريد ${candidate.refNumber} بنجاح ✅`);
          this.queue.delete(candidate.refNumber);
        } else {
          await this.handleFailedCandidate(candidate, 'فشلت محاولة الإرسال بدون استثناء');
        }
      } catch (e) {
        await this.handleFailedCandidate(candidate, (e as Error).message);
      }
    }
  }

  /** معالجة الفشل لرسالة معينة من جدول قاعدة البيانات */
  private async handleFailedCandidate(candidate: OutboxMail, error: string): Promise<void> {
    if (!this.prisma) return;
    const newAttempts = candidate.attempts + 1;
    const maxAttempts = candidate.maxAttempts || 3;

    if (newAttempts >= maxAttempts) {
      await this.prisma.outboxMail.update({
        where: { id: candidate.id },
        data: {
          attempts: newAttempts,
          status: OutboxMailStatus.FAILED,
          lastError: error,
        },
      });
      this.logger.error(
        `وصل البريد ${candidate.refNumber} للحد الأقصى من محاولات الإرسال (${maxAttempts}) — تم تعيين الحالة FAILED`,
      );
      this.queue.delete(candidate.refNumber);
      await this.notifyFailure(candidate.refNumber, candidate.to, error, candidate.id);
    } else {
      const backoffIndex = Math.min(newAttempts - 1, this.BACKOFF_INTERVALS_MS.length - 1);
      const delay = this.BACKOFF_INTERVALS_MS[backoffIndex];
      await this.prisma.outboxMail.update({
        where: { id: candidate.id },
        data: {
          attempts: newAttempts,
          lastError: error,
          nextRetryAt: new Date(Date.now() + delay),
          status: OutboxMailStatus.QUEUED,
        },
      });
      this.logger.warn(
        `إعادة جدولة البريد ${candidate.refNumber} (المحاولة ${newAttempts + 1} من ${maxAttempts}) بعد ${delay / 1000} ثانية`,
      );
    }
  }

  /** معالجة القائمة المحلية في الذاكرة (للاختبارات وبيئات التطوير بدون DB) */
  private async processMemoryQueue(): Promise<void> {
    if (this.queue.size === 0 || !this.senderFn) return;
    const now = new Date();
    const candidates: QueuedMail[] = [];

    for (const item of this.queue.values()) {
      if (now >= item.nextRetryAt) {
        candidates.push(item);
      }
    }

    for (const item of candidates) {
      this.logger.log(
        `محاولة إعادة إرسال البريد ${item.opts.refNumber} إلى ${item.opts.to} (محاولة رقم ${item.attempts})...`,
      );

      try {
        const success = await this.senderFn(item.opts);
        if (success) {
          this.logger.log(`نجحت إعادة إرسال البريد ${item.opts.refNumber} بنجاح ✅`);
          this.queue.delete(item.id);
        } else {
          this.enqueue(item.opts, 'فشلت محاولة الإرسال بدون استثناء');
        }
      } catch (e) {
        this.enqueue(item.opts, (e as Error).message);
      }
    }
  }

  /** إرسال إشعار عاجل للمدير العام وتوثيق الفشل النهائي في سجل التدقيق */
  private async notifyFailure(refNumber: string, to: string, error: string, outboxId: string): Promise<void> {
    const alertMessage = `⚠️ رد رسمي معتمد لم يصل العميل: رقم [${refNumber}]، الجهة [${to}]، سبب الفشل: [${error}]`;
    this.logger.error(alertMessage);

    if (this.notifications && this.prisma) {
      try {
        const gms = await this.prisma.user.findMany({
          where: { role: Role.GM, isActive: true },
          select: { id: true },
        });
        if (gms.length > 0) {
          await this.notifications.notifyMany(
            gms.map((gm) => gm.id),
            {
              type: NotificationType.REPLY_SENT,
              title: `⚠️ تعذر إرسال رد رسمي للعميل: ${refNumber}`,
              body: alertMessage,
              link: '/correspondences',
              entityType: 'OutboxMail',
              entityId: outboxId,
            },
          );
        }
      } catch (e) {
        this.logger.error(`تعذر إشعار المدير العام بالفشل النهائي: ${(e as Error).message}`);
      }
    }

    if (this.audit) {
      try {
        await this.audit.log({
          action: AuditAction.SEND,
          entityType: 'OutboxMail',
          entityId: outboxId,
          summary: alertMessage,
          metadata: {
            refNumber,
            to,
            lastError: error,
            permanentFailure: true,
          },
        });
      } catch (e) {
        this.logger.error(`تعذر توثيق الفشل النهائي في سجل التدقيق: ${(e as Error).message}`);
      }
    }
  }

  /**
   * إرسال مُتتبَّع لرسالة صادر مسجلة مسبقًا في جدول OutboxMail (داخل معاملة الحالة):
   * النجاح يوسمها SENT، والفشل يبدأ دورة التراجع الأسي على نفس الصف.
   * هذا يجعل الإرسال محصّنًا من انهيار العملية: الصف موجود قبل أي محاولة إرسال،
   * فلا يُفقد رد رسمي لعميل مهما حدث بين الالتزام والإرسال.
   */
  async attemptTrackedSend(outboxMailId: string, opts: SendReplyOptions): Promise<void> {
    if (!this.prisma) return;
    const mail = await this.prisma.outboxMail.findUnique({ where: { id: outboxMailId } });
    if (!mail) return;

    if (!this.senderFn) {
      // وضع تجريبي بدون مُرسل — يُعتبر مُسلَّمًا (نفس دلالات console mode)
      await this.prisma.outboxMail.update({
        where: { id: mail.id },
        data: { status: OutboxMailStatus.SENT, sentAt: new Date() },
      });
      return;
    }

    try {
      const success = await this.senderFn(opts);
      if (success) {
        await this.prisma.outboxMail.update({
          where: { id: mail.id },
          data: { status: OutboxMailStatus.SENT, sentAt: new Date() },
        });
        this.logger.log(`تم إرسال البريد المتتبَّع ${mail.refNumber} بنجاح ✅`);
        this.queue.delete(mail.refNumber);
      } else {
        await this.handleFailedCandidate(mail, 'فشلت محاولة الإرسال بدون استثناء');
      }
    } catch (e) {
      await this.handleFailedCandidate(mail, (e as Error).message);
    }
  }

  // ─────────────── وظائف الإدارة والتحكم الإداري ───────────────

  /** استرجاع قائمة الرسائل في الصادر مع الفلترة والترقيم */
  async getOutboxList(filter: {
    status?: OutboxMailStatus;
    refNumber?: string;
    page?: number;
    limit?: number;
  }) {
    if (!this.prisma) {
      const items = Array.from(this.queue.values());
      return {
        items,
        total: items.length,
        page: 1,
        limit: 20,
        totalPages: 1,
      };
    }

    const page = Math.max(Number(filter.page) || 1, 1);
    const limit = Math.min(Math.max(Number(filter.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filter.status) where.status = filter.status;
    if (filter.refNumber) where.refNumber = { contains: filter.refNumber, mode: 'insensitive' };

    const [items, total] = await Promise.all([
      this.prisma.outboxMail.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reply: {
            select: {
              id: true,
              version: true,
              correspondence: {
                select: { id: true, refNumber: true, subject: true },
              },
            },
          },
        },
      }),
      this.prisma.outboxMail.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /** إعادة محاولة إرسال رسالة صادر يدويًا من قبل الأدمن */
  async retryManually(id: string): Promise<OutboxMail> {
    if (!this.prisma) throw new NotFoundException('خدمة قاعدة البيانات غير مهيأة');

    const mail = await this.prisma.outboxMail.findUnique({ where: { id } });
    if (!mail) throw new NotFoundException('رسالة الصادر غير موجودة');

    const updated = await this.prisma.outboxMail.update({
      where: { id },
      data: {
        status: OutboxMailStatus.QUEUED,
        attempts: 0,
        nextRetryAt: new Date(),
      },
    });

    // معالجة فورية غير متزامنة في الخلفية
    this.processQueue().catch((err) => {
      this.logger.error(`خطأ أثناء معالجة إعادة الإرسال اليدوي: ${(err as Error).message}`);
    });

    return updated;
  }

  /** إيقاف إعادة المحاولة مؤقتًا لرسالة صادر */
  async pauseMail(id: string): Promise<OutboxMail> {
    if (!this.prisma) throw new NotFoundException('خدمة قاعدة البيانات غير مهيأة');

    const mail = await this.prisma.outboxMail.findUnique({ where: { id } });
    if (!mail) throw new NotFoundException('رسالة الصادر غير موجودة');

    return this.prisma.outboxMail.update({
      where: { id },
      data: {
        status: OutboxMailStatus.PAUSED,
      },
    });
  }

  /** الاستعلام عن حالة قائمة الاسترداد للمراقبة الإدارية */
  getQueueStatus(): {
    pendingCount: number;
    items: {
      id: string;
      refNumber: string;
      to: string | null;
      attempts: number;
      nextRetryAt: Date;
      lastError: string;
    }[];
  } {
    return {
      pendingCount: this.queue.size,
      items: Array.from(this.queue.values()).map((q) => ({
        id: q.id,
        refNumber: q.opts.refNumber,
        to: q.opts.to,
        attempts: q.attempts,
        nextRetryAt: q.nextRetryAt,
        lastError: q.lastError,
      })),
    };
  }

  /** تفريغ القائمة (لأغراض الاختبار والتحكم) */
  clearQueue(): void {
    this.queue.clear();
  }

  /** عدد العناصر الحالية في قائمة الذاكرة */
  get pendingCount(): number {
    return this.queue.size;
  }
}

