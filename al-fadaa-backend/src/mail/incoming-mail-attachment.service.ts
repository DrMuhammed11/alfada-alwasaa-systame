import { Injectable, Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class IncomingMailAttachmentService {
  private readonly logger = new Logger('IncomingMailAttachment');

  constructor(private readonly prisma: PrismaService) {}

  /**
   * حفظ مرفقات رسالة العميل على القرص وإنشاء سجلات لها في قاعدة البيانات
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

        const unique = `${Date.now()}-${Math.round(Math.random() * 1_000_000_000)}`;
        const storedName = `${unique}${ext || ''}`;
        const filePath = path.join(uploadDir, storedName);

        if (att.content && Buffer.isBuffer(att.content)) {
          await fs.promises.writeFile(filePath, att.content);
          await this.prisma.attachment.create({
            data: {
              correspondenceId,
              fileName: att.filename || 'attachment',
              storedName,
              mimeType: mime || 'application/octet-stream',
              size,
              uploadedById: systemUserId,
            },
          });
          this.logger.log(
            `[IMAP Engine] تم حفظ المرفق «${att.filename}» (${(size / 1024).toFixed(1)}KB) للمراسلة`,
          );
        }
      } catch (err) {
        this.logger.error(
          `فشل حفظ المرفق «${att.filename}»: ${(err as Error).message}`,
        );
      }
    }
  }
}
