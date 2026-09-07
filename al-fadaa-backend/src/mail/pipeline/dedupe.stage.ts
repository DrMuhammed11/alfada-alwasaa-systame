import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class DedupeStage implements IngestionStage {
  readonly name = 'DedupeStage';
  readonly stopOnFailure = true;
  private readonly logger = new Logger('DedupeStage');

  private blockedSenders: string[] = [];

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.blockedSenders = (this.config.get<string>('IMAP_BLOCKED_SENDERS') || '')
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean);
  }

  async run(ctx: IngestionContext): Promise<void> {
    const senderEmail = ctx.senderEmail!;

    // 1. فحص قائمة المحجوبين
    if (this.blockedSenders.includes(senderEmail)) {
      ctx.isBlocked = true;
      ctx.status = 'ABORTED';
      this.logger.warn(`تجاهل رسالة من مرسل محجوب: ${senderEmail}`);
      return;
    }

    try {
      // 2. التحقق عبر Message-ID الفريد
      if (ctx.incomingMessageId) {
        const existing = await this.prisma.correspondence.findFirst({
          where: { messageId: ctx.incomingMessageId },
          select: { id: true, refNumber: true },
        });
        if (existing) {
          ctx.isDuplicate = true;
          ctx.status = 'ABORTED';
          this.logger.log(
            `رسالة مكررة (Message-ID: ${ctx.incomingMessageId}) مسجلة مسبقًا برقم ${existing.refNumber}`,
          );
          return;
        }
      } else {
        // 3. التحقق الاحتياطي عبر بصمة المحتوى والتوقيت
        const receivedAt = ctx.parsed?.date ? new Date(ctx.parsed.date) : undefined;
        const existing = await this.prisma.correspondence.findFirst({
          where: {
            senderEmail,
            subject: ctx.subject,
            body: ctx.body,
            receivedAt,
          },
          select: { id: true, refNumber: true },
        });
        if (existing) {
          ctx.isDuplicate = true;
          ctx.status = 'ABORTED';
          this.logger.log(
            `رسالة مكررة بالمحتوى والتوقيت من ${senderEmail} مسجلة مسبقًا برقم ${existing.refNumber}`,
          );
          return;
        }
      }
    } catch (err) {
      throw new StageError(
        this.name,
        `فشل التحقق من تكرار الرسالة: ${(err as Error).message}`,
        true,
        err,
      );
    }
  }
}
