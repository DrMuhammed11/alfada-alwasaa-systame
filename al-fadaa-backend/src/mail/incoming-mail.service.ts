import { Injectable, Logger, OnModuleInit, OnModuleDestroy, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImapFlow } from 'imapflow';
import { simpleParser } from 'mailparser';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  NotificationType,
  Priority,
  Role,
} from '@prisma/client';
import { normalizeSubject, stripHtml } from './incoming-mail.utils';
import { IncomingMailAttachmentService } from './incoming-mail-attachment.service';
import { IncomingMailMatcherService } from './incoming-mail-matcher.service';

export { normalizeSubject, stripHtml } from './incoming-mail.utils';

@Injectable()
export class IncomingMailService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('IncomingMail');
  private pollTimer: NodeJS.Timeout | null = null;
  private isPolling = false;

  /** كاش المستخدم النظامي — يُحمَّل مرة واحدة */
  private systemUserId: string | null = null;

  /** قائمة المرسلين المحجوبين — تُحمَّل من متغير البيئة */
  private blockedSenders: string[] = [];

  private readonly attachmentService: IncomingMailAttachmentService;
  private readonly matcherService: IncomingMailMatcherService;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly correspondencesService: CorrespondencesService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() attachmentService?: IncomingMailAttachmentService,
    @Optional() matcherService?: IncomingMailMatcherService,
  ) {
    this.attachmentService = attachmentService ?? new IncomingMailAttachmentService(this.prisma);
    this.matcherService = matcherService ?? new IncomingMailMatcherService(this.prisma);
  }

  async onModuleInit(): Promise<void> {
    const host = this.config.get<string>('IMAP_HOST');
    const user = this.config.get<string>('IMAP_USER');
    const pass = this.config.get<string>('IMAP_PASS');

    if (!host || !user || !pass) {
      this.logger.warn('إعدادات IMAP غير مكتملة في .env — تم تعطيل محرك سحب البريد الآلي');
      return;
    }

    // تحميل قائمة المرسلين المحجوبين
    this.blockedSenders = (this.config.get<string>('IMAP_BLOCKED_SENDERS') || '')
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean);

    // تحميل المستخدم النظامي
    await this.loadSystemUser();

    const interval = this.config.get<number>('IMAP_POLL_INTERVAL_MS') ?? 30000;
    this.logger.log(`تم تفعيل محرك سحب البريد الآلي (IMAP Engine) — فحص كل ${interval / 1000} ثانية من ${user}`);

    // فحص دوري كل 30 ثانية
    this.pollTimer = setInterval(() => {
      this.pollEmails().catch(() => {});
    }, interval);

    // فحص فوري بعد ثانيتين من تشغيل الخادم
    setTimeout(() => {
      this.pollEmails().catch(() => {});
    }, 2000);
  }

  onModuleDestroy(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  /** تحميل المستخدم النظامي مع كاش */
  private async loadSystemUser(): Promise<void> {
    const sysUser = await this.prisma.user.findUnique({
      where: { email: 'mail-engine@al-fadaa.internal' },
      select: { id: true },
    });
    if (sysUser) {
      this.systemUserId = sysUser.id;
      this.logger.log('تم تحميل حساب محرك البريد النظامي');
    } else {
      // سقوط احتياطي: أول GM نشط
      const fallback = await this.prisma.user.findFirst({
        where: { isActive: true, role: { in: [Role.ADMIN, Role.GM] } },
        select: { id: true },
      });
      this.systemUserId = fallback?.id ?? null;
      this.logger.warn('حساب محرك البريد غير موجود — استخدام أول مدير نشط كاحتياط');
    }
  }

  /**
   * فحص صندوق الوارد وسحب الرسائل الجديدة باستخدام علامة الماء (أعلى UID معالج)
   */
  async pollEmails(): Promise<void> {
    if (this.isPolling) return;
    this.isPolling = true;

    const host = this.config.get<string>('IMAP_HOST');
    const port = this.config.get<number>('IMAP_PORT') ?? 993;
    const user = this.config.get<string>('IMAP_USER');
    const pass = this.config.get<string>('IMAP_PASS');

    if (!host || !user || !pass) {
      this.isPolling = false;
      return;
    }

    if (!this.systemUserId) {
      await this.loadSystemUser();
      if (!this.systemUserId) {
        this.isPolling = false;
        return;
      }
    }

    const client = new ImapFlow({
      host,
      port,
      secure: true,
      auth: { user, pass },
      tls: { rejectUnauthorized: false },
      logger: false,
      connectionTimeout: 15000,
      socketTimeout: 20000,
    });

    client.on('error', () => {});

    try {
      await client.connect();
      const lock = await client.getMailboxLock('INBOX');

      try {
        // 1. جلب علامة الماء
        const hwm = await this.prisma.imapHighWaterMark.upsert({
          where: { mailbox: 'INBOX' },
          create: { mailbox: 'INBOX', lastUid: 0 },
          update: {},
        });
        const lastUid = hwm.lastUid;

        // 2. جلب الرسائل بعد آخر UID معالج فقط
        const range = `${lastUid + 1}:*`;
        const messageList: { uid: number; source: Buffer }[] = [];

        for await (const m of client.fetch(range, { uid: true, source: true }, { uid: true })) {
          if (m.source && m.uid && m.uid > lastUid) {
            messageList.push({ uid: m.uid, source: m.source });
          }
        }

        if (messageList.length === 0) return;

        // ترتيب بالأقدم أولاً لضمان التسلسل
        messageList.sort((a, b) => a.uid - b.uid);

        let maxProcessedUid = lastUid;
        const systemAuthUser = {
          id: this.systemUserId!,
          email: 'mail-engine@al-fadaa.internal',
          name: 'محرك البريد',
          role: Role.EMPLOYEE as Role,
        };

        for (const item of messageList) {
          try {
            const parsed = await simpleParser(item.source);
            const senderEmail = (parsed.from?.value[0]?.address || 'unknown@domain.com').toLowerCase().trim();
            const senderName = parsed.from?.value[0]?.name || senderEmail.split('@')[0] || 'مرسل خارجي';
            const subject = (parsed.subject || 'مراسلة واردة عبر البريد الإلكتروني').trim();

            // معالجة HTML الوارد بأمان
            const hasHtml = typeof parsed.html === 'string' && parsed.html.trim().length > 0;
            const plainText = (parsed.text || '').trim();
            const body = plainText || (hasHtml ? stripHtml(parsed.html as string) : '');

            // تجاهل المرسلين المحجوبين من متغير البيئة
            if (this.blockedSenders.includes(senderEmail)) continue;

            const incomingMessageId = parsed.messageId ? parsed.messageId.trim() : null;

            // 1. مكافحة التكرار بـ messageId الفريد
            if (incomingMessageId) {
              const exists = await this.prisma.correspondence.findFirst({
                where: { messageId: incomingMessageId },
              });
              if (exists) {
                maxProcessedUid = Math.max(maxProcessedUid, item.uid);
                continue;
              }
            } else {
              const exists = await this.prisma.correspondence.findFirst({
                where: {
                  senderEmail,
                  subject,
                  body,
                  receivedAt: parsed.date ? new Date(parsed.date) : undefined,
                },
              });
              if (exists) {
                maxProcessedUid = Math.max(maxProcessedUid, item.uid);
                continue;
              }
            }

            // وسمها كمقروءة في السيرفر
            try {
              await client.messageFlagsAdd(item.uid, ['\\Seen'], { uid: true });
            } catch {}

            // بناء metadata مع وسم HTML
            const metadata: Record<string, unknown> = {};
            if (hasHtml) {
              metadata.hasHtml = true;
              metadata.htmlBody = (parsed.html as string).slice(0, 10240);
            }

            // 2. محرك مطابقة الخيط:
            const threadRoot = await this.matcherService.findThreadRoot(
              parsed,
              senderEmail,
              subject,
              body,
            );

            // 3. الربط أو بدء جذر جديد:
            if (threadRoot) {
              const childRefNumber = await this.refNumbers.generate('INC');
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
                  receivedAt: parsed.date ? new Date(parsed.date) : new Date(),
                  createdById: systemAuthUser.id,
                  parentId: threadRoot.id,
                  messageId: incomingMessageId ?? undefined,
                },
              });

              // حفظ المرفقات الواردة إن وُجدت
              await this.attachmentService.saveIncomingAttachments(
                parsed.attachments,
                childCorr.id,
                systemAuthUser.id,
              );

              // قاعدة فتح الخيط
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
                    updatedAt: new Date(),
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
                  data: { updatedAt: new Date() },
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

              // الإشعارات
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
                  body: `أرسل «${senderName}» رداً جديداً: «${subject}»`,
                  link: `/correspondences/${threadRoot.id}`,
                  entityType: 'Correspondence',
                  entityId: threadRoot.id,
                });
              }

              this.logger.log(
                `[IMAP Engine] تم ربط رد وارد جديد ${childRefNumber} بالمحادثة الأصلية ${threadRoot.refNumber} من ${senderEmail}`,
              );
            } else {
              // جذر جديد مع channel=email
              const corr = await this.correspondencesService.createIncoming(
                {
                  subject,
                  body,
                  senderName,
                  senderEmail,
                  priority: Priority.NORMAL,
                  messageId: incomingMessageId ?? undefined,
                  channel: 'email',
                },
                systemAuthUser,
              );

              // حفظ المرفقات الواردة إن وُجدت
              await this.attachmentService.saveIncomingAttachments(
                parsed.attachments,
                corr.id,
                systemAuthUser.id,
              );

              this.logger.log(
                `[IMAP Engine] تم تسجيل مراسلة واردة جديدة برقم ${corr.refNumber} من ${senderEmail} - الموضوع: "${subject}"`,
              );
            }

            maxProcessedUid = Math.max(maxProcessedUid, item.uid);
          } catch (msgErr) {
            this.logger.error(`خطأ في معالجة رسالة UID ${item.uid}: ${(msgErr as Error).message}`);
            maxProcessedUid = Math.max(maxProcessedUid, item.uid);
          }
        }

        // 3. تحديث علامة الماء
        if (maxProcessedUid > lastUid) {
          await this.prisma.imapHighWaterMark.update({
            where: { mailbox: 'INBOX' },
            data: { lastUid: maxProcessedUid },
          });
        }
      } finally {
        lock.release();
      }
    } catch {
      // انقطاع شبكي مؤقت — يتجاوزه النظام بهدوء
    } finally {
      try {
        await client.logout();
      } catch {}
      this.isPolling = false;
    }
  }

  /**
   * حفظ مرفقات رسالة العميل على القرص وإنشاء سجلات لها في قاعدة البيانات
   */
  async saveIncomingAttachments(
    attachments: any[] | undefined,
    correspondenceId: string,
    systemUserId: string,
  ): Promise<void> {
    return this.attachmentService.saveIncomingAttachments(
      attachments,
      correspondenceId,
      systemUserId,
    );
  }

  /**
   * إجمالي عدد المراسلات الواردة في قاعدة البيانات — يُستخدم لحساب الفرق بعد المزامنة
   */
  async getCorrespondenceCount(): Promise<number> {
    return this.prisma.correspondence.count({
      where: { type: 'INCOMING' },
    });
  }
}
