import { AuditAction, NotificationType, Prisma } from '@prisma/client';

export enum OutboxEventType {
  REFERRAL_CREATED = 'REFERRAL_CREATED',
  TASK_ASSIGNED = 'TASK_ASSIGNED',
  REPLY_SUBMITTED = 'REPLY_SUBMITTED',
  REPLY_APPROVED = 'REPLY_APPROVED',
  REPLY_REJECTED = 'REPLY_REJECTED',
  REPLY_SENT = 'REPLY_SENT',
  CORRESPONDENCE_CLOSED = 'CORRESPONDENCE_CLOSED',
  CORRESPONDENCE_ARCHIVED = 'CORRESPONDENCE_ARCHIVED',
}

export interface OutboxAuditPayload {
  action: AuditAction;
  summary?: string;
  entityType?: string;
  entityId?: string;
  metadata?: Prisma.InputJsonValue;
  userId?: string;
}

export interface OutboxNotificationPayload {
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
  entityType?: string;
  entityId?: string;
  userId?: string;
  recipientIds?: string[];
}

export interface OutboxPayload {
  audit?: OutboxAuditPayload;
  notification?: OutboxNotificationPayload;
  [key: string]: unknown;
}

export interface OutboxEmitDto {
  type: string;
  payload: OutboxPayload;
}
