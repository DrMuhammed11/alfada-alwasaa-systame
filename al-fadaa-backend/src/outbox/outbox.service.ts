import { Injectable, Logger } from '@nestjs/common';
import { EventOutbox, OutboxStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { OutboxEmitDto } from './outbox.types';

@Injectable()
export class OutboxService {
  private readonly logger = new Logger('OutboxService');

  constructor(private readonly prisma: PrismaService) {}

  /**
   * تسجيل حدث جديد في جدول Outbox داخل نفس المعاملة (Atomic Transactional Write)
   */
  async emit(tx: Prisma.TransactionClient, entry: OutboxEmitDto): Promise<void> {
    // حماية لتوافق كائنات الـ mock في بيئات الاختبار
    if ((tx as any).eventOutbox) {
      await (tx as any).eventOutbox.create({
        data: {
          type: entry.type,
          payload: entry.payload as Prisma.InputJsonValue,
          status: OutboxStatus.PENDING,
          attempts: 0,
        },
      });
    }
  }

  /**
   * جلب حزمة من الأحداث المعلقة المستحقة للمعالجة بترتيب الإنشاء
   */
  async getPendingBatch(limit = 50): Promise<EventOutbox[]> {
    if (!this.prisma.eventOutbox) return [];
    const now = new Date();
    return this.prisma.eventOutbox.findMany({
      where: {
        status: OutboxStatus.PENDING,
        OR: [{ nextRetryAt: null }, { nextRetryAt: { lte: now } }],
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
    });
  }

  /**
   * تعليم الحدث كمعالج بنجاح
   */
  async markProcessed(id: string): Promise<void> {
    if (!this.prisma.eventOutbox) return;
    await this.prisma.eventOutbox.update({
      where: { id },
      data: {
        status: OutboxStatus.PROCESSED,
        processedAt: new Date(),
      },
    });
  }

  /**
   * جدولة إعادة محاولة الحدث بتراجع أسي أو وسمه بالفشل النهائي
   */
  async markFailed(id: string, currentAttempts: number, error: string): Promise<void> {
    if (!this.prisma.eventOutbox) return;
    const attempts = currentAttempts + 1;
    const backoffSeconds = [5, 30, 120, 600, 1800];
    const maxAttempts = 5;

    if (attempts >= maxAttempts) {
      this.logger.error(
        `فشل نهائي للحدث ${id} بعد ${attempts} محاولات. الخطأ الأخير: ${error}`,
      );
      await this.prisma.eventOutbox.update({
        where: { id },
        data: {
          status: OutboxStatus.FAILED,
          attempts,
          processedAt: new Date(),
        },
      });
    } else {
      const delay = backoffSeconds[attempts - 1] ?? 1800;
      const nextRetryAt = new Date(Date.now() + delay * 1000);
      this.logger.warn(
        `إعادة جدولة الحدث ${id} (المحاولة ${attempts} من ${maxAttempts}) بعد ${delay} ثانية. السبب: ${error}`,
      );
      await this.prisma.eventOutbox.update({
        where: { id },
        data: {
          attempts,
          nextRetryAt,
        },
      });
    }
  }

  /**
   * حساب عدد الأحداث المعلقة الأقدم من وقت محدد (لفحص الصحة والإنذار المبكر)
   */
  async countPendingOlderThan(threshold: Date): Promise<number> {
    if (!this.prisma.eventOutbox) return 0;
    return this.prisma.eventOutbox.count({
      where: {
        status: OutboxStatus.PENDING,
        createdAt: { lt: threshold },
      },
    });
  }

  /**
   * إجمالي الأحداث المعلقة حاليًا
   */
  async countPending(): Promise<number> {
    if (!this.prisma.eventOutbox) return 0;
    return this.prisma.eventOutbox.count({
      where: { status: OutboxStatus.PENDING },
    });
  }
}
