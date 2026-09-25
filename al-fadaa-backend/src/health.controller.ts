import { Controller, Get, Optional, Res } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Public } from './common/decorators/public.decorator';
import { OutboxService } from './outbox/outbox.service';
import { PrismaService } from './prisma/prisma.service';

@ApiTags('الصحة')
@Controller('health')
export class HealthController {
  constructor(
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly prisma?: PrismaService,
  ) {}

  /**
   * فحص الصحة الحقيقي:
   * - يفحص قاعدة البيانات فعليًا بـ SELECT 1 (لا يُخفى فشلها خلف قيمة افتراضية)
   * - الإنذار المبكر لأحداث Outbox المعلقة
   * يرد بـ 200 عند السلامة و503 عند فشل قاعدة البيانات (للـ readiness probe).
   */
  @Public()
  @Get()
  @ApiOperation({ summary: 'فحص جاهزية الخادم وقاعدة البيانات والإنذار المبكر للأحداث المعلقة' })
  async check(@Res() res: Response): Promise<void> {
    let dbOk = false;
    let dbError: string | undefined;
    if (this.prisma) {
      try {
        await this.prisma.$queryRaw`SELECT 1`;
        dbOk = true;
      } catch (e) {
        dbError = (e as Error).message;
      }
    }

    let outboxHealth:
      | { pendingOlderThan1h: number; status: 'healthy' | 'warning'; warning?: string }
      | undefined;

    if (this.outbox) {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const pendingOlder = await this.outbox.countPendingOlderThan(oneHourAgo).catch(() => 0);
      outboxHealth = {
        pendingOlderThan1h: pendingOlder,
        status: pendingOlder > 0 ? 'warning' : 'healthy',
        ...(pendingOlder > 0
          ? { warning: `يوجد ${pendingOlder} حدث معلق في صندوق الـ Outbox لأكثر من ساعة` }
          : {}),
      };
    }

    const status = !dbOk ? 'error' : outboxHealth?.status === 'warning' ? 'warning' : 'ok';

    res.status(dbOk ? 200 : 503).json({
      status,
      database: { ok: dbOk, ...(dbError ? { error: dbError } : {}) },
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      ...(outboxHealth ? { outbox: outboxHealth } : {}),
    });
  }
}
