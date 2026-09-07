import { Injectable, Logger } from '@nestjs/common';
import { FetchStage } from './fetch.stage';
import { ParseStage } from './parse.stage';
import { DedupeStage } from './dedupe.stage';
import { ThreadMatchStage } from './thread-match.stage';
import { PersistStage } from './persist.stage';
import { AttachmentsStage } from './attachments.stage';
import { NotifyStage } from './notify.stage';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class IngestionPipeline {
  private readonly logger = new Logger('IngestionPipeline');
  private readonly stages: IngestionStage[];

  /** سجل تشغيل قابل للتفتيش لآخر 100 رسالة معالجة */
  private readonly executionHistory: IngestionContext[] = [];
  private readonly maxHistorySize = 100;

  constructor(
    fetchStage: FetchStage,
    parseStage: ParseStage,
    dedupeStage: DedupeStage,
    threadMatchStage: ThreadMatchStage,
    persistStage: PersistStage,
    attachmentsStage: AttachmentsStage,
    notifyStage: NotifyStage,
  ) {
    this.stages = [
      fetchStage,
      parseStage,
      dedupeStage,
      threadMatchStage,
      persistStage,
      attachmentsStage,
      notifyStage,
    ];
  }

  /**
   * تشغيل خط الأنابيب لمعالجة رسالة واحدة مع قياس أزمنة كل مرحلة وتوثيق النتيجة
   */
  async execute(ctx: IngestionContext): Promise<IngestionContext> {
    ctx.stagesExecuted = [];
    ctx.status = 'PENDING';

    for (let i = 0; i < this.stages.length; i++) {
      const stage = this.stages[i];

      // إذا كانت الرسالة أُلغيت في مرحلة سابقة (مكررة/محجوبة) نتوقف بهدوء
      if ((ctx.status as string) === 'ABORTED') {
        break;
      }

      const startTime = performance.now();
      try {
        await stage.run(ctx);
        const durationMs = Math.round((performance.now() - startTime) * 100) / 100;

        ctx.stagesExecuted.push({
          stage: stage.name,
          durationMs,
          success: true,
        });
      } catch (err) {
        const durationMs = Math.round((performance.now() - startTime) * 100) / 100;
        const stageError =
          err instanceof StageError
            ? err
            : new StageError(stage.name, (err as Error).message, stage.stopOnFailure, err);

        ctx.stagesExecuted.push({
          stage: stage.name,
          durationMs,
          success: false,
          error: stageError.message,
        });

        if (stage.stopOnFailure) {
          ctx.status = 'ABORTED';
          ctx.error = stageError;
          this.logger.error(
            `توقف خط الأنابيب عند المرحلة [${i + 1}: ${stage.name}] للرسالة UID ${ctx.uid}: ${stageError.message}`,
          );
          break;
        } else {
          ctx.status = 'PARTIAL_SUCCESS';
          this.logger.warn(
            `تحذير في المرحلة غير الحرجة [${i + 1}: ${stage.name}] للرسالة UID ${ctx.uid} — استمرار المعالجة: ${stageError.message}`,
          );
        }
      }
    }

    if (ctx.status !== 'ABORTED' && ctx.status !== 'PARTIAL_SUCCESS') {
      ctx.status = 'SUCCESS';
    }

    // حفظ في سجل التفتيش المحلي
    this.recordHistory(ctx);

    return ctx;
  }

  /**
   * استرجاع سجل التنفيذ القابل للتفتيش
   */
  getExecutionHistory(): IngestionContext[] {
    return [...this.executionHistory];
  }

  /**
   * استرجاع سجل الرسائل التي واجهت أخطاء أو توقفت
   */
  getRecentErrors(): IngestionContext[] {
    return this.executionHistory.filter(
      (c) => c.status === 'ABORTED' || c.status === 'PARTIAL_SUCCESS' || !!c.error,
    );
  }

  private recordHistory(ctx: IngestionContext): void {
    if (this.executionHistory.length >= this.maxHistorySize) {
      this.executionHistory.shift();
    }
    this.executionHistory.push({ ...ctx });
  }
}
