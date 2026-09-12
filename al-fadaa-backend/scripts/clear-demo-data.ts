/**
 * سكربت تنظيف وحذف كافة البيانات التجريبية من قاعدة البيانات
 * مع الإبقاء الكامل على المستخدمين والأقسام والإعدادات الإدارية.
 *
 * تشغيل:
 *   npx ts-node scripts/clear-demo-data.ts
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🧹 بدء تنظيف وحذف البيانات التجريبية...');

  try {
    // 1. حذف المراسلات الصادرة في صندوق البريد
    const outboxMails = await prisma.outboxMail.deleteMany();
    console.log(`  ✓ تم حذف سجلات OutboxMail: ${outboxMails.count}`);

    // 2. حذف أحداث صندوق الخروج المعاملاتي
    const events = await prisma.eventOutbox.deleteMany();
    console.log(`  ✓ تم حذف سجلات EventOutbox: ${events.count}`);

    // 3. حذف حالات اتفاقيات مستوى الخدمة
    const sla = await prisma.slaState.deleteMany();
    console.log(`  ✓ تم حذف سجلات SlaState: ${sla.count}`);

    // 4. حذف خطوات مسارات الاعتماد
    const approvalSteps = await prisma.approvalStep.deleteMany();
    console.log(`  ✓ تم حذف سجلات ApprovalStep: ${approvalSteps.count}`);

    // 5. حذف إصدارات الردود
    const replyVersions = await prisma.replyVersion.deleteMany();
    console.log(`  ✓ تم حذف سجلات ReplyVersion: ${replyVersions.count}`);

    // 6. حذف المرفقات
    const attachments = await prisma.attachment.deleteMany();
    console.log(`  ✓ تم حذف سجلات Attachment: ${attachments.count}`);

    // 7. حذف الردود
    const replies = await prisma.reply.deleteMany();
    console.log(`  ✓ تم حذف سجلات Reply: ${replies.count}`);

    // 8. حذف التكليفات
    const tasks = await prisma.task.deleteMany();
    console.log(`  ✓ تم حذف سجلات Task: ${tasks.count}`);

    // 9. حذف الإحالات
    const referrals = await prisma.referral.deleteMany();
    console.log(`  ✓ تم حذف سجلات Referral: ${referrals.count}`);

    // 10. حذف المراسلات التابعة أولاً ثم الجذرية
    const childCorrs = await prisma.correspondence.deleteMany({
      where: { parentId: { not: null } },
    });
    console.log(`  ✓ تم حذف المراسلات التابعة (Children): ${childCorrs.count}`);

    const rootCorrs = await prisma.correspondence.deleteMany();
    console.log(`  ✓ تم حذف المراسلات الجذرية (Roots): ${rootCorrs.count}`);

    // 11. حذف الإشعارات القديمة
    const notifications = await prisma.notification.deleteMany();
    console.log(`  ✓ تم حذف الإشعارات: ${notifications.count}`);

    // 12. تصفير العدادات الترقيمية لتبدأ المراسلات الجديدة من 00001
    const counters = await prisma.counter.deleteMany();
    console.log(`  ✓ تم تصفير عدادات الترقيم: ${counters.count}`);

    // 13. تصفير علامات ماء سحب البريد
    const hwm = await prisma.imapHighWaterMark.deleteMany();
    console.log(`  ✓ تم تصفير علامة ماء البريد: ${hwm.count}`);

    // 14. محاولة تنظيف سجل التدقيق إن أمكن
    try {
      await prisma.$executeRawUnsafe('TRUNCATE TABLE "AuditLog" CASCADE;');
      console.log('  ✓ تم تفريغ سجل التدقيق AuditLog بنجاح');
    } catch (auditErr) {
      console.log('  ℹ️ تم الحفاظ على سجل التدقيق (محمي بحكم النظام والتريجر)');
    }

    const remainingUsers = await prisma.user.count();
    const remainingDepts = await prisma.department.count();

    console.log('\n========================================');
    console.log('✅ اكتمل تنظيف البيانات التجريبية بنجاح!');
    console.log(`👥 المستخدمون المتاحون لتسجيل الدخول: ${remainingUsers}`);
    console.log(`🏢 الأقسام الإدارية النشطة: ${remainingDepts}`);
    console.log('========================================\n');
  } catch (err) {
    console.error('❌ خطأ أثناء تنظيف البيانات:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
