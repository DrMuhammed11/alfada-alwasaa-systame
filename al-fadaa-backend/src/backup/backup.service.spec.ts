import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { BackupService } from './backup.service';
import { MailService } from '../mail/mail.service';

describe('BackupService', () => {
  let service: BackupService;
  let mailService: { sendReply: jest.Mock };
  let configMap: Record<string, any>;
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'backup-test-'));

    configMap = {
      BACKUP_DIR: tmpDir,
      BACKUP_RETENTION_DAYS: 7,
      BACKUP_ALERT_EMAIL: 'ops@al-fadaa.com',
      BACKUP_ENABLED: 'false',
      DATABASE_URL: 'postgresql://testuser:testpass@dbhost:5433/testdb?schema=public',
    };

    mailService = {
      sendReply: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BackupService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => configMap[key]),
          },
        },
        {
          provide: MailService,
          useValue: mailService,
        },
      ],
    }).compile();

    service = module.get<BackupService>(BackupService);
  });

  afterEach(() => {
    try {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    } catch {}
  });

  describe('parseDatabaseUrl', () => {
    it('يحلل رابط قاعدة البيانات بنجاح ويستخرج المعاملات', () => {
      const parsed = service.parseDatabaseUrl(
        'postgresql://alfadaa:mypassword@localhost:5432/alfadaa_db?schema=public',
      );

      expect(parsed.user).toBe('alfadaa');
      expect(parsed.password).toBe('mypassword');
      expect(parsed.host).toBe('localhost');
      expect(parsed.port).toBe('5432');
      expect(parsed.database).toBe('alfadaa_db');
    });

    it('يستخدم DATABASE_URL من ConfigService عند عدم تمرير رابط', () => {
      const parsed = service.parseDatabaseUrl();

      expect(parsed.user).toBe('testuser');
      expect(parsed.password).toBe('testpass');
      expect(parsed.host).toBe('dbhost');
      expect(parsed.port).toBe('5433');
      expect(parsed.database).toBe('testdb');
    });

    it('يتعامل بلباقة مع الروابط غير الصالحة أو الفارغة', () => {
      expect(service.parseDatabaseUrl('')).toEqual({});
      expect(service.parseDatabaseUrl('invalid-url')).toEqual({});
    });
  });

  describe('rotateBackups', () => {
    it('يحذف النسخ الأقدم من المدة المحددة ويُبقي على النسخ الحديثة', () => {
      const oldFile = path.join(tmpDir, 'backup-old.sql.gz');
      const newFile = path.join(tmpDir, 'backup-new.sql.gz');
      const unrelatedFile = path.join(tmpDir, 'notes.txt');

      fs.writeFileSync(oldFile, 'محتوى قديم');
      fs.writeFileSync(newFile, 'محتوى حديث');
      fs.writeFileSync(unrelatedFile, 'ملف نصي عادي');

      // ضبط تاريخ التعديل للملف القديم ليكون قبل 10 أيام (تجاوز 7 أيام)
      const tenDaysAgo = (Date.now() - 10 * 24 * 60 * 60 * 1000) / 1000;
      fs.utimesSync(oldFile, tenDaysAgo, tenDaysAgo);

      const deletedCount = service.rotateBackups(tmpDir, 7);

      expect(deletedCount).toBe(1);
      expect(fs.existsSync(oldFile)).toBe(false);
      expect(fs.existsSync(newFile)).toBe(true);
      expect(fs.existsSync(unrelatedFile)).toBe(true);
    });

    it('يعيد صفر ولا يرمي خطأ إذا كان المجلد غير موجود', () => {
      const deleted = service.rotateBackups(path.join(tmpDir, 'non-existent'), 7);
      expect(deleted).toBe(0);
    });
  });

  describe('sendFailureAlert', () => {
    it('يرسل إشعار بريدي عبر MailService يتضمن تفاصيل الفشل ومعرف SYS-BACKUP', async () => {
      await service.sendFailureAlert('فشل الاتصال بقاعدة البيانات');

      expect(mailService.sendReply).toHaveBeenCalledTimes(1);
      const callArg = mailService.sendReply.mock.calls[0][0];

      expect(callArg.to).toBe('ops@al-fadaa.com');
      expect(callArg.subject).toContain('فشل النسخ الاحتياطي لقاعدة البيانات');
      expect(callArg.body).toContain('فشل الاتصال بقاعدة البيانات');
      expect(callArg.refNumber).toBe('SYS-BACKUP');
      expect(callArg.html).toContain('⚠️ تنبيه حرج');
    });
  });

  describe('handleScheduledBackup', () => {
    it('يتجاهل التنفيذ إذا كان BACKUP_ENABLED غير مفعّل', async () => {
      const createBackupSpy = jest.spyOn(service, 'createBackup').mockResolvedValue({
        success: true,
      });

      configMap.BACKUP_ENABLED = 'false';
      await service.handleScheduledBackup();

      expect(createBackupSpy).not.toHaveBeenCalled();
    });

    it('ينفذ النسخ الاحتياطي إذا كان BACKUP_ENABLED مفعلاً', async () => {
      const createBackupSpy = jest.spyOn(service, 'createBackup').mockResolvedValue({
        success: true,
      });

      configMap.BACKUP_ENABLED = 'true';
      await service.handleScheduledBackup();

      expect(createBackupSpy).toHaveBeenCalledTimes(1);
    });
  });
});
