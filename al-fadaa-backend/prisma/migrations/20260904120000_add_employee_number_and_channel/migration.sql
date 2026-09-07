-- AlterTable: إضافة الرقم الوظيفي للمستخدمين وقناة الوصول للمراسلات
-- وفق مخطط قاعدة البيانات المعتمد (المخطط 3 من 4)

-- إضافة عمود الرقم الوظيفي للمستخدمين (اختياري، فريد)
ALTER TABLE "User" ADD COLUMN "employeeNumber" TEXT;
CREATE UNIQUE INDEX "User_employeeNumber_key" ON "User"("employeeNumber");

-- إضافة عمود قناة الوصول للمراسلات (اختياري)
-- القيم المتوقعة: email | website | fax | hand
ALTER TABLE "Correspondence" ADD COLUMN "channel" TEXT;
