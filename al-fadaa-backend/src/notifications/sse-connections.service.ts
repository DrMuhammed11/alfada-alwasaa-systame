import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import type { Response } from 'express';
import { SsePubSubService } from './sse-pubsub.service';

/**
 * خدمة إدارة اتصالات Server-Sent Events (SSE).
 * تتعقب الاتصالات النشطة لكل مستخدم وتبث الأحداث الفورية.
 * - حد أقصى 3 اتصالات متزامنة لكل مستخدم (يُغلَق الأقدم عند التجاوز).
 * - تنظيف تلقائي عند إغلاق الاتصال.
 * - متكاملة مع SsePubSubService لدعم التوسع العنقودي ومجموعات الخوادم الموزعة.
 */
@Injectable()
export class SseConnectionsService implements OnModuleInit {
  private readonly logger = new Logger('SSE');
  private readonly connections = new Map<string, Response[]>();
  private readonly MAX_PER_USER = 3;

  constructor(@Optional() private readonly pubSub?: SsePubSubService) {}

  onModuleInit(): void {
    if (this.pubSub) {
      this.pubSub.subscribe((msg) => {
        this.deliverLocally(msg.userIds, msg.event, msg.data);
      });
    }
  }

  /** تسجيل اتصال SSE جديد لمستخدم — إغلاق الأقدم عند تجاوز الحد */
  add(userId: string, res: Response): void {
    let userConns = this.connections.get(userId);
    if (!userConns) {
      userConns = [];
      this.connections.set(userId, userConns);
    }

    // إغلاق الأقدم عند تجاوز الحد
    while (userConns.length >= this.MAX_PER_USER) {
      const oldest = userConns.shift();
      if (oldest && !oldest.writableEnded) {
        try { oldest.end(); } catch {}
      }
    }

    userConns.push(res);
  }

  /** إزالة اتصال مغلق */
  remove(userId: string, res: Response): void {
    const userConns = this.connections.get(userId);
    if (!userConns) return;

    const idx = userConns.indexOf(res);
    if (idx !== -1) {
      userConns.splice(idx, 1);
    }
    if (userConns.length === 0) {
      this.connections.delete(userId);
    }
  }

  /** بث حدث SSE لمستخدم محدد (عبر الوسيط الموزع إذا كان متاحاً) */
  sendToUser(userId: string, event: string, data: unknown): void {
    this.sendToUsers([userId], event, data);
  }

  /** بث حدث لعدة مستخدمين عبر الوسيط الموزع ليتم تسليمها لكافة نُسخ الخادم */
  sendToUsers(userIds: string[], event: string, data: unknown): void {
    const unique = [...new Set(userIds.filter(Boolean))];
    if (unique.length === 0) return;

    if (this.pubSub) {
      this.pubSub.publish(unique, event, data).catch((err) => {
        this.logger.error(`فشل نشر رسالة SSE عبر الوسيط: ${(err as Error).message}`);
        // سقوط احتياطي فوري للتسليم المحلي
        this.deliverLocally(unique, event, data);
      });
    } else {
      this.deliverLocally(unique, event, data);
    }
  }

  /** التسليم الفعلي على المقابس المتصلة محلياً بهذه النسخة من الخادم */
  deliverLocally(userIds: string[], event: string, data: unknown): void {
    const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;

    for (const uid of userIds) {
      const userConns = this.connections.get(uid);
      if (!userConns || userConns.length === 0) continue;

      const dead: Response[] = [];
      for (const res of userConns) {
        try {
          if (!res.writableEnded) {
            res.write(payload);
          } else {
            dead.push(res);
          }
        } catch {
          dead.push(res);
        }
      }

      for (const d of dead) {
        this.remove(uid, d);
      }
    }
  }

  /** عدد الاتصالات النشطة على هذه النسخة (للمراقبة) */
  get totalConnections(): number {
    let count = 0;
    for (const conns of this.connections.values()) {
      count += conns.length;
    }
    return count;
  }
}
