import { ParsedMail } from 'mailparser';
import { ThreadRootRecord } from '../incoming-mail-matcher.service';

export interface StageExecutionRecord {
  stage: string;
  durationMs: number;
  success: boolean;
  skipped?: boolean;
  error?: string;
}

export class StageError extends Error {
  constructor(
    public readonly stageName: string,
    message: string,
    public readonly isFatal: boolean = true,
    public readonly originalError?: unknown,
  ) {
    super(`[المرحلة: ${stageName}] ${message}`);
    this.name = 'StageError';
  }
}

export interface IngestionContext {
  uid: number;
  source?: Buffer;
  internalDate?: Date;
  parsed?: ParsedMail;
  senderEmail?: string;
  senderName?: string;
  subject?: string;
  body?: string;
  hasHtml?: boolean;
  incomingMessageId?: string | null;
  isBlocked?: boolean;
  isDuplicate?: boolean;
  threadRoot?: ThreadRootRecord | null;
  correspondenceId?: string;
  refNumber?: string;
  childRefNumber?: string;
  isChild?: boolean;
  attachmentsSavedCount?: number;
  systemUserId: string;
  mailbox?: string;
  stagesExecuted: StageExecutionRecord[];
  error?: StageError;
  status: 'PENDING' | 'SUCCESS' | 'ABORTED' | 'PARTIAL_SUCCESS';
}

export interface IngestionStage {
  readonly name: string;
  /** هل الفشل في هذه المرحلة يوقف معالجة الرسالة بالكامل؟ */
  readonly stopOnFailure: boolean;
  run(ctx: IngestionContext): Promise<void>;
}
