/**
 * يُنفَّذ في كل عامل Jest قبل تحميل أي ملف اختبار —
 * يوجه التطبيق إلى قاعدة بيانات الاختبار (وليس قاعدة التطوير!).
 */
import { deriveTestDbUrl } from './e2e-db';

process.env.NODE_ENV = process.env.NODE_ENV ?? 'test';
process.env.DATABASE_URL = deriveTestDbUrl();
// إجبارية وليست افتراضية — MAIL_DRIVER=smtp في بيئة النظام كان سيجعل e2e
// تحاول الإرسال عبر SMTP حقيقي بدل الطباعة في الطرفية
process.env.MAIL_DRIVER = 'console';
// رفع حد محاولات الدخول في الأجنحة الوظيفية — جناح المصادقة وحده يجري 6 طلبات
// دخول خلال ثوانٍ والحد الافتراضي 5 يقيّده بـ 429. اختبار المحدد يضبط حده
// المنخفض بنفسه في beforeAll (THROTTLE_LOGIN_LIMIT=3) فلا يتأثر اختبار 429
process.env.THROTTLE_LOGIN_LIMIT = '100';
process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'e2e-test-secret';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '12h';
process.env.JWT_ISSUER = process.env.JWT_ISSUER ?? 'alfadaa-api';
process.env.JWT_AUDIENCE = process.env.JWT_AUDIENCE ?? 'alfadaa-app';
process.env.IMAP_HOST = '';
process.env.UPLOAD_DIR = process.env.UPLOAD_DIR ?? './uploads-e2e';
