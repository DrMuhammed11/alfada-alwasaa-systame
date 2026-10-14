import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import type { Request, Response } from 'express';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * معالج عدم التكرار (Idempotency Interceptor) لطلبات POST:
 * يمنع تكرار تنفيذ العمليات في حال إعادة إرسالها من طابور الأوفلاين أو انقطاع الشبكة.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const ctx = context.switchToHttp();
    const req = ctx.getRequest<Request>();
    const res = ctx.getResponse<Response>();

    // يعمل فقط على طلبات POST
    if (req.method !== 'POST') {
      return next.handle();
    }

    // استخراج ترويسة Idempotency-Key
    const rawKey = req.headers['idempotency-key'] || req.headers['x-idempotency-key'];
    const key = typeof rawKey === 'string' ? rawKey.trim() : Array.isArray(rawKey) ? rawKey[0].trim() : null;

    if (!key) {
      return next.handle();
    }

    const userId: string | null = (req as any).user?.id ?? null;
    const endpoint = req.originalUrl || req.url;

    // البحث عن سجل سابق بنفس المفتاح
    const existing = await this.prisma.idempotencyRecord.findUnique({
      where: { key },
    });

    if (existing) {
      // إذا كان المفتاح مسجلاً لمستخدم آخر، تجاهله لمنع التلاعب والتصادم الخبيث
      if (existing.userId !== userId) {
        return next.handle();
      }

      // إذا تطابق الـ userId والـ endpoint، أعد الاستجابة المخزنة فوراً بلا إعادة تنفيذ
      if (existing.endpoint === endpoint) {
        res.status(existing.statusCode || 200);
        return of(existing.responseBody);
      }
    }

    // إن لم يوجد سجل مطابق، نفّذ الطلب وخزّن الاستجابة عند النجاح 2xx
    return next.handle().pipe(
      tap({
        next: async (responseBody) => {
          const statusCode = res.statusCode;
          if (statusCode >= 200 && statusCode < 300) {
            try {
              await this.prisma.idempotencyRecord.create({
                data: {
                  key,
                  userId,
                  endpoint,
                  responseBody: responseBody ?? {},
                  statusCode,
                },
              });
            } catch {
              // تجاهل خطأ السباق المتزامن إذا أُنشئ السجل مسبقاً
            }
          }
        },
      }),
    );
  }
}
