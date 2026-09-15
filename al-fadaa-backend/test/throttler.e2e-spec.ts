import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

/**
 * اختبارات e2e لتحديد معدل الطلبات (Rate Limiting) —
 * تثبت إرجاع رمز الحالة 429 Too Many Requests عند تجاوز الحد المسموح.
 */
describe('Rate Limiting Throttler (e2e)', () => {
  let app: INestApplication;
  let httpServer: any;

  beforeAll(async () => {
    // ضبط حد مخفض للاختبار
    process.env.THROTTLE_LOGIN_LIMIT = '3';
    process.env.THROTTLE_LOGIN_TTL = '60';

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

  it('يُرجع 429 Too Many Requests عند تجاوز حد محاولات تسجيل الدخول', async () => {
    const invalidCredentials = {
      email: 'brute-force@al-fadaa.com',
      password: 'WrongPassword123',
    };

    // المحاولة 1: تفشل بـ 401 (غير مصرح)
    const res1 = await request(httpServer)
      .post('/api/v1/auth/login')
      .send(invalidCredentials);
    expect(res1.status).toBe(401);

    // المحاولة 2: تفشل بـ 401
    const res2 = await request(httpServer)
      .post('/api/v1/auth/login')
      .send(invalidCredentials);
    expect(res2.status).toBe(401);

    // المحاولة 3: تفشل بـ 401 (الحد الأقصى المسموح هو 3)
    const res3 = await request(httpServer)
      .post('/api/v1/auth/login')
      .send(invalidCredentials);
    expect(res3.status).toBe(401);

    // المحاولة 4: تم تجاوز الحد المسموح → يجب إرجاع 429
    const res4 = await request(httpServer)
      .post('/api/v1/auth/login')
      .send(invalidCredentials);
    expect(res4.status).toBe(429);
    expect(res4.body.message).toContain('429');
  });
});
