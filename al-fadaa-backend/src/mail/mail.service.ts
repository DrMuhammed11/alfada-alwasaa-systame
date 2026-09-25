import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { MailRetryService } from './mail-retry.service';

export interface SendReplyOptions {
  to: string | null;
  subject: string;
  body: string;
  refNumber: string;
  messageId?: string;
  inReplyTo?: string;
  references?: string;
  attachments?: { filename: string; path?: string; content?: Buffer; contentType?: string }[];
  replyId?: string;
  html?: string;
}

/**
 * خدمة البريد — كل الردود تُرسل موحّدة من بريد الشركة الرسمي info@al-fadaa.com.
 * وضعان:
 *  - console : طباعة في الطرفية فقط (افتراضي للتطوير — لا إرسال حقيقي)
 *  - smtp    : إرسال حقيقي عبر خادم بريد الشركة (يُضبط من .env)
 * مزودة بآلية استرداد ذكية (MailRetryService) لإعادة محاولة الرسائل الفاشلة تلقائياً.
 */
@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger('Mail');
  private transporter: nodemailer.Transporter | null = null;

  constructor(
    private readonly config: ConfigService,
    @Optional() private readonly retryService?: MailRetryService,
  ) {}

  onModuleInit(): void {
    if (this.retryService) {
      this.retryService.registerSender(async (opts) => this.rawSend(opts));
    }

    if (this.config.get<string>('MAIL_DRIVER') === 'smtp') {
      const port = Number(this.config.get<number>('SMTP_PORT')) || 465;
      this.transporter = nodemailer.createTransport({
        host: this.config.get<string>('SMTP_HOST'),
        port,
        secure: port === 465,
        auth: {
          user: this.config.get<string>('SMTP_USER'),
          pass: this.config.get<string>('SMTP_PASS'),
        },
        tls: {
          // التحقق من شهادة TLS إلزامي في بيئة الإنتاج لمنع هجمات MITM، ومتاح التعطيل للتطوير فقط
          rejectUnauthorized:
            this.config.get<string>('NODE_ENV') === 'production'
              ? true
              : (this.config.get<string>('IMAP_TLS_REJECT_UNAUTHORIZED') !== 'false'),
        },
      });
      this.logger.log('تمت تهيئة البريد بوضع SMTP — الإرسال حقيقي مع محرك الاسترداد');
    } else {
      this.logger.warn('MAIL_DRIVER=console — الرسائل تُطبع في الطرفية ولا تُرسل فعليًا');
    }
  }

  async rawSend(opts: SendReplyOptions): Promise<boolean> {
    const from = this.config.get<string>('MAIL_FROM') ?? 'info@al-fadaa.com';
    if (!this.transporter) {
      const attNames = opts.attachments?.map((a) => a.filename).join(', ');
      this.logger.log(
        `[وضع التجربة] بريد من ${from} إلى ${opts.to ?? '(بدون بريد)'}` +
          ` | الموضوع: ${opts.subject} | المرجع: ${opts.refNumber} | معرف: ${opts.messageId ?? '(تلقائي)'}` +
          (attNames ? ` | المرفقات: ${attNames}` : ''),
      );
      return true;
    }
    if (!opts.to) {
      this.logger.warn(`لا يوجد بريد إلكتروني للمرسل — لم يُرسَل الرد ${opts.refNumber}`);
      return true;
    }
    const escapedBody = opts.body
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');

    const htmlBody = `<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, Tahoma, sans-serif; line-height: 1.7; color: #1e293b; direction: rtl; text-align: right; background-color: #f8fafc; padding: 20px; margin: 0;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; border: 1px solid #e2e8f0; overflow: hidden;">
    <div style="background-color: #0f172a; color: #ffffff; padding: 16px 20px; border-bottom: 3px solid #0284c7;">
      <h2 style="margin: 0; font-size: 16px; color: #ffffff;">شركة الفضاء الواسع</h2>
      <span style="font-size: 12px; color: #94a3b8;">نظام المراسلات الرسمي — إشعار صادر</span>
    </div>
    <div style="padding: 24px; font-size: 14px; white-space: pre-wrap; line-height: 1.8;">${escapedBody}</div>
    <div style="background-color: #f1f5f9; padding: 12px 20px; font-size: 11px; color: #64748b; border-top: 1px solid #e2e8f0;">
      هذه رسالة رسمية صادرة برقم القيد: <strong>${opts.refNumber}</strong> من شركة الفضاء الواسع.
    </div>
  </div>
</body>
</html>`;

    const mailOptions: nodemailer.SendMailOptions = {
      from: `"شركة الفضاء الواسع" <${from}>`,
      to: opts.to,
      subject: opts.subject,
      text: opts.body,
      html: opts.html ?? htmlBody,
    };
    if (opts.messageId) mailOptions.messageId = opts.messageId;
    if (opts.inReplyTo) mailOptions.inReplyTo = opts.inReplyTo;
    if (opts.references) mailOptions.references = opts.references;
    if (opts.attachments && opts.attachments.length > 0) {
      mailOptions.attachments = opts.attachments;
    }

    const info = await this.transporter.sendMail(mailOptions);
    this.logger.log(
      `تم إرسال الرد ${opts.refNumber} إلى ${opts.to} (معرّف الرسالة: ${info.messageId})`,
    );
    return true;
  }

  async sendReply(opts: SendReplyOptions): Promise<void> {
    try {
      await this.rawSend(opts);
    } catch (e) {
      const err = e as Error;
      this.logger.error(`فشل إرسال البريد ${opts.refNumber}: ${err.message}`);
      if (this.retryService && this.transporter) {
        this.retryService.enqueue(opts, err.message);
      }
    }
  }

  /**
   * إرسال مُتتبَّع لرسالة مسجلة مسبقًا في OutboxMail (أنشئت داخل معاملة الحالة) —
   * المسار الافتراضي لكل رد رسمي: لا يوجد نافذة يُفقد فيها البريد بانتهار العملية.
   */
  async sendReplyTracked(outboxMailId: string, opts: SendReplyOptions): Promise<void> {
    if (this.retryService) {
      await this.retryService.attemptTrackedSend(outboxMailId, opts);
      return;
    }
    // لا خدمة استرداد — نرسل مع تسجيل الخطأ فقط (نفس سلوك sendReply القديم)
    try {
      await this.rawSend(opts);
    } catch (e) {
      this.logger.error(`فشل إرسال البريد المتتبَّع ${opts.refNumber}: ${(e as Error).message}`);
    }
  }
}
