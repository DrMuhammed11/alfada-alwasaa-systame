import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OutboxService } from './outbox.service';
import { OutboxPayload } from './outbox.types';

@Injectable()
export class OutboxProcessor {
  private readonly logger = new Logger('OutboxProcessor');
  private isProcessing = false;

  constructor(
    private readonly outbox: OutboxService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * معالج دوري يقرأ الأحداث المعلقة كل 5 ثوانٍ وينفذ التدقيق والإشعارات
   */
  @Cron(CronExpression.EVERY_5_SECONDS)
  async handleScheduledOutbox(): Promise<void> {
    await this.processPendingEvents();
  }

  /**
   * تشغيل فوري للمعالجة عند إصدار حدث لتسريع التفاعل الحي
   */
  trigger(): void {
    setImmediate(() => {
      this.processPendingEvents().catch(() => {});
    });
  }

  /**
   * معالجة الأحداث المعلقة بترتيب الإنشاء
   */
  async processPendingEvents(batchSize = 50): Promise<number> {
    if (this.isProcessing) return 0;
    this.isProcessing = true;
    let processedCount = 0;

    try {
      const events = await this.outbox.getPendingBatch(batchSize);
      for (const event of events) {
        try {
          const payload = event.payload as unknown as OutboxPayload;

          // 1. تنفيذ سجل التدقيق (إن وجد)
          if (payload?.audit) {
            await this.audit.log(payload.audit);
          }

          // 2. إرسال الإشعارات وبث SSE (إن وجد)
          if (payload?.notification) {
            const notif = payload.notification;
            if (notif.recipientIds && notif.recipientIds.length > 0) {
              await this.notifications.notifyMany(notif.recipientIds, {
                type: notif.type,
                title: notif.title,
                body: notif.body,
                link: notif.link,
                entityType: notif.entityType,
                entityId: notif.entityId,
              });
            } else if (notif.userId) {
              await this.notifications.notify({
                userId: notif.userId,
                type: notif.type,
                title: notif.title,
                body: notif.body,
                link: notif.link,
                entityType: notif.entityType,
                entityId: notif.entityId,
              });
            }
          }

          // 3. تعليم الحدث كمعالج بنجاح
          await this.outbox.markProcessed(event.id);
          processedCount++;
        } catch (err) {
          const errorMsg = (err as Error).message || 'Unknown error';
          this.logger.error(`فشل في معالجة حدث الـ Outbox [${event.id}]: ${errorMsg}`);
          await this.outbox.markFailed(event.id, event.attempts, errorMsg);
        }
      }
    } finally {
      this.isProcessing = false;
    }

    return processedCount;
  }
}
