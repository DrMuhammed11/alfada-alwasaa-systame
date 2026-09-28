-- إضافة أعمدة سلسلة الهاش لسجل التدقيق (الضمان ضد التلاعب):
--   previousHash : بصمة السجل السابق لربط السلسلة
--   recordHash   : بصمة SHA-256 الفريدة لهذا السجل
-- الحقلان كانا في schema.prisma واستخدامهما في audit.service.ts دون ترحيل —
-- فتفشل كل كتابة تدقيق على أي قاعدة بنيت من الترحيلات (وإضافة /audit كانت 500).
-- صيغة idempotent عمداً: قواعد حصلت على الأعمدة تاريخياً عبر prisma db push
-- (مثل قاعدة التطوير الرئيسية) تتجاوز التنفيذ بأمان ويسجل الترحيل في تاريخها.
-- المرجع: prisma/migrations/20260928224240_add_audit_hash_chain

-- AlterTable
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "previousHash" TEXT;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "recordHash" TEXT;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "AuditLog_recordHash_idx" ON "AuditLog"("recordHash");
