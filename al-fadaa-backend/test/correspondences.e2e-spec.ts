import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

/**
 * اختبار e2e — الرحلة الكاملة لدورة حياة المراسلة (المخطط الثاني):
 *
 *  تسجيل وارد (GM) → إحالة لمدير القسم (GM) → تكليف موظف (مدير القسم)
 *  → مسودة رد (الموظف) → رفع للاعتماد → اعتماد (مدير القسم)
 *  → رفض الإرسال من غير المدير العام (403) → الإرسال (GM)
 *  → التحقق من السلسلة كاملة في سجل التدقيق
 */
describe('دورة حياة المراسلة الكاملة (e2e)', () => {
  let app: INestApplication;
  let httpServer: any;

  const PASSWORD = 'Alfadaa@2026';
  const year = new Date().getFullYear();

  let gmToken = '';
  let adminToken = '';
  let engManagerToken = '';
  let employeeToken = '';

  let correspondenceId = '';
  let correspondenceRef = '';
  let referralId = '';
  let taskId = '';
  let replyId = '';
  let outgoingRef = '';
  let attachmentId = '';

  /** تسجيل دخول مساعد */
  const login = async (email: string) => {
    const res = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email, password: PASSWORD });
    expect(res.status).toBe(201);
    return res.body.accessToken as string;
  };

  /** جلب هوية مستخدم من seed (للإحالة والتكليف) */
  const findUserId = async (token: string, email: string): Promise<string> => {
    const res = await request(httpServer)
      .get(`/api/v1/users?limit=100`)
      .set('Authorization', `Bearer ${token}`);
    const user = res.body.data.find((u: any) => u.email === email);
    expect(user).toBeTruthy();
    return user.id as string;
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    httpServer = app.getHttpServer();

    gmToken = await login('gm@al-fadaa.com');
    adminToken = await login('admin@al-fadaa.com');
    engManagerToken = await login('eng.manager@al-fadaa.com');
    employeeToken = await login('eng.employee1@al-fadaa.com');
  });

  afterAll(async () => {
    await app.close();
  });

  // ────── المرحلة 1: التسجيل ──────

  it('الموظف لا يستطيع تسجيل مراسلة واردة (403 — ليس من صلاحياته)', async () => {
    const res = await request(httpServer)
      .post('/api/v1/correspondences/incoming')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ subject: 'اختبار', senderName: 'عميل' });
    expect(res.status).toBe(403);
  });

  it('المدير العام يسجّل مراسلة واردة برقم مرجعي تسلسلي', async () => {
    const res = await request(httpServer)
      .post('/api/v1/correspondences/incoming')
      .set('Authorization', `Bearer ${gmToken}`)
      .send({
        subject: 'طلب تعاون في مشروع برج الفضاء التجاري',
        body: 'نرغب بدراسة جدوى التعاون في تنفيذ البرج التجاري الجديد.',
        senderName: 'شركة الأفق للمقاولات',
        senderEmail: 'info@ofoq-contracting.com',
        priority: 'HIGH',
      });

    expect(res.status).toBe(201);
    expect(res.body.refNumber).toBe(`INC-${year}-00003`); // الـ seed أنشأ 00001 و 00002
    expect(res.body.status).toBe('RECEIVED');
    correspondenceId = res.body.id;
    correspondenceRef = res.body.refNumber;
  });

  it('الموظف لا يرى المراسلة (خارج نطاقه) — 403، والمدير العام يراها', async () => {
    const forbidden = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${employeeToken}`);
    expect(forbidden.status).toBe(403);

    const ok = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(ok.status).toBe(200);
    expect(ok.body.subject).toContain('برج الفضاء');
  });

  it('رفع مرفق للمراسلة يعمل (multipart)', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/correspondences/${correspondenceId}/attachments`)
      .set('Authorization', `Bearer ${gmToken}`)
      .attach('file', Buffer.from('محتوى ملف تجريبي PDF'), 'ملف-العرض.pdf');
    // Multer يحصل على ال mimetype من الامتداد
    expect([201, 200]).toContain(res.status);
    expect(res.body.fileName).toContain('pdf');
    attachmentId = res.body.id;
  });

  // ─────ـ المرحلة 2: الإحالة ──────

  it('المدير العام يحيل المراسلة لمدير القسم الهندسي', async () => {
    const engManagerId = await findUserId(adminToken, 'eng.manager@al-fadaa.com');
    const res = await request(httpServer)
      .post(`/api/v1/correspondences/${correspondenceId}/referrals`)
      .set('Authorization', `Bearer ${gmToken}`)
      .send({
        toUserId: engManagerId,
        note: 'للدراسة وإعداد الرد',
        dueDate: new Date(Date.now() + 86400000).toISOString(),
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe('OPEN');
    referralId = res.body.id;

    // حالة المراسلة أصبحت محالة وربطت بالقسم الهندسي
    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(corr.body.status).toBe('REFERRED');
    expect(corr.body.department.name).toBe('القسم الهندسي');
  });

  it('مدير القسم يجد الإحالة في صندوق إحالاته', async () => {
    const res = await request(httpServer)
      .get('/api/v1/referrals/my')
      .set('Authorization', `Bearer ${engManagerToken}`);
    expect(res.status).toBe(200);
    const found = res.body.data.some((r: any) => r.id === referralId);
    expect(found).toBe(true);
  });

  // ────── المرحلة 3: التكليف ──────

  it('مدير القسم يكلّف موظفًا من قسمه، ولا يستطيع تكليف موظف من قسم آخر', async () => {
    const engEmpId = await findUserId(adminToken, 'eng.employee1@al-fadaa.com');
    const finEmpId = await findUserId(adminToken, 'fin.employee1@al-fadaa.com');

    // تكليف من قسم آخر → مرفوض
    const bad = await request(httpServer)
      .post(`/api/v1/correspondences/${correspondenceId}/tasks`)
      .set('Authorization', `Bearer ${engManagerToken}`)
      .send({ title: 'تكليف خاطئ', assignedToId: finEmpId });
    expect(bad.status).toBe(400);

    // التكليف الصحيح
    const res = await request(httpServer)
      .post(`/api/v1/correspondences/${correspondenceId}/tasks`)
      .set('Authorization', `Bearer ${engManagerToken}`)
      .send({
        title: 'إعداد دراسة التعاون ورد رسمي',
        description: 'تشمل الجدوى والجدول الزمني',
        assignedToId: engEmpId,
        referralId,
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe('PENDING');
    taskId = res.body.id;
  });

  it('الموظف المكلَّف يرى المراسلة الآن ضمن مهامه', async () => {
    const tasks = await request(httpServer)
      .get('/api/v1/tasks/my')
      .set('Authorization', `Bearer ${employeeToken}`);
    expect(tasks.status).toBe(200);
    expect(tasks.body.data.some((t: any) => t.id === taskId)).toBe(true);

    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${employeeToken}`);
    expect(corr.status).toBe(200);
  });

  it('الموظف يبدأ التنفيذ (PENDING → IN_PROGRESS)', async () => {
    const res = await request(httpServer)
      .patch(`/api/v1/tasks/${taskId}/status`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ status: 'IN_PROGRESS' });
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('IN_PROGRESS');
  });

  // ────── المرحلة 4: المسودة ──────

  it('الموظف يعدّ مسودة رد — والمراسلة تصبح «جاري إعداد الرد»', async () => {
    const res = await request(httpServer)
      .post('/api/v1/replies')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({
        correspondenceId,
        taskId,
        body: 'يسرّنا إبلاغكم موافقتنا المبدئية على دراسة التعاون، وسنرسل العرض التفصيلي خلال أسبوع.',
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe('DRAFT');
    replyId = res.body.id;

    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(corr.body.status).toBe('IN_PROGRESS');
  });

  it('الموظف لا يستطيع الاعتماد أو الإرسال — فقط المشرفون والمدير العام', async () => {
    const approve = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/approve`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({});
    expect(approve.status).toBe(403);

    const send = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/send`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({});
    expect(send.status).toBe(403);
  });

  it('الموظف يرفع المسودة للاعتماد — المراسلة «بانتظار الاعتماد»', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/submit`)
      .set('Authorization', `Bearer ${employeeToken}`);
    expect(res.status).toBe(201);
    expect(res.body.status).toBe('SUBMITTED');

    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(corr.body.status).toBe('PENDING_APPROVAL');
  });

  // ────── المرحلة 5: الاعتماد ──────

  it('مدير القسم يعتمد الرد — والمراسلة «معتمدة»', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/approve`)
      .set('Authorization', `Bearer ${engManagerToken}`)
      .send({});
    expect(res.status).toBe(201);
    expect(res.body.status).toBe('APPROVED');
    expect(res.body.approvedBy.email).toBe('eng.manager@al-fadaa.com');

    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(corr.body.status).toBe('APPROVED');
    // الإحالة أصبحت «تم الرد عليها»
    const referrals = corr.body.referrals as any[];
    expect(referrals[0].status).toBe('ANSWERED');
  });

  it('مدير القسم لا يستطيع الإرسال — حصري للمدير العام (403)', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/send`)
      .set('Authorization', `Bearer ${engManagerToken}`)
      .send({});
    expect(res.status).toBe(403);
  });

  // ────── المرحلة 6: الإرسال ──────

  it('المدير العام يرسل الرد — يتولد رقم صادر وترتبط السلسلة', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/send`)
      .set('Authorization', `Bearer ${gmToken}`)
      .send({});

    expect(res.status).toBe(201);
    expect(res.body.sent).toBe(true);
    expect(res.body.refNumber).toMatch(/^OUT-\d{4}-\d{5}$/);
    outgoingRef = res.body.refNumber;

    const corr = await request(httpServer)
      .get(`/api/v1/correspondences/${correspondenceId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(corr.body.status).toBe('SENT');
    expect(corr.body.sentAt).toBeTruthy();
    // سلسلة المراسلة: الصادر مرتبط كابن للوارد
    expect(corr.body.children[0].refNumber).toBe(outgoingRef);
    // التكليف أُقفل كمنجز
    expect(corr.body.tasks[0].status).toBe('DONE');
  });

  it('لا يمكن إرسال رد ثانٍ لنفس المراسلة (409 منطقي — 400)', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/replies/${replyId}/send`)
      .set('Authorization', `Bearer ${gmToken}`)
      .send({});
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it('سجل التدقيق يحتوي السلسلة الكاملة: تسجيل ← إحالة ← تكليف ← مسودة ← رفع ← اعتماد ← إرسال', async () => {
    // أحداث المراسلة نفسها
    const corrRes = await request(httpServer)
      .get(`/api/v1/audit?entityType=Correspondence&entityId=${correspondenceId}&limit=50`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(corrRes.status).toBe(200);
    const corrActions = corrRes.body.data.map((e: any) => e.action);
    for (const expected of ['CREATE', 'REFER', 'SEND']) {
      expect(corrActions).toContain(expected);
    }
    // حدث الإرسال موسوم بالمستخدم وIP
    const sendEvent = corrRes.body.data.find((e: any) => e.action === 'SEND');
    expect(sendEvent.user.email).toBe('gm@al-fadaa.com');
    expect(sendEvent.summary).toContain(outgoingRef);

    // أحداث التكليف (كيان Task)
    const taskRes = await request(httpServer)
      .get(`/api/v1/audit?entityType=Task&entityId=${taskId}&limit=50`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(taskRes.status).toBe(200);
    const taskActions = taskRes.body.data.map((e: any) => e.action);
    expect(taskActions).toContain('ASSIGN');

    // أحداث الرد (كيان Reply): إنشاء ← رفع ← اعتماد
    const replyRes = await request(httpServer)
      .get(`/api/v1/audit?entityType=Reply&entityId=${replyId}&limit=50`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(replyRes.status).toBe(200);
    const replyActions = replyRes.body.data.map((e: any) => e.action);
    for (const expected of ['CREATE', 'SUBMIT', 'APPROVE']) {
      expect(replyActions).toContain(expected);
    }
  });

  it('الموظف ممنوع من سجل التدقيق (403) — والمسؤول يرى أحداث الدخول', async () => {
    const forbidden = await request(httpServer)
      .get('/api/v1/audit')
      .set('Authorization', `Bearer ${employeeToken}`);
    expect(forbidden.status).toBe(403);

    const res = await request(httpServer)
      .get('/api/v1/audit?action=LOGIN&limit=5')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it('تنزيل المرفق يعمل (200) — ولا يُحذف بعد الإرسال (400)', async () => {
    const download = await request(httpServer)
      .get(`/api/v1/attachments/${attachmentId}/download`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(download.status).toBe(200);

    const remove = await request(httpServer)
      .delete(`/api/v1/attachments/${attachmentId}`)
      .set('Authorization', `Bearer ${gmToken}`);
    expect(remove.status).toBe(400); // مراسلة منتهية — المرفق محفوظ للأرشيف
  });

  it('المدير العام يؤرشف المراسلة — نهاية الدورة', async () => {
    const res = await request(httpServer)
      .post(`/api/v1/correspondences/${correspondenceId}/archive`)
      .set('Authorization', `Bearer ${gmToken}`)
      .send({});
    expect(res.status).toBe(201);
    expect(res.body.status).toBe('ARCHIVED');
  });
});
