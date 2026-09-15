/**
 * يُنفَّذ في كل عامل Jest قبل تحميل أي ملف اختبار —
 * يوجه التطبيق إلى قاعدة بيانات الاختبار (وليس قاعدة التطوير!).
 */
import { deriveTestDbUrl } from './e2e-db';

process.env.NODE_ENV = process.env.NODE_ENV ?? 'test';
process.env.DATABASE_URL = deriveTestDbUrl();
process.env.MAIL_DRIVER = process.env.MAIL_DRIVER ?? 'console';
process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'e2e-test-secret';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '12h';
process.env.JWT_ISSUER = process.env.JWT_ISSUER ?? 'alfadaa-api';
process.env.JWT_AUDIENCE = process.env.JWT_AUDIENCE ?? 'alfadaa-app';
process.env.IMAP_HOST = '';
process.env.UPLOAD_DIR = process.env.UPLOAD_DIR ?? './uploads-e2e';
