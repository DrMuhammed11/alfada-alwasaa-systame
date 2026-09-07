import {
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  Res,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { SseConnectionsService } from './sse-connections.service';
import { NotificationsQueryDto } from './dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';
import type { Response } from 'express';

/**
 * صندوق الإشعارات — خدمات ذاتية لكل مستخدم (لا تحتاج صلاحية خاصة،
 * مثل «مهامي» و«إحالاتي»): كل مستخدم يرى إشعاراته فقط.
 *
 * يشمل بث SSE للإشعارات الحية بدل استطلاع كل 15 ثانية.
 */
@ApiTags('الإشعارات')
@ApiBearerAuth()
@Controller()
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly sseConnections: SseConnectionsService,
  ) {}

  /**
   * بث SSE للإشعارات الحية — يُبقي الاتصال مفتوحًا ويبث الإشعارات فوريًا.
   * الأحداث المبثوثة:
   *   - new-notification: إشعار جديد (بالبيانات الكاملة)
   *   - unread-count: عدد غير المقروء المحدّث { count: number }
   */
  @Get('notifications/stream')
  @ApiOperation({ summary: 'بث SSE للإشعارات الحية — يُبقي الاتصال مفتوحًا' })
  @Header('Cache-Control', 'no-cache')
  @Header('X-Accel-Buffering', 'no')
  stream(@CurrentUser() user: AuthUser, @Res() res: Response) {
    // إعداد رؤوس SSE
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    // تسجيل الاتصال
    this.sseConnections.add(user.id, res);

    // إرسال عدد غير المقروء فورًا
    this.notificationsService.unreadCount(user.id).then((result) => {
      if (!res.writableEnded) {
        res.write(`event: unread-count\ndata: ${JSON.stringify(result)}\n\n`);
      }
    }).catch(() => {});

    // نبضة حياة كل 30 ثانية لمنع قطع الاتصال
    const heartbeat = setInterval(() => {
      if (!res.writableEnded) {
        res.write(': heartbeat\n\n');
      }
    }, 30000);

    // تنظيف عند إغلاق الاتصال
    res.on('close', () => {
      clearInterval(heartbeat);
      this.sseConnections.remove(user.id, res);
    });
  }

  @Get('notifications/my')
  @ApiOperation({ summary: 'إشعاراتي — الأحدث أولًا (تصفية: غير المقروء / النوع)' })
  mine(@Query() dto: NotificationsQueryDto, @CurrentUser() user: AuthUser) {
    return this.notificationsService.findMine(dto, user);
  }

  @Get('notifications/unread-count')
  @ApiOperation({ summary: 'عدد إشعاراتي غير المقروءة — شارة الجرس' })
  unreadCount(@CurrentUser('id') userId: string) {
    return this.notificationsService.unreadCount(userId);
  }

  @Patch('notifications/read-all')
  @ApiOperation({ summary: 'وسم كل إشعاراتي كمقروءة' })
  markAllRead(@CurrentUser() user: AuthUser) {
    return this.notificationsService.markAllRead(user);
  }

  @Patch('notifications/:id/read')
  @ApiOperation({ summary: 'وسم إشعار واحد كمقروء' })
  markRead(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.notificationsService.markRead(id, user);
  }
}
