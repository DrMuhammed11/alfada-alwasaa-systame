import { IngestionPipeline } from './ingestion.pipeline';
import { FetchStage } from './fetch.stage';
import { ParseStage } from './parse.stage';
import { DedupeStage } from './dedupe.stage';
import { ThreadMatchStage } from './thread-match.stage';
import { PersistStage } from './persist.stage';
import { AttachmentsStage } from './attachments.stage';
import { NotifyStage } from './notify.stage';
import { IngestionContext } from './ingestion.types';

describe('Mail Ingestion Pipeline (خط أنابيب معالجة البريد الوارد)', () => {
  let pipeline: IngestionPipeline;

  let prismaMock: any;
  let configMock: any;
  let matcherMock: any;
  let correspondencesMock: any;
  let auditMock: any;
  let attachmentMock: any;
  let notificationsMock: any;

  let highWaterMarkStore: Record<string, number> = {};

  beforeEach(() => {
    highWaterMarkStore = { INBOX: 10 };

    prismaMock = {
      correspondence: {
        findFirst: jest.fn().mockResolvedValue(null),
        findUnique: jest.fn().mockResolvedValue(null),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn().mockResolvedValue({ id: 'corr-new', refNumber: 'INC-2026-00001' }),
        update: jest.fn().mockResolvedValue({}),
      },
      user: {
        findMany: jest.fn().mockResolvedValue([{ id: 'gm-1' }]),
      },
      reply: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      imapHighWaterMark: {
        findUnique: jest.fn().mockImplementation(async ({ where }: any) => {
          const lastUid = highWaterMarkStore[where.mailbox];
          return lastUid !== undefined ? { mailbox: where.mailbox, lastUid } : null;
        }),
        upsert: jest.fn().mockImplementation(async ({ where, create, update }: any) => {
          const val = update?.lastUid ?? create?.lastUid ?? 0;
          highWaterMarkStore[where.mailbox] = val;
          return { mailbox: where.mailbox, lastUid: val };
        }),
      },
    };

    configMock = {
      get: jest.fn().mockImplementation((key: string) => {
        if (key === 'IMAP_BLOCKED_SENDERS') return 'spam@blocked.com';
        return undefined;
      }),
    };

    matcherMock = {
      findThreadRoot: jest.fn().mockResolvedValue(null),
    };

    correspondencesMock = {
      createIncoming: jest.fn().mockResolvedValue({
        id: 'corr-new-1',
        refNumber: 'INC-2026-00001',
      }),
    };

    auditMock = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    attachmentMock = {
      saveIncomingAttachments: jest.fn().mockResolvedValue(undefined),
    };

    notificationsMock = {
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    const fetchStage = new FetchStage();
    const parseStage = new ParseStage();
    const dedupeStage = new DedupeStage(prismaMock, configMock);
    const threadMatchStage = new ThreadMatchStage(matcherMock);
    const persistStage = new PersistStage(prismaMock, correspondencesMock, auditMock);
    const attachmentsStage = new AttachmentsStage(attachmentMock);
    const notifyStage = new NotifyStage(prismaMock, notificationsMock);

    pipeline = new IngestionPipeline(
      fetchStage,
      parseStage,
      dedupeStage,
      threadMatchStage,
      persistStage,
      attachmentsStage,
      notifyStage,
    );
  });

  const sampleRawEmail = Buffer.from(
    `From: Customer <client@domain.com>
To: info@al-fadaa.com
Subject: استفسار حول مشروع التوريد
Message-ID: <msg-unique-123@domain.com>
Date: Mon, 07 Sep 2026 10:00:00 +0300
Content-Type: text/plain; charset="utf-8"

السلام عليكم، نود الاستفسار عن تفاصيل التوريد.`,
  );

  it('ينفذ المراحل السبع بنجاح لرسالة جديدة ويقيس زمن كل مرحلة', async () => {
    const ctx: IngestionContext = {
      uid: 15,
      source: sampleRawEmail,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    const result = await pipeline.execute(ctx);

    expect(result.status).toBe('SUCCESS');
    expect(result.senderEmail).toBe('client@domain.com');
    expect(result.subject).toBe('استفسار حول مشروع التوريد');
    expect(result.refNumber).toBe('INC-2026-00001');

    // التحقق من تسجيل المراحل السبع مع أزمنة التنفيذ
    expect(result.stagesExecuted.length).toBe(7);
    expect(result.stagesExecuted.map((s) => s.stage)).toEqual([
      'FetchStage',
      'ParseStage',
      'DedupeStage',
      'ThreadMatchStage',
      'PersistStage',
      'AttachmentsStage',
      'NotifyStage',
    ]);
    expect(result.stagesExecuted.every((s) => s.success && s.durationMs >= 0)).toBe(true);

    // التحقق من تحديث ImapHighWaterMark بعد الحفظ
    expect(highWaterMarkStore['INBOX']).toBe(15);
  });

  it('يوقف الرسالة ولا يحدث ImapHighWaterMark عند فشل مرحلة الحفظ PersistStage', async () => {
    correspondencesMock.createIncoming.mockRejectedValueOnce(
      new Error('Database unique constraint failed'),
    );

    const ctx: IngestionContext = {
      uid: 20,
      source: sampleRawEmail,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    const result = await pipeline.execute(ctx);

    expect(result.status).toBe('ABORTED');
    expect(result.error).toBeDefined();
    expect(result.error?.stageName).toBe('PersistStage');
    expect(result.error?.message).toContain('PersistStage');

    // علامة الماء يجب ألا تتحدث حتى لا تُفقد الرسالة
    expect(highWaterMarkStore['INBOX']).toBe(10);
  });

  it('فشل حفظ المرفقات غير قاتل: يتم إنشاء المراسلة وتوثيق الخطأ كـ PARTIAL_SUCCESS', async () => {
    // محاكاة بريد يحتوي على مرفق
    const emailWithAttachment = Buffer.from(
      `From: Client <client@domain.com>
To: info@al-fadaa.com
Subject: رسالة بمرفق
Message-ID: <msg-att-1@domain.com>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="sep"

--sep
Content-Type: text/plain; charset="utf-8"

نص الرسالة

--sep
Content-Type: application/pdf; name="doc.pdf"
Content-Disposition: attachment; filename="doc.pdf"
Content-Transfer-Encoding: base64

AQIDBA==
--sep--`,
    );

    attachmentMock.saveIncomingAttachments.mockRejectedValueOnce(
      new Error('Disk storage full'),
    );

    const ctx: IngestionContext = {
      uid: 25,
      source: emailWithAttachment,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    const result = await pipeline.execute(ctx);

    // المراسلة تم حفظها بنجاح وعلامة الماء حُدثت
    expect(result.status).toBe('PARTIAL_SUCCESS');
    expect(result.refNumber).toBe('INC-2026-00001');
    expect(highWaterMarkStore['INBOX']).toBe(25);

    // تم تسجيل خطأ مرحلة المرفقات بدقة بالاسم
    const attStageResult = result.stagesExecuted.find((s) => s.stage === 'AttachmentsStage');
    expect(attStageResult?.success).toBe(false);
    expect(attStageResult?.error).toContain('تعذر حفظ بعض المرفقات');
  });

  it('يتعرف على الرسائل المكررة في DedupeStage ويوقف الخط دون إعادة الحفظ', async () => {
    prismaMock.correspondence.findFirst.mockResolvedValueOnce({
      id: 'existing-corr',
      refNumber: 'INC-2026-99999',
    });

    const ctx: IngestionContext = {
      uid: 30,
      source: sampleRawEmail,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    const result = await pipeline.execute(ctx);

    expect(result.status).toBe('ABORTED');
    expect(result.isDuplicate).toBe(true);
    expect(correspondencesMock.createIncoming).not.toHaveBeenCalled();
  });

  it('يتعرف على المرسلين المحجوبين ويتوقف فوراً', async () => {
    const blockedEmail = Buffer.from(
      `From: Spammer <spam@blocked.com>
To: info@al-fadaa.com
Subject: إعلان تجاري
Message-ID: <spam-1@domain.com>

رسالة غير مرغوب فيها`,
    );

    const ctx: IngestionContext = {
      uid: 35,
      source: blockedEmail,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    const result = await pipeline.execute(ctx);

    expect(result.status).toBe('ABORTED');
    expect(result.isBlocked).toBe(true);
    expect(correspondencesMock.createIncoming).not.toHaveBeenCalled();
  });

  it('يحتفظ بسجل تشغيل قابل للتفتيش لعمليات المعالجة', async () => {
    const ctx: IngestionContext = {
      uid: 40,
      source: sampleRawEmail,
      systemUserId: 'sys-user',
      mailbox: 'INBOX',
      stagesExecuted: [],
      status: 'PENDING',
    };

    await pipeline.execute(ctx);

    const history = pipeline.getExecutionHistory();
    expect(history.length).toBeGreaterThan(0);
    expect(history[history.length - 1].uid).toBe(40);
  });
});
