-- إضافة حقل بصمة SHA-256 للمرفقات وقيمة DOWNLOAD لسجل التدقيق

-- إضافة حقل sha256 لجدول المرفقات
ALTER TABLE "Attachment" ADD COLUMN IF NOT EXISTS "sha256" TEXT;

-- إضافة قيمة DOWNLOAD لنوع AuditAction (إن لم تكن موجودة)
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'DOWNLOAD';
