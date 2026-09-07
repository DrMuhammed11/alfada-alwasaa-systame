import { Global, Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { SseConnectionsService } from './sse-connections.service';

/**
 * وحدة الإشعارات — وحدة عامة (Global) تمامًا مثل وحدة التدقيق،
 * لأن كل وحدات الأعمال (الإحالات / التكليفات / الردود / المراسلات)
 * تُطلق إشعاراتها من داخل خدماتها دون الحاجة لاستيراد الوحدة في كل مكان.
 *
 * تشمل خدمة SSE لبث الإشعارات الحية فوريًا.
 */
@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, SseConnectionsService],
  exports: [NotificationsService, SseConnectionsService],
})
export class NotificationsModule {}
