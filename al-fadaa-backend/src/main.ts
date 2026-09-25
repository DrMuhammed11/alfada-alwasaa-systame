import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const logger = new Logger('Bootstrap');

  // للحصول على IP الحقيقي للعميل خلف البروكسي (nginx وغيره)
  app.set('trust proxy', 1);

  configureApp(app);

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
