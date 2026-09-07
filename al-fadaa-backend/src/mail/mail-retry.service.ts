import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
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
 * تطبق خوارزمية التراجع الأسي (Exponential Backoff):
 *  - المحاولة الأولى: بعد دقيقة واحدة
 *  - المحاولة الثانية: بعد 5 دقائق
 *  - المحاولة الثالثة: بعد 15 دقيقة (الحد الأقصى الافتراضي: 3 محاولات)
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
   * إدراج رسالة فاشلة في قائمة الاسترداد لإعادة المحاولة
   */
  enqueue(opts: SendReplyOptions, error: string, maxAttempts = 3): void {
    const key = opts.refNumber || `${opts.to}-${Date.now()}`;
    const existing = this.queue.get(key);

    if (existing) {
      existing.attempts += 1;
      existing.lastError = error;
      if (existing.attempts >= existing.maxAttempts) {
        this.logger.error(
          `وصل البريد ${opts.refNumber} للحد الأقصى من محاولات الإرسال (${existing.maxAttempts}) — تم إلغاء المحاولات. الخطأ: ${error}`,
        );
        this.queue.delete(key);
        return;
      }
      const backoffIndex = Math.min(existing.attempts - 1, this.BACKOFF_INTERVALS_MS.length - 1);
      const delay = this.BACKOFF_INTERVALS_MS[backoffIndex];
      existing.nextRetryAt = new Date(Date.now() + delay);
      this.logger.warn(
        `إعادة جدولة البريد ${opts.refNumber} (المحاولة ${existing.attempts + 1} من ${existing.maxAttempts}) بعد ${delay / 1000} ثانية`,
      );
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
  }

  /**
   * معالجة كافة الرسائل المستحقة لإعادة المحاولة
   */
  async processQueue(): Promise<void> {
    if (this.isProcessing || this.queue.size === 0 || !this.senderFn) return;
    this.isProcessing = true;

    try {
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
    } finally {
      this.isProcessing = false;
    }
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

  /** عدد العناصر الحالية في القائمة */
  get pendingCount(): number {
    return this.queue.size;
  }
}
