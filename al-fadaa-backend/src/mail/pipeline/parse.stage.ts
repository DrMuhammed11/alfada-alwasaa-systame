import { Injectable } from '@nestjs/common';
import { simpleParser } from 'mailparser';
import { stripHtml } from '../incoming-mail.utils';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class ParseStage implements IngestionStage {
  readonly name = 'ParseStage';
  readonly stopOnFailure = true;

  async run(ctx: IngestionContext): Promise<void> {
    try {
      const parsed = await simpleParser(ctx.source!);
      ctx.parsed = parsed;

      const senderEmail = (parsed.from?.value[0]?.address || 'unknown@domain.com')
        .toLowerCase()
        .trim();
      const senderName =
        parsed.from?.value[0]?.name || senderEmail.split('@')[0] || 'مرسل خارجي';
      const subject = (parsed.subject || 'مراسلة واردة عبر البريد الإلكتروني').trim();

      const hasHtml = typeof parsed.html === 'string' && parsed.html.trim().length > 0;
      const plainText = (parsed.text || '').trim();
      const body = plainText || (hasHtml ? stripHtml(parsed.html as string) : '');
      const incomingMessageId = parsed.messageId ? parsed.messageId.trim() : null;

      ctx.senderEmail = senderEmail;
      ctx.senderName = senderName;
      ctx.subject = subject;
      ctx.hasHtml = hasHtml;
      ctx.body = body;
      ctx.incomingMessageId = incomingMessageId;
    } catch (err) {
      throw new StageError(
        this.name,
        `فشل في تحليل محتوى البريد الإلكتروني: ${(err as Error).message}`,
        true,
        err,
      );
    }
  }
}
