import { Injectable, Logger } from '@nestjs/common';
import { IncomingMailAttachmentService } from '../incoming-mail-attachment.service';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class AttachmentsStage implements IngestionStage {
  readonly name = 'AttachmentsStage';
  /** فشل حفظ المرفق لا يمنع تسجيل المراسلة بل يُسجل كخطأ ويُسمح بالمتابعة */
  readonly stopOnFailure = false;
  private readonly logger = new Logger('AttachmentsStage');

  constructor(private readonly attachmentService: IncomingMailAttachmentService) {}

  async run(ctx: IngestionContext): Promise<void> {
    if (ctx.status === 'ABORTED' || !ctx.correspondenceId) return;
    const attachments = ctx.parsed?.attachments;
    if (!attachments || attachments.length === 0) return;

    try {
      await this.attachmentService.saveIncomingAttachments(
        attachments,
        ctx.correspondenceId,
        ctx.systemUserId,
      );
      ctx.attachmentsSavedCount = attachments.length;
      this.logger.log(
        `[AttachmentsStage] تم حفظ ${attachments.length} مرفقات بنجاح للمراسلة ${ctx.refNumber}`,
      );
    } catch (err) {
      this.logger.error(
        `[AttachmentsStage] تعذر حفظ مرفقات المراسلة ${ctx.refNumber}: ${(err as Error).message}`,
      );
      throw new StageError(
        this.name,
        `تعذر حفظ بعض المرفقات: ${(err as Error).message}`,
        false, // non-fatal
        err,
      );
    }
  }
}
