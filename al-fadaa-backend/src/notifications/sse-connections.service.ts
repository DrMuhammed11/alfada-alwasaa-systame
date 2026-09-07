import { Injectable, Logger } from '@nestjs/common';
import type { Response } from 'express';

/**
 * خدمة إدارة اتصالات Server-Sent Events (SSE).
 * تتعقب الاتصالات النشطة لكل مستخدم وتبث الأحداث الفورية.
 * - حد أقصى 3 اتصالات متزامنة لكل مستخدم (يُغلَق الأقدم عند التجاوز).
 * - تنظيف تلقائي عند إغلاق الاتصال.
 */
@Injectable()
export class SseConnectionsService {
  private readonly logger = new Logger('SSE');
  private readonly connections = new Map<string, Response[]>();
  private readonly MAX_PER_USER = 3;

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

  /** بث حدث SSE لجميع اتصالات مستخدم محدد */
  sendToUser(userId: string, event: string, data: unknown): void {
    const userConns = this.connections.get(userId);
    if (!userConns || userConns.length === 0) return;

    const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
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

    // تنظيف الاتصالات الميتة
    for (const d of dead) {
      this.remove(userId, d);
    }
  }

  /** بث حدث لعدة مستخدمين */
  sendToUsers(userIds: string[], event: string, data: unknown): void {
    const unique = [...new Set(userIds.filter(Boolean))];
    for (const uid of unique) {
      this.sendToUser(uid, event, data);
    }
  }

  /** عدد الاتصالات النشطة (للمراقبة) */
  get totalConnections(): number {
    let count = 0;
    for (const conns of this.connections.values()) {
      count += conns.length;
    }
    return count;
  }
}
