import { Injectable, Logger } from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  Priority,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CorrespondencesService } from '../../correspondences/correspondences.service';
import { AuditService } from '../../audit/audit.service';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class PersistStage implements IngestionStage {
  readonly name = 'PersistStage';
  readonly stopOnFailure = true;
  private readonly logger = new Logger('PersistStage');

  constructor(
    private readonly prisma: PrismaService,
    private readonly correspondencesService: CorrespondencesService,
    private readonly audit: AuditService,
  ) {}

  async run(ctx: IngestionContext): Promise<void> {
    if (ctx.status === 'ABORTED') return;

    try {
      const parsed = ctx.parsed!;
      const senderEmail = ctx.senderEmail!;
      const senderName = ctx.senderName!;
      const subject = ctx.subject!;
      const body = ctx.body!;
      const incomingMessageId = ctx.incomingMessageId;
      const threadRoot = ctx.threadRoot;

      const systemAuthUser = {
        id: ctx.systemUserId,
        email: 'mail-engine@al-fadaa.internal',
        name: 'محرك البريد',
        role: Role.EMPLOYEE as Role,
      };

      const metadata: Record<string, unknown> = {};
      if (ctx.hasHtml && parsed.html) {
        metadata.hasHtml = true;
        metadata.htmlBody = (parsed.html as string).slice(0, 10240);
      }

      if (threadRoot) {
        // 1. إنشاء تعقيب على خيط محادثة قائم
        const childCount = await this.prisma.correspondence.count({
          where: { parentId: threadRoot.id },
        });
        let seq = childCount + 1;
        let childRefNumber = `${threadRoot.refNumber}#${seq}`;
        while (
          await this.prisma.correspondence.findUnique({
            where: { refNumber: childRefNumber },
            select: { id: true },
          })
        ) {
          seq++;
          childRefNumber = `${threadRoot.refNumber}#${seq}`;
        }

        const actualEmailDate = ctx.internalDate || (parsed.date ? new Date(parsed.date) : new Date());

        const childCorr = await this.prisma.correspondence.create({
          data: {
            refNumber: childRefNumber,
            type: CorrespondenceType.INCOMING,
            subject,
            body,
            priority: threadRoot.priority,
            status: CorrespondenceStatus.RECEIVED,
            senderName,
            senderEmail,
            channel: 'email',
            receivedAt: actualEmailDate,
            createdAt: actualEmailDate,
            updatedAt: actualEmailDate,
            createdById: systemAuthUser.id,
            parentId: threadRoot.id,
            messageId: incomingMessageId ?? undefined,
          },
        });

        ctx.correspondenceId = childCorr.id;
        ctx.refNumber = childRefNumber;
        ctx.childRefNumber = childRefNumber;

        // قاعدة فتح الخيط إذا كان مغلقاً أو مرسلاً أو مؤرشفاً
        const shouldReopen = (
          [
            CorrespondenceStatus.SENT,
            CorrespondenceStatus.CLOSED,
            CorrespondenceStatus.ARCHIVED,
          ] as CorrespondenceStatus[]
        ).includes(threadRoot.status);

        if (shouldReopen) {
          await this.prisma.correspondence.update({
            where: { id: threadRoot.id },
            data: {
              status: CorrespondenceStatus.IN_PROGRESS,
              closedAt: null,
              updatedAt: actualEmailDate,
            },
          });
          await this.audit.log({
            action: AuditAction.UPDATE,
            entityType: 'Correspondence',
            entityId: threadRoot.id,
            summary: 'إعادة فتح الخيط بسبب رد العميل',
            metadata: {
              previousStatus: threadRoot.status,
              newStatus: CorrespondenceStatus.IN_PROGRESS,
              childRefNumber,
              senderEmail,
            },
          });
        } else {
          await this.prisma.correspondence.update({
            where: { id: threadRoot.id },
            data: { updatedAt: actualEmailDate },
          });
        }

        await this.audit.log({
          action: AuditAction.CREATE,
          entityType: 'Correspondence',
          entityId: childCorr.id,
          summary: `استلام تعقيب جديد ${childRefNumber} من العميل «${senderName}» على المحادثة ${threadRoot.refNumber}`,
          metadata: {
            parentId: threadRoot.id,
            parentRefNumber: threadRoot.refNumber,
            subject,
            messageId: incomingMessageId,
            ...metadata,
          },
        });
      } else {
        const actualEmailDate = ctx.internalDate || (parsed.date ? new Date(parsed.date) : new Date());

        // 2. تسجيل جذر مراسلة واردة جديد مع تمرير تاريخ الاستلام الفعلي
        const corr = await this.correspondencesService.createIncoming(
          {
            subject,
            body,
            senderName,
            senderEmail,
            priority: Priority.NORMAL,
            messageId: incomingMessageId ?? undefined,
            channel: 'email',
            receivedAt: actualEmailDate.toISOString(),
          },
          systemAuthUser,
        );

        ctx.correspondenceId = corr.id;
        ctx.refNumber = corr.refNumber;
      }

      // 3. تحديث علامة الماء ImapHighWaterMark حصريًا بعد نجاح الحفظ لضمان عدم فقدان أي رسالة
      const mailbox = ctx.mailbox ?? 'INBOX';
      const existingHwm = await this.prisma.imapHighWaterMark.findUnique({
        where: { mailbox },
      });
      if (!existingHwm || ctx.uid > existingHwm.lastUid) {
        await this.prisma.imapHighWaterMark.upsert({
          where: { mailbox },
          create: { mailbox, lastUid: ctx.uid },
          update: { lastUid: ctx.uid },
        });
      }

      this.logger.log(`[PersistStage] تم حفظ المراسلة بنجاح برقم مرجعي: ${ctx.refNumber}`);
    } catch (err) {
      throw new StageError(
        this.name,
        `فشل حفظ المراسلة في قاعدة البيانات: ${(err as Error).message}`,
        true,
        err,
      );
    }
  }
}
