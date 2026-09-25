import { Injectable, Logger } from '@nestjs/common';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { validateMagicBytes, isZipAllowed } from '../common/attachments/magic-bytes';

@Injectable()
export class IncomingMailAttachmentService {
  private readonly logger = new Logger('IncomingMailAttachment');

  constructor(private readonly prisma: PrismaService) {}

  /**
   * حفظ مرفقات رسالة العميل على القرص وإنشاء سجلات لها في قاعدة البيانات.
   * تُطبَّق نفس سياسة الأمان الخاصة برفع المستخدمين: فحص البايتات السحرية
   * (وليس الاعتماد على نوع MIME المُعلن)، حظر ZIP وفق الإعداد، وبصمة SHA-256.
   * مرفقات البريد الوارد سطح هجوم خارجي — أدنى تساهل معها يعني RCE محتمل.
   */
  async saveIncomingAttachments(
    attachments: any[] | undefined,
    correspondenceId: string,
    systemUserId: string,
  ): Promise<void> {
    if (!attachments || attachments.length === 0) return;

    const allowedMimes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/zip',
      'text/plain',
    ];
    const maxSizeBytes = 15 * 1024 * 1024;
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    for (const att of attachments) {
      try {
        const size = att.size || att.content?.length || 0;
        if (size > maxSizeBytes) {
          this.logger.warn(
            `تجاوز حجم المرفق «${att.filename}» الحد المسموح (15MB) — تم تخطيه`,
          );
          continue;
        }

        const mime = (att.contentType || '').toLowerCase().trim();
        const ext = path.extname(att.filename || '').toLowerCase();
        const isAllowedExt = [
          '.pdf',
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.zip',
          '.txt',
        ].includes(ext);

        if (!allowedMimes.includes(mime) && !isAllowedExt) {
          this.logger.warn(
            `نوع المرفق «${att.filename}» (${mime}) غير مدعوم — تم تخطيه`,
          );
          continue;
        }

        if (!att.content || !Buffer.isBuffer(att.content)) continue;

        // ZIP محظور وفق الإعداد نفسه المطبق على رفع المستخدمين
        if (mime === 'application/zip' && !isZipAllowed()) {
          this.logger.warn(
            `رفض مرفق ZIP «${att.filename}» من البريد الوارد (ALLOW_ZIP_UPLOADS غير مفعّل)`,
          );
          continue;
        }

        const unique = `${Date.now()}-${Math.round(Math.random() * 1_000_000_000)}`;
        const storedName = `${unique}${ext || ''}`;
        const filePath = path.join(uploadDir, storedName);

        await fs.promises.writeFile(filePath, att.content);

        // فحص المحتوى الفعلي (magic bytes) بعد الكتابة — النوع المُعلن من المرسل غير موثوق
        if (!validateMagicBytes(filePath, mime || guessMimeFromExt(ext))) {
          this.logger.warn(
            `محتوى المرفق «${att.filename}» لا يطابق نوعه المُعلن (${mime}) — حُذف الملف ورُفض السجل`,
          );
          fs.unlinkSync(filePath);
          continue;
        }

        // بصمة SHA-256 للتحقق من السلامة — مطابقة لسلوك رفع المستخدمين
        const sha256 = crypto.createHash('sha256').update(att.content).digest('hex');

        await this.prisma.attachment.create({
          data: {
            correspondenceId,
            fileName: att.filename || 'attachment',
            storedName,
            mimeType: mime || 'application/octet-stream',
            size,
            sha256,
            uploadedById: systemUserId,
          },
        });
        this.logger.log(
          `[IMAP Engine] تم حفظ المرفق «${att.filename}» (${(size / 1024).toFixed(1)}KB) للمراسلة`,
        );
      } catch (err) {
        this.logger.error(
          `فشل حفظ المرفق «${att.filename}»: ${(err as Error).message}`,
        );
      }
    }
  }
}

/** تخمين نوع MIME من الامتداد لغرض فحص البايتات السحرية عندما يغيب النوع */
function guessMimeFromExt(ext: string): string {
  const map: Record<string, string> = {
    '.pdf': 'application/pdf',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.zip': 'application/zip',
    '.txt': 'text/plain',
  };
  return map[ext] ?? 'application/octet-stream';
}
