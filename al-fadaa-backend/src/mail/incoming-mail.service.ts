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

import {
  FetchStage,
  ParseStage,
  DedupeStage,
  ThreadMatchStage,
  PersistStage,
  AttachmentsStage,
  NotifyStage,
  IngestionPipeline,
  IngestionContext,
} from './pipeline';

export { normalizeSubject, stripHtml } from './incoming-mail.utils';

@Injectable()
export class IncomingMailService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('IncomingMail');
  private pollTimer: NodeJS.Timeout | null = null;
  private isPolling = false;
  private pollPending = false;

  /** اتصال IMAP IDLE المخصص للاستجابة اللحظية */
  private idleClient: ImapFlow | null = null;
  private idleReconnectTimer: NodeJS.Timeout | null = null;
  private idleKeepAliveTimer: NodeJS.Timeout | null = null;
  private isIdleConnecting = false;
  private isDestroyed = false;

  /** كاش المستخدم النظامي — يُحمَّل مرة واحدة */
  private systemUserId: string | null = null;

  /** قائمة المرسلين المحجوبين — تُحمَّل من متغير البيئة */
  private blockedSenders: string[] = [];

  private readonly attachmentService: IncomingMailAttachmentService;
  private readonly matcherService: IncomingMailMatcherService;
  private readonly pipeline: IngestionPipeline;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly correspondencesService: CorrespondencesService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() attachmentService?: IncomingMailAttachmentService,
    @Optional() matcherService?: IncomingMailMatcherService,
    @Optional() pipeline?: IngestionPipeline,
  ) {
    this.attachmentService = attachmentService ?? new IncomingMailAttachmentService(this.prisma);
    this.matcherService = matcherService ?? new IncomingMailMatcherService(this.prisma);
    this.pipeline =
      pipeline ??
      new IngestionPipeline(
        new FetchStage(),
        new ParseStage(),
        new DedupeStage(this.prisma, this.config),
        new ThreadMatchStage(this.matcherService),
        new PersistStage(this.prisma, this.correspondencesService, this.audit),
        new AttachmentsStage(this.attachmentService),
        new NotifyStage(this.prisma, this.notifications),
      );
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

    // تشغيل محرك IMAP IDLE Push للاستجابة اللحظية في غضون ثانية
    await this.startIdleListener().catch(() => {});

    // مؤقت فحص دوري أمان (Watchdog) كل 60 ثانية كضمانة ثانوية في حال انقطاع Socket
    const interval = this.config.get<number>('IMAP_POLL_INTERVAL_MS') ?? 60000;
    this.logger.log(`تم تفعيل صمام الأمان الدوري (Watchdog) — فحص احتياطي كل ${interval / 1000} ثانية`);

    this.pollTimer = setInterval(() => {
      this.pollEmails().catch(() => {});
    }, interval);

    // فحص فوري بعد ثانيتين من تشغيل الخادم
    setTimeout(() => {
      this.pollEmails().catch(() => {});
    }, 2000);
  }

  onModuleDestroy(): void {
    this.isDestroyed = true;
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
    this.cleanupIdleClient();
  }

  /**
   * تشغيل اتصال IMAP IDLE Push للاستماع اللحظي للبريد الوارد
   */
  async startIdleListener(): Promise<void> {
    if (this.isDestroyed || this.isIdleConnecting) return;
    this.isIdleConnecting = true;

    const host = this.config.get<string>('IMAP_HOST');
    const port = this.config.get<number>('IMAP_PORT') ?? 993;
    const user = this.config.get<string>('IMAP_USER');
    const pass = this.config.get<string>('IMAP_PASS');

    if (!host || !user || !pass) {
      this.isIdleConnecting = false;
      return;
    }

    try {
      this.cleanupIdleClient();

      this.idleClient = new ImapFlow({
        host,
        port,
        secure: true,
        auth: { user, pass },
        tls: { rejectUnauthorized: false },
        logger: false,
        connectionTimeout: 20000,
        socketTimeout: 30000,
      });

      this.idleClient.on('error', (err) => {
        this.logger.warn(`تنبيه اتصال IMAP IDLE: ${(err as Error).message}`);
      });

      this.idleClient.on('close', () => {
        if (!this.isDestroyed) {
          this.logger.warn('انقطع اتصال IMAP IDLE — ستتم إعادة الاتصال تلقائياً خلال 15 ثانية');
          this.scheduleIdleReconnect(15000);
        }
      });

      // رصد فوري لوصول أي بريد جديد في غضون ثانية
      this.idleClient.on('exists', (data) => {
        this.logger.log(
          `⚡ [IMAP IDLE Push] وصول بريد جديد فورياً (إجمالي الرسائل: ${data.count}) — مزامنة لحظية`,
        );
        if (this.isPolling) {
          this.pollPending = true;
          return;
        }
        this.pollEmails().catch((err) => {
          this.logger.error(`خطأ أثناء معالجة دفع البريد الفوري: ${(err as Error).message}`);
        });
      });

      await this.idleClient.connect();
      await this.idleClient.mailboxOpen('INBOX', { readOnly: true });

      this.logger.log('✅ تم تفعيل اتصال IMAP IDLE Push بنجاح — الاستجابة اللحظية نشطة');

      // تجديد دوري لـ IDLE كل 15 دقيقة وفق RFC 2177
      this.idleKeepAliveTimer = setInterval(() => {
        if (this.idleClient && this.idleClient.usable) {
          this.idleClient.noop().catch(() => {});
        }
      }, 15 * 60 * 1000);
    } catch (err) {
      this.logger.warn(
        `تعذّر بدء اتصال IMAP IDLE Push (${(err as Error).message}) — سيعتمد النظام على الفحص الدوري ويُعاود محاولة IDLE بعد 30 ثانية`,
      );
      this.scheduleIdleReconnect(30000);
    } finally {
      this.isIdleConnecting = false;
    }
  }

  private scheduleIdleReconnect(delayMs = 15000): void {
    if (this.idleReconnectTimer || this.isDestroyed) return;
    this.idleReconnectTimer = setTimeout(() => {
      this.idleReconnectTimer = null;
      this.startIdleListener().catch(() => {});
    }, delayMs);
  }

  private cleanupIdleClient(): void {
    if (this.idleKeepAliveTimer) {
      clearInterval(this.idleKeepAliveTimer);
      this.idleKeepAliveTimer = null;
    }
    if (this.idleReconnectTimer) {
      clearTimeout(this.idleReconnectTimer);
      this.idleReconnectTimer = null;
    }
    if (this.idleClient) {
      try {
        this.idleClient.close();
      } catch {}
      this.idleClient = null;
    }
  }

  /** التحقق من حالة اتصال IDLE (للمراقبة) */
  get isIdleActive(): boolean {
    return !!(this.idleClient && this.idleClient.usable);
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
    if (this.isPolling) {
      this.pollPending = true;
      return;
    }
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

        for (const item of messageList) {
          try {
            // وسمها كمقروءة في السيرفر
            try {
              await client.messageFlagsAdd(item.uid, ['\\Seen'], { uid: true });
            } catch {}

            const ctx: IngestionContext = {
              uid: item.uid,
              source: item.source,
              systemUserId: this.systemUserId!,
              mailbox: 'INBOX',
              stagesExecuted: [],
              status: 'PENDING',
            };

            await this.pipeline.execute(ctx);

            if (ctx.status !== 'ABORTED' || ctx.isDuplicate || ctx.isBlocked) {
              maxProcessedUid = Math.max(maxProcessedUid, item.uid);
            }
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
      if (this.pollPending) {
        this.pollPending = false;
        this.pollEmails().catch(() => {});
      }
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

  /**
   * استرجاع خط أنابيب المعالجة للتفتيش والمراقبة
   */
  getPipeline(): IngestionPipeline {
    return this.pipeline;
  }
}
