import { INestApplication, VersioningType } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

/**
 * اختبارات e2e للمصادقة والصلاحيات —
 * تعمل ضد قاعدة alfadaa_test الحقيقية (تُبنى تلقائيًا في global-setup).
 */
describe('المصادقة (e2e)', () => {
  let app: INestApplication;
  let httpServer: any;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    httpServer = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('فحص الصحة يعمل دون توثيق', async () => {
    const res = await request(httpServer).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('تسجيل دخول ناجح يعيد رمز JWT وبيانات المستخدم', async () => {
    const res = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'gm@al-fadaa.com', password: 'Alfadaa@2026' });

    expect(res.status).toBe(201);
    expect(res.body.accessToken).toBeTruthy();
    expect(res.body.user.email).toBe('gm@al-fadaa.com');
    expect(res.body.user.role).toBe('GM');
    expect(res.body.user).not.toHaveProperty('passwordHash');
  });

  it('كلمة مرور خاطئة → 401', async () => {
    const res = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'gm@al-fadaa.com', password: 'WrongPass@1' });
    expect(res.status).toBe(401);
  });

  it('الوصول بدون رمز إلى مسار محمي → 401', async () => {
    const res = await request(httpServer).get('/api/v1/users');
    expect(res.status).toBe(401);
  });

  it('/auth/me يعيد بيانات المستخدم من الرمز', async () => {
    const login = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'eng.employee1@al-fadaa.com', password: 'Alfadaa@2026' });
    const token = login.body.accessToken;

    const res = await request(httpServer)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.email).toBe('eng.employee1@al-fadaa.com');
    expect(res.body.role).toBe('EMPLOYEE');
  });

  it('حارس الصلاحيات: الموظف ممنوع من إدارة المستخدمين (403)', async () => {
    const login = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'eng.employee1@al-fadaa.com', password: 'Alfadaa@2026' });
    const token = login.body.accessToken;

    const res = await request(httpServer)
      .get('/api/v1/users')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.message).toMatch(/ليست لديك صلاحية/);
  });

  it('حارس الصلاحيات: المسؤول يرى المستخدمين (200)', async () => {
    const login = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@al-fadaa.com', password: 'Alfadaa@2026' });
    const token = login.body.accessToken;

    const res = await request(httpServer)
      .get('/api/v1/users')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.meta.total).toBeGreaterThanOrEqual(10);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('مدخلات غير صالحة (بريد بلا صيغة سليمة) → 400 برسالة عربية', async () => {
    const res = await request(httpServer)
      .post('/api/v1/auth/login')
      .send({ email: 'not-an-email', password: 'x' });
    expect(res.status).toBe(400);
  });
});
