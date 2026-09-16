/**
 * سكربت تشغيل النسخ الاحتياطي لقاعدة البيانات عبر سطر الأوامر (CLI Runner)
 * الاستخدام:
 *   npm run db:backup
 * أو عبر Cron نظام التشغيل مباشرة:
 *   npx ts-node scripts/db-backup.ts
 */
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { BackupService } from '../src/backup/backup.service';

async function run(): Promise<void> {
  // إنشاء تطبيق NestJS مستقل (بدون تشغيل خادم HTTP)
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  const backupService = app.get(BackupService);
  console.log('🔄 بدء تشغيل أداة النسخ الاحتياطي لقاعدة البيانات...');

  try {
    const result = await backupService.createBackup();
    if (result.success) {
      console.log('✅ اكتمل النسخ الاحتياطي بنجاح!');
      console.log(`📁 مسار الملف: ${result.filePath}`);
      console.log(`📦 الحجم: ${(result.sizeBytes! / 1024).toFixed(1)} KB`);
      console.log(`🧹 النسخ القديمة المحذوفة: ${result.deletedOldBackups}`);
      await app.close();
      process.exit(0);
    } else {
      console.error('❌ فشلت عملية النسخ الاحتياطي:');
      console.error(result.error);
      await app.close();
      process.exit(1);
    }
  } catch (e) {
    console.error('❌ استثناء غير متوقع أثناء النسخ الاحتياطي:', (e as Error).message);
    await app.close();
    process.exit(1);
  }
}

void run();
