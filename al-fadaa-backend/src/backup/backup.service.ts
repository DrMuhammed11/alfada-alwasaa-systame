import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron } from '@nestjs/schedule';
import { spawn } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as zlib from 'zlib';
import { MailService } from '../mail/mail.service';

export interface DatabaseConnectionConfig {
  user?: string;
  password?: string;
  host?: string;
  port?: string;
  database?: string;
}

export interface BackupResult {
  success: boolean;
  filePath?: string;
  sizeBytes?: number;
  error?: string;
  deletedOldBackups?: number;
}

/**
 * خدمة النسخ الاحتياطي لقاعدة بيانات PostgreSQL
 * - تنفيذ النسخ وضغطه فورياً بصيغة gzip (.sql.gz)
 * - تدوير النسخ وحذف النسخ الأقدم من فترة الاحتفاظ المحددة
 * - إرسال تنبيه بريدي فوري للمسؤول في حال فشل النسخ
 * - تشغيل مجدول عبر Cron أو عند الطلب عبر CLI
 */
@Injectable()
export class BackupService {
  private readonly logger = new Logger('DatabaseBackup');

  constructor(
    private readonly config: ConfigService,
    @Optional() private readonly mailService?: MailService,
  ) {}

  /** مجلد حفظ النسخ الاحتياطية */
  getBackupDir(): string {
    return this.config.get<string>('BACKUP_DIR') || './backups';
  }

  /** عدد أيام الاحتفاظ بالنسخ الاحتياطية (الافتراضي 7 أيام) */
  getRetentionDays(): number {
    return Number(this.config.get<string | number>('BACKUP_RETENTION_DAYS')) || 7;
  }

  /** البريد المستلم لتنبيهات الفشل */
  getAlertEmail(): string {
    return (
      this.config.get<string>('BACKUP_ALERT_EMAIL') ||
      this.config.get<string>('MAIL_FROM') ||
      'admin@al-fadaa.com'
    );
  }

  /** هل النسخ التلقائي المجدول مفعّل؟ */
  isScheduledBackupEnabled(): boolean {
    return this.config.get<string>('BACKUP_ENABLED') === 'true';
  }

  /** تحليل رابط الاتصال DATABASE_URL لاستخراج المعاملات */
  parseDatabaseUrl(rawUrl?: string): DatabaseConnectionConfig {
    const dbUrl = rawUrl !== undefined ? rawUrl : this.config.get<string>('DATABASE_URL');
    if (!dbUrl) return {};

    try {
      const parsed = new URL(dbUrl);
      return {
        user: decodeURIComponent(parsed.username),
        password: decodeURIComponent(parsed.password),
        host: parsed.hostname,
        port: parsed.port || '5432',
        database: parsed.pathname ? parsed.pathname.replace(/^\//, '') : undefined,
      };
    } catch {
      return {};
    }
  }

  /**
   * تدوير النسخ الاحتياطية: حذف الملفات التي تجاوزت مدة الاحتفاظ
   */
  rotateBackups(dir?: string, retentionDays?: number): number {
    const targetDir = dir || this.getBackupDir();
    const days = retentionDays || this.getRetentionDays();
    if (!fs.existsSync(targetDir)) return 0;

    const files = fs.readdirSync(targetDir);
    const now = Date.now();
    const maxAgeMs = days * 24 * 60 * 60 * 1000;
    let deletedCount = 0;

    for (const file of files) {
      if (!file.endsWith('.sql.gz') && !file.endsWith('.sql')) continue;

      const fullPath = path.join(targetDir, file);
      try {
        const stats = fs.statSync(fullPath);
        const age = now - stats.mtimeMs;
        if (age > maxAgeMs) {
          fs.unlinkSync(fullPath);
          deletedCount++;
          this.logger.log(`تم حذف نسخة احتياطية قديمة طبقاً لسياسة التدوير: ${file}`);
        }
      } catch (e) {
        this.logger.warn(`تعذر فحص أو حذف الملف ${file}: ${(e as Error).message}`);
      }
    }

    return deletedCount;
  }

  /**
   * إرسال بريد تنبيه عند فشل عملية النسخ
   */
  async sendFailureAlert(errorMsg: string): Promise<void> {
    const alertEmail = this.getAlertEmail();
    const timestamp = new Date().toLocaleString('ar-SA', { timeZone: 'Asia/Riyadh' });
    const subject = `⚠️ تنبيه حرج: فشل النسخ الاحتياطي لقاعدة البيانات [SYS-BACKUP]`;
    const body = `نحيطكم علماً بفشل عملية النسخ الاحتياطي التلقائي لقاعدة بيانات نظام المراسلات.\nالوقت: ${timestamp}\nالسبب: ${errorMsg}\n\nيرجى التحقق من الخادم وسعة التخزين وصلاحيات قاعدة البيانات فوراً.`;

    const html = `<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, Tahoma, sans-serif; line-height: 1.7; color: #1e293b; direction: rtl; text-align: right; background-color: #f8fafc; padding: 20px; margin: 0;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; border: 1px solid #e2e8f0; overflow: hidden;">
    <div style="background-color: #dc2626; color: #ffffff; padding: 16px 20px;">
      <h2 style="margin: 0; font-size: 16px; color: #ffffff;">⚠️ تنبيه حرج — فشل النسخ الاحتياطي</h2>
      <span style="font-size: 12px; color: #fecaca;">نظام إدارة المراسلات — شركة الفضاء الواسع</span>
    </div>
    <div style="padding: 24px; font-size: 14px; line-height: 1.8;">
      <p style="color: #991b1b; font-weight: bold;">فشلت عملية النسخ الاحتياطي لقاعدة البيانات في الموعد المحدد.</p>
      <table style="width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13px;">
        <tr><td style="padding: 6px; color: #64748b; width: 30%;">الوقت:</td><td style="padding: 6px; font-weight: bold;">${timestamp}</td></tr>
        <tr><td style="padding: 6px; color: #64748b;">تفاصيل الخطأ:</td><td style="padding: 6px; color: #b91c1c; font-family: monospace;">${errorMsg}</td></tr>
      </table>
      <p style="margin-top: 20px; font-size: 12px; color: #475569;">يرجى اتخاذ الإجراء اللازم والتأكد من تشغيل أداة pg_dump وتوفر مساحة كافية على القرص.</p>
    </div>
    <div style="background-color: #f1f5f9; padding: 12px 20px; font-size: 11px; color: #64748b; border-top: 1px solid #e2e8f0;">
      تنبيه نظام تلقائي صادر من مخدّم الفضاء الواسع.
    </div>
  </div>
</body>
</html>`;

    this.logger.error(`إرسال تنبيه فشل النسخ الاحتياطي إلى ${alertEmail}: ${errorMsg}`);

    if (this.mailService) {
      try {
        await this.mailService.sendReply({
          to: alertEmail,
          subject,
          body,
          html,
          refNumber: 'SYS-BACKUP',
        });
      } catch (mailErr) {
        this.logger.error(`تعذر إرسال بريد التنبيه: ${(mailErr as Error).message}`);
      }
    }
  }

  /**
   * تنفيذ عملية النسخ الاحتياطي وضغط الملف وتدوير الأرشيف
   */
  async createBackup(): Promise<BackupResult> {
    const backupDir = this.getBackupDir();
    fs.mkdirSync(backupDir, { recursive: true });

    const conn = this.parseDatabaseUrl();
    if (!conn.database) {
      const err = 'لم يتم العثور على اسم قاعدة البيانات في DATABASE_URL';
      await this.sendFailureAlert(err);
      return { success: false, error: err };
    }

    const dbName = conn.database;
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const fileName = `backup-${dbName}-${timestamp}.sql.gz`;
    const targetPath = path.join(backupDir, fileName);

    return new Promise<BackupResult>((resolve) => {
      const args: string[] = [];
      if (conn.host) args.push('-h', conn.host);
      if (conn.port) args.push('-p', conn.port);
      if (conn.user) args.push('-U', conn.user);
      args.push(dbName);

      const env: NodeJS.ProcessEnv = { ...process.env };
      if (conn.password) {
        env.PGPASSWORD = conn.password;
      }

      this.logger.log(`بدء عملية النسخ الاحتياطي لقاعدة البيانات [${conn.database}]...`);

      let childProcess;
      try {
        childProcess = spawn('pg_dump', args, { env });
      } catch (err) {
        const errorMsg = `تعذر بدء أمر pg_dump: ${(err as Error).message}`;
        this.sendFailureAlert(errorMsg).finally(() => {
          resolve({ success: false, error: errorMsg });
        });
        return;
      }

      const gzip = zlib.createGzip({ level: 9 });
      const output = fs.createWriteStream(targetPath);

      let stderrOutput = '';
      childProcess.stderr?.on('data', (chunk) => {
        stderrOutput += chunk.toString();
      });

      childProcess.on('error', async (err) => {
        const errorMsg = `خطأ أثناء تشغيل pg_dump: ${err.message}`;
        this.logger.error(errorMsg);
        try {
          if (fs.existsSync(targetPath)) fs.unlinkSync(targetPath);
        } catch {}
        await this.sendFailureAlert(errorMsg);
        resolve({ success: false, error: errorMsg });
      });

      childProcess.stdout.pipe(gzip).pipe(output);

      output.on('finish', async () => {
        try {
          const stats = fs.statSync(targetPath);
          const sizeKb = (stats.size / 1024).toFixed(1);
          this.logger.log(
            `اكتمل النسخ الاحتياطي بنجاح ✅: ${fileName} (${sizeKb} KB)`,
          );

          const deletedOld = this.rotateBackups(backupDir);

          resolve({
            success: true,
            filePath: targetPath,
            sizeBytes: stats.size,
            deletedOldBackups: deletedOld,
          });
        } catch (e) {
          const errorMsg = `فشل قراءة الملف الناتج بعد النسخ: ${(e as Error).message}`;
          await this.sendFailureAlert(errorMsg);
          resolve({ success: false, error: errorMsg });
        }
      });

      output.on('error', async (err) => {
        const errorMsg = `خطأ في تدفق كتابة ملف النسخ: ${err.message}`;
        this.logger.error(errorMsg);
        try {
          if (fs.existsSync(targetPath)) fs.unlinkSync(targetPath);
        } catch {}
        await this.sendFailureAlert(errorMsg);
        resolve({ success: false, error: errorMsg });
      });
    });
  }

  /**
   * المهمة اليومية المجدولة (تعمل الساعة 2:00 صباحاً بتوقيت الخادم)
   */
  @Cron(process.env.BACKUP_CRON || '0 2 * * *')
  async handleScheduledBackup(): Promise<void> {
    if (!this.isScheduledBackupEnabled()) {
      this.logger.debug('النسخ الاحتياطي المجدول معطّل (BACKUP_ENABLED=false)');
      return;
    }

    this.logger.log('بدء مهمة النسخ الاحتياطي المجدولة اليومية...');
    const result = await this.createBackup();
    if (!result.success) {
      this.logger.error(`فشلت مهمة النسخ الاحتياطي اليومية: ${result.error}`);
    }
  }
}
