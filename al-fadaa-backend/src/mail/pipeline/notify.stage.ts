import { Injectable, Logger } from '@nestjs/common';
import { NotificationType, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { IngestionContext, IngestionStage, StageError } from './ingestion.types';

@Injectable()
export class NotifyStage implements IngestionStage {
  readonly name = 'NotifyStage';
  /** فشل إرسال الإشعار لا يمنع تسجيل المراسلة بل يُسجل ويُسمح بالانتهاء */
  readonly stopOnFailure = false;
  private readonly logger = new Logger('NotifyStage');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async run(ctx: IngestionContext): Promise<void> {
    if (ctx.status === 'ABORTED' || !ctx.correspondenceId) return;

    try {
      const threadRoot = ctx.threadRoot;
      if (threadRoot) {
        // إشعار المعنيين بالخيط
        const recipientSet = new Set<string>();

        const gmUsers = await this.prisma.user.findMany({
          where: { role: Role.GM, isActive: true },
          select: { id: true },
        });
        for (const gm of gmUsers) {
          recipientSet.add(gm.id);
        }

        const lastApproved = await this.prisma.reply.findFirst({
          where: { correspondenceId: threadRoot.id, approvedById: { not: null } },
          orderBy: { approvedAt: 'desc' },
          select: { approvedById: true },
        });
        if (lastApproved?.approvedById) {
          recipientSet.add(lastApproved.approvedById);
        }

        const lastReply = await this.prisma.reply.findFirst({
          where: { correspondenceId: threadRoot.id },
          orderBy: { createdAt: 'desc' },
          select: { authorId: true },
        });
        if (lastReply?.authorId) {
          recipientSet.add(lastReply.authorId);
        }

        if (recipientSet.size > 0) {
          await this.notifications.notifyMany([...recipientSet], {
            type: NotificationType.NEW_INCOMING,
            title: `تعقيب جديد من العميل على ${threadRoot.refNumber}`,
            body: `أرسل «${ctx.senderName}» رداً جديداً: «${ctx.subject}»`,
            link: `/correspondences/${threadRoot.id}`,
            entityType: 'Correspondence',
            entityId: threadRoot.id,
          });
        }
      }
    } catch (err) {
      this.logger.error(
        `[NotifyStage] تعذر إرسال الإشعارات للرسالة ${ctx.refNumber}: ${(err as Error).message}`,
      );
      throw new StageError(
        this.name,
        `فشل إرسال إشعارات البريد الوارد: ${(err as Error).message}`,
        false, // non-fatal
        err,
      );
    }
  }
}
