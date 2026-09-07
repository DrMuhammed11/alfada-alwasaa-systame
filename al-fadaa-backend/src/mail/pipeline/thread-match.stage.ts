import { Injectable } from '@nestjs/common';
import { IncomingMailMatcherService } from '../incoming-mail-matcher.service';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class ThreadMatchStage implements IngestionStage {
  readonly name = 'ThreadMatchStage';
  readonly stopOnFailure = true;

  constructor(private readonly matcherService: IncomingMailMatcherService) {}

  async run(ctx: IngestionContext): Promise<void> {
    if (ctx.status === 'ABORTED') return;

    try {
      const threadRoot = await this.matcherService.findThreadRoot(
        ctx.parsed!,
        ctx.senderEmail!,
        ctx.subject!,
        ctx.body!,
      );
      ctx.threadRoot = threadRoot;
      ctx.isChild = !!threadRoot;
    } catch (err) {
      throw new StageError(
        this.name,
        `فشل مطابقة سلسلة المحادثة للرسالة: ${(err as Error).message}`,
        true,
        err,
      );
    }
  }
}
