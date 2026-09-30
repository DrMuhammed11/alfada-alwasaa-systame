import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from '@nestjs/common';
import { attach, enableTelemetry } from './vendor/boosthis-kit';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { AppLogger } from './common/logger/app-logger';

// ═══ شبكة أمان العملية: لا موت صامت إطلاقاً ═══
// رفض وعد غير معالج (مثل رفض close() أثناء عواصف انقطاع IMAP) كان يُسقط Node
// بصمت بلا أي أثر. الآن يُطبع بأعلى صوت مع أثر المكدس كاملاً:
// في التطوير تستمر العملية بالخدمة، وفي الإنتاج تخرج برمز فشل بعد الطباعة
// ليعيد النظام المستضيف تشغيلها — الموت مسموح لكن الصمت ممنوع.
const isProdProcess = process.env.NODE_ENV === 'production';
process.on('uncaughtException', (err: Error) => {
  console.error('════════ [FATAL] uncaughtException ════════\n', err?.stack ?? String(err));
  if (isProdProcess) process.exit(1);
});
process.on('unhandledRejection', (reason: unknown) => {
  const asError = reason instanceof Error ? reason : new Error(String(reason));
  console.error('════════ [FATAL] unhandledRejection ════════\n', asError.stack ?? String(reason));
  if (isProdProcess) process.exit(1);
});

// ═══ قياس الأداء Boosthis — يجب أن يعمل قبل إنشاء الخادم ليطال كل طلب ═══
// المفتاح من البيئة BOOSTHIS_INVITE_KEY (ملف .env، غير مرفوع للمستودع)؛
// غيابه يبقي القياس محلياً بلا تسجيل بعيد.
attach();
enableTelemetry({
  installId: 'e7f7f17e-f2e5-4b1f-8a61-b337ec38e890',
  inviteKey: process.env.BOOSTHIS_INVITE_KEY,
  endpoint: 'https://www.boosthis.com/api',
  appName: 'al-fadaa-backend',
});

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const logger = new Logger('Bootstrap');

  // للحصول على IP الحقيقي للعميل خلف البروكسي (nginx وغيره)
  app.set('trust proxy', 1);

  configureApp(app);

  // وضع التطوير: طباعة كل شيء — كل طلب HTTP بالطريقة والحالة والزمن،
  // وكل مستويات المسجل (debug/verbose) التي تخفيها المستويات الافتراضية
  if (!isProdProcess) {
    app.use(
      (
        req: { method: string; originalUrl: string },
        res: { statusCode: number; on: (event: string, cb: () => void) => void },
        next: () => void,
      ) => {
        const startedAt = Date.now();
        res.on('finish', () => {
          console.log(`[HTTP] ${req.method} ${req.originalUrl} → ${res.statusCode} (${Date.now() - startedAt}ms)`);
        });
        next();
      },
    );
    app.useLogger(new AppLogger());
    // تفعيل كل المستويات (debug/verbose) التي تخفيها المستويات الافتراضية —
    // بالنمط الموثق في Nest: overrideLogger بمصفوفة [الخدمة، المستويات]،
    // لأن setLogLevels في المسجل المركزي no-op عمداً (تدار مركزياً)
    Logger.overrideLogger([
      new AppLogger(),
      ['log', 'error', 'warn', 'debug', 'verbose'],
    ] as unknown as Parameters<typeof Logger.overrideLogger>[0]);
  }

  // إغلاق لطيف عند SIGTERM — يوقف IMAP والمؤقتات ويفصل Prisma بشكل نظيف عند النشر
  app.enableShutdownHooks();

  // توثيق Swagger التفاعلي — في التطوير فقط؛ كشفه في الإنتاج كشف سطح هجوم بلا داع
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('نظام إدارة المراسلات — الفضاء الواسع')
      .setDescription(
        'واجهات برمجة التطبيقات لنظام إدارة المراسلات المؤسسي (al-fadaa.com).\n\n' +
          'سجّل الدخول أولاً من ‎POST /api/v1/auth/login‎ ثم اضغط زر **Authorize** ' +
          'وألصق الرمز لتجربة بقية النقاط.',
      )
      .setVersion('0.1')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document, {
      swaggerOptions: { persistAuthorization: true },
    });
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);

  logger.log('──────────────────────────────────────────────');
  logger.log(`🚀 الواجهة الخلفية تعمل على:  http://localhost:${port}/api/v1`);
  if (process.env.NODE_ENV !== 'production') {
    logger.log(`📘 توثيق Swagger:            http://localhost:${port}/api/docs`);
  }
  logger.log('──────────────────────────────────────────────');
}

void bootstrap();
