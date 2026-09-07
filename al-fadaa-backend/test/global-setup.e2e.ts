/**
 * إعداد عالمي لاختبارات e2e — يُنفَّذ مرة واحدة قبل كل شيء:
 * إنشاء قاعدة بيانات الاختبار إن لزم، ثم إعادة بنائها
 * (الترحيلات + Trigger منع تعديل سجل التدقيق + البيانات الأولية).
 */
import { resetTestDatabase } from './e2e-db';

export default async function globalSetup(): Promise<void> {
  console.log('── إعداد قاعدة بيانات الاختبار (alfadaa_test) ──');
  await resetTestDatabase();
  console.log('── قاعدة بيانات الاختبار جاهزة ──');
}
