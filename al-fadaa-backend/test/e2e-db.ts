import 'dotenv/config';
import { Client } from 'pg';
import { execSync } from 'node:child_process';

/**
 * أدوات قاعدة بيانات الاختبار (e2e):
 * قاعدة منفصلة اسمها alfadaa_test مشتقة من DATABASE_URL نفسه
 * (نفس المنفذ والمستخدم) حتى تعمل محليًا وفي CI دون أي إعداد إضافي.
 */
export function deriveTestDbUrl(): string {
  // نتجاهل أي DATABASE_URL لا يشير إلى PostgreSQL (قد يكون مضبوطًا مسبقًا في البيئة)
  const fromEnv =
    process.env.E2E_DATABASE_URL ??
    (process.env.DATABASE_URL?.startsWith('postgres')
      ? process.env.DATABASE_URL
      : undefined);
  const base =
    fromEnv ??
    'postgresql://alfadaa:alfadaa@localhost:5432/alfadaa_correspondence?schema=public';
  // استبدال اسم قاعدة البيانات الأخير بـ alfadaa_test
  return base.replace(/\/[^/?]+(\?|$)/, '/alfadaa_test$1');
}

/** إنشاء قاعدة الاختبار إن لم تكن موجودة */
export async function ensureTestDatabase(): Promise<string> {
  const testUrl = deriveTestDbUrl();
  const adminUrl = testUrl.replace(/\/[^/?]+(\?|$)/, '/postgres$1');
  const client = new Client({ connectionString: adminUrl });
  await client.connect();
  const dbName = new URL(testUrl).pathname.slice(1);
  const res = await client.query('SELECT 1 FROM pg_database WHERE datname = $1', [
    dbName,
  ]);
  if ((res.rowCount ?? 0) === 0) {
    await client.query(`CREATE DATABASE "${dbName}"`);
  }
  await client.end();
  return testUrl;
}

/** إعادة بناء قاعدة الاختبار من الصفر: المخطط + الترحيلات + البيانات الأولية */
export async function resetTestDatabase(): Promise<void> {
  const testUrl = await ensureTestDatabase();
  execSync('npx prisma migrate reset --force', {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: testUrl },
  });
}
