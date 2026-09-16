import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import helmet from 'helmet';
import type { NextFunction, Request, Response } from 'express';
import { requestContextStorage } from './common/context/request-context';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { requestIdMiddleware } from './common/middleware/request-id.middleware';
import { AppLogger } from './common/logger/app-logger';
import { buildCorsOriginFunction } from './common/cors/build-cors-origin';

/**
 * إعدادات مشتركة بين التشغيل الحقيقي (main.ts) واختبارات e2e —
 * حتى تُختبر التطبيقات بنفس سلوك الإنتاج تمامًا.
 */
export function configureApp(app: INestApplication): void {
  // مسجل الأحداث المركزي المنظم: JSON في الإنتاج وملون مع requestId في التطوير
  app.useLogger(new AppLogger());

  // رؤوس أمان HTTP القياسية
  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }));

  // معرف الطلب الفريد (X-Request-Id)
  app.use(requestIdMiddleware);

  // سياق الطلب (معرف الطلب + IP + المتصفح) لسجل التدقيق وسياق التسجيل
  app.use((req: Request, _res: Response, next: NextFunction) => {
    requestContextStorage.run(
      {
        requestId: (req as any).requestId,
        ip: req.ip ?? undefined,
        userAgent: req.headers['user-agent'] ?? undefined,
      },
      () => next(),
    );
  });

  // التحقق من صحة المدخلات (DTO) — الرفض التلقائي للحقول غير المعرفة
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // معالج الأخطاء الموحد (عربي)
  app.useGlobalFilters(new AllExceptionsFilter());

  // البادئة العامة /api + الإصدار /v1 → المسارات النهائية: /api/v1/...
  app.setGlobalPrefix('api');
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });

  // السماح للواجهة الأمامية (فلاتر وبقية الواجهات) بالاتصال — قائمة بيضاء من CORS_ORIGIN
  const isProduction = process.env.NODE_ENV === 'production';
  app.enableCors({
    origin: buildCorsOriginFunction(process.env.CORS_ORIGIN, isProduction),
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type,Accept,Authorization,X-Request-Id',
  });
}
