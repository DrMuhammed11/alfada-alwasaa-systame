import { Injectable } from '@nestjs/common';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class FetchStage implements IngestionStage {
  readonly name = 'FetchStage';
  readonly stopOnFailure = true;

  async run(ctx: IngestionContext): Promise<void> {
    if (!ctx.source || ctx.source.length === 0) {
      throw new StageError(this.name, `الرسالة UID ${ctx.uid} لا تحتوي على محتوى مصدري (Source Buffer)`);
    }
    if (!ctx.uid || ctx.uid <= 0) {
      throw new StageError(this.name, `معرف الرسالة UID غير صالح (${ctx.uid})`);
    }
  }
}
