import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
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
import * as fs from 'fs';
import * as path from 'path';

/**
 * تنظيف موضوع الرسالة من البادئات وأرقام المراجع لمطابقة محادثات البريد
 */
function normalizeSubject(subject: string): string {
  let s = (subject || '').trim();
  s = s.replace(/\[?(?:INC|OUT|INT)-\d{4}-\d{5,6}\]?/gi, '').trim();
  const prefixRegex = /^(re|fwd|fw|رد|اعادة|إعادة)\s*[:：\-]\s*/i;
  while (prefixRegex.test(s)) {
    s = s.replace(prefixRegex, '').trim();
  }
  return s.trim();
}

/**
 * تجريد وسوم HTML والإبقاء على النص المرئي فقط
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

@Injectable()
export class IncomingMailService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('IncomingMail');
  private pollTimer: NodeJS.Timeout | null = null;
  private isPolling = false;

  /** كاش المستخدم النظامي — يُحمَّل مرة واحدة */
  private systemUserId: string | null = null;

  /** قائمة المرسلين المحجوبين — تُحمَّل من متغير البيئة */
  private blockedSenders: string[] = [];

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly correspondencesService: CorrespondencesService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

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
            let threadRoot: {
              id: string;
              refNumber: string;
              subject: string;
              priority: Priority;
              status: CorrespondenceStatus;
            } | null = null;

            // (أ) طابق رأس In-Reply-To/References مع messageId المحفوظ
            const candidateIds: string[] = [];
            const rawInReplyTo = parsed.inReplyTo || (parsed.headers && parsed.headers.get('in-reply-to'));
            const rawReferences = parsed.references || (parsed.headers && parsed.headers.get('references'));
            const parseHeaderIds = (val: unknown) => {
              if (!val) return;
              const str = Array.isArray(val) ? val.join(' ') : String(val);
              const matches = str.match(/<[^>]+>|[^\s,]+/g) || [];
              for (const m of matches) {
                const t = m.trim();
                if (t) {
                  candidateIds.push(t);
                  if (t.startsWith('<') && t.endsWith('>')) {
                    candidateIds.push(t.slice(1, -1));
                  } else {
                    candidateIds.push(`<${t}>`);
                  }
                }
              }
            };
            parseHeaderIds(rawInReplyTo);
            parseHeaderIds(rawReferences);

            if (candidateIds.length > 0) {
              const matchedCorr = await this.prisma.correspondence.findFirst({
                where: { messageId: { in: [...new Set(candidateIds)] } },
                select: { id: true, parentId: true },
              });
              if (matchedCorr) {
                const rootId = matchedCorr.parentId ?? matchedCorr.id;
                threadRoot = await this.prisma.correspondence.findUnique({
                  where: { id: rootId },
                  select: { id: true, refNumber: true, subject: true, priority: true, status: true },
                });
              }
            }

            // (ب) إن لم يوجد، فطابق آخر صادر أُرسل لنفس بريد المُرسل خلال آخر 30 يومًا
            if (!threadRoot) {
              const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
              const lastOutgoing = await this.prisma.correspondence.findFirst({
                where: {
                  type: CorrespondenceType.OUTGOING,
                  sentAt: { gte: thirtyDaysAgo },
                  OR: [
                    { parent: { senderEmail } },
                    { senderEmail },
                  ],
                },
                orderBy: { sentAt: 'desc' },
                select: { id: true, parentId: true },
              });
              if (lastOutgoing) {
                const rootId = lastOutgoing.parentId ?? lastOutgoing.id;
                threadRoot = await this.prisma.correspondence.findUnique({
                  where: { id: rootId },
                  select: { id: true, refNumber: true, subject: true, priority: true, status: true },
                });
              }
            }

            // إجراء وقائي: البحث عن رقم مرجعي صريح في الموضوع إن وُجد
            if (!threadRoot) {
              const refMatch = subject.match(/(?:INC|OUT|INT)-\d{4}-\d{5,6}/i) || body.match(/(?:INC|OUT|INT)-\d{4}-\d{5,6}/i);
              if (refMatch) {
                const referenced = await this.prisma.correspondence.findUnique({
                  where: { refNumber: refMatch[0].toUpperCase() },
                  select: { id: true, parentId: true },
                });
                if (referenced) {
                  const rootId = referenced.parentId ?? referenced.id;
                  threadRoot = await this.prisma.correspondence.findUnique({
                    where: { id: rootId },
                    select: { id: true, refNumber: true, subject: true, priority: true, status: true },
                  });
                }
              }
            }

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
              await this.saveIncomingAttachments(
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
              await this.saveIncomingAttachments(
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
  private async saveIncomingAttachments(
    attachments: any[] | undefined,
    correspondenceId: string,
    systemUserId: string,
  ): Promise<void> {
    if (!attachments || attachments.length === 0) return;

    const allowedMimes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/zip',
      'text/plain',
    ];
    const maxSizeBytes = 15 * 1024 * 1024;
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    for (const att of attachments) {
      try {
        const size = att.size || att.content?.length || 0;
        if (size > maxSizeBytes) {
          this.logger.warn(
            `تجاوز حجم المرفق «${att.filename}» الحد المسموح (15MB) — تم تخطيه`,
          );
          continue;
        }

        const mime = (att.contentType || '').toLowerCase().trim();
        const ext = path.extname(att.filename || '').toLowerCase();
        const isAllowedExt = [
          '.pdf',
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.zip',
          '.txt',
        ].includes(ext);

        if (!allowedMimes.includes(mime) && !isAllowedExt) {
          this.logger.warn(
            `نوع المرفق «${att.filename}» (${mime}) غير مدعوم — تم تخطيه`,
          );
          continue;
        }

        const unique = `${Date.now()}-${Math.round(Math.random() * 1_000_000_000)}`;
        const storedName = `${unique}${ext || ''}`;
        const filePath = path.join(uploadDir, storedName);

        if (att.content && Buffer.isBuffer(att.content)) {
          await fs.promises.writeFile(filePath, att.content);
          await this.prisma.attachment.create({
            data: {
              correspondenceId,
              fileName: att.filename || 'attachment',
              storedName,
              mimeType: mime || 'application/octet-stream',
              size,
              uploadedById: systemUserId,
            },
          });
          this.logger.log(
            `[IMAP Engine] تم حفظ المرفق «${att.filename}» (${(size / 1024).toFixed(1)}KB) للمراسلة`,
          );
        }
      } catch (err) {
        this.logger.error(
          `فشل حفظ المرفق «${att.filename}»: ${(err as Error).message}`,
        );
      }
    }
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
