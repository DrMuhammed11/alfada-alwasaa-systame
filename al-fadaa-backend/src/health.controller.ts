import { Controller, Get, Optional } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from './common/decorators/public.decorator';
import { OutboxService } from './outbox/outbox.service';

@ApiTags('الصحة')
@Controller('health')
export class HealthController {
  constructor(@Optional() private readonly outbox?: OutboxService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'فحص جاهزية الخادم والإنذار المبكر للأحداث المعلقة' })
  async check(): Promise<{
    status: string;
    uptime: number;
    timestamp: string;
    outbox?: {
      pendingOlderThan1h: number;
      status: 'healthy' | 'warning';
      warning?: string;
    };
  }> {
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

    return {
      status: outboxHealth?.status === 'warning' ? 'warning' : 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      ...(outboxHealth ? { outbox: outboxHealth } : {}),
    };
  }
}
