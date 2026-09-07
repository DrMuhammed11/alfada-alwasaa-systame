// ═══════════════════════════════════════════════════════════════════
//  البيانات الأولية (Seed) — تُنفَّذ تلقائيًا مع:
//  npx prisma db seed   أو   npm run db:reset
// ═══════════════════════════════════════════════════════════════════

import {
  PrismaClient,
  Role,
  Priority,
  CorrespondenceType,
  CorrespondenceStatus,
  ReferralStatus,
  TaskStatus,
  ReplyStatus,
  AuditAction,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

/** كلمة المرور الموحدة لجميع الحسابات التجريبية (للتطوير فقط — غيّرها في الإنتاج) */
const DEV_PASSWORD = 'Alfadaa@2026';

async function main() {
  const passwordHash = await bcrypt.hash(DEV_PASSWORD, 10);
  const year = new Date().getFullYear();
  const hoursAgo = (h: number) => new Date(Date.now() - h * 60 * 60 * 1000);

  // ─── 1) الأقسام ───
  const departmentDefs = [
    { code: 'GEN', name: 'الإدارة العامة' },
    { code: 'ENG', name: 'القسم الهندسي' },
    { code: 'FIN', name: 'القسم المالي' },
    { code: 'HR', name: 'الموارد البشرية' },
    { code: 'IT', name: 'قسم تقنية المعلومات' },
    { code: 'REC', name: 'قسم الاستقبال والاستعلامات' },
    { code: 'CS', name: 'قسم خدمة العملاء والردود' },
  ];
  const dept: Record<string, string> = {};
  for (const d of departmentDefs) {
    const row = await prisma.department.upsert({
      where: { code: d.code },
      update: { name: d.name },
      create: d,
    });
    dept[d.code] = row.id;
  }

  // ─── 2) المستخدمون (حساب لكل دور) ───
  const userDefs = [
    { key: 'admin',     name: 'مسؤول النظام',          email: 'admin@al-fadaa.com',          role: 'ADMIN' as Role,        dept: 'GEN', jobTitle: 'مسؤول النظام' },
    { key: 'gm',        name: 'المدير العام',           email: 'gm@al-fadaa.com',             role: 'GM' as Role,           dept: 'GEN', jobTitle: 'المدير العام' },
    { key: 'deputy',    name: 'نائب المدير العام',      email: 'deputy@al-fadaa.com',         role: 'DEPUTY_GM' as Role,    dept: 'GEN', jobTitle: 'نائب المدير العام' },
    { key: 'engMgr',    name: 'مدير القسم الهندسي',     email: 'eng.manager@al-fadaa.com',    role: 'DEPT_MANAGER' as Role, dept: 'ENG', jobTitle: 'مدير القسم الهندسي' },
    { key: 'finMgr',    name: 'مدير القسم المالي',      email: 'fin.manager@al-fadaa.com',    role: 'DEPT_MANAGER' as Role, dept: 'FIN', jobTitle: 'مدير القسم المالي' },
    { key: 'hrMgr',     name: 'مدير الموارد البشرية',   email: 'hr.manager@al-fadaa.com',     role: 'DEPT_MANAGER' as Role, dept: 'HR', jobTitle: 'مدير الموارد البشرية' },
    { key: 'itMgr',     name: 'مدير تقنية المعلومات',   email: 'it.manager@al-fadaa.com',     role: 'DEPT_MANAGER' as Role, dept: 'IT', jobTitle: 'مدير تقنية المعلومات' },
    { key: 'csMgr',     name: 'مدير خدمة العملاء',      email: 'cs.manager@al-fadaa.com',     role: 'DEPT_MANAGER' as Role, dept: 'CS', jobTitle: 'مدير خدمة العملاء' },
    { key: 'engEmp1',   name: 'المهندس أحمد',           email: 'eng.employee1@al-fadaa.com',  role: 'EMPLOYEE' as Role,     dept: 'ENG', jobTitle: 'مهندس' },
    { key: 'engEmp2',   name: 'المهندسة سارة',          email: 'eng.employee2@al-fadaa.com',  role: 'EMPLOYEE' as Role,     dept: 'ENG', jobTitle: 'مهندسة' },
    { key: 'finEmp1',   name: 'المحاسب خالد',           email: 'fin.employee1@al-fadaa.com',  role: 'EMPLOYEE' as Role,     dept: 'FIN', jobTitle: 'محاسب' },
    { key: 'recEmp',    name: 'مستقبل المعاملات (علي)', email: 'reception@al-fadaa.com',      role: 'EMPLOYEE' as Role,     dept: 'REC', jobTitle: 'مستقبل الاستقبال' },
    { key: 'csEmp1',    name: 'ممثلة خدمة العملاء (فاطمة)', email: 'cs.employee1@al-fadaa.com', role: 'EMPLOYEE' as Role,   dept: 'CS', jobTitle: 'ممثلة خدمة العملاء' },
  ];
  const u: Record<string, { id: string; name: string }> = {};
  for (const x of userDefs) {
    const row = await prisma.user.upsert({
      where: { email: x.email },
      update: { name: x.name, role: x.role, departmentId: dept[x.dept], isActive: true },
      create: {
        name: x.name,
        email: x.email,
        passwordHash,
        role: x.role,
        departmentId: dept[x.dept],
        jobTitle: x.jobTitle,
      },
    });
    u[x.key] = { id: row.id, name: row.name };
  }

  // ربط مدير كل قسم
  const managerOf: Record<string, string> = { ENG: 'engMgr', FIN: 'finMgr', HR: 'hrMgr', IT: 'itMgr' };
  for (const [code, key] of Object.entries(managerOf)) {
    await prisma.department.update({ where: { code }, data: { managerId: u[key].id } });
  }

  // ─── مستخدم نظامي (محرك البريد) — حساب معطّل للإسناد الآلي ───
  await prisma.user.upsert({
    where: { email: 'mail-engine@al-fadaa.internal' },
    update: {},
    create: {
      name: 'محرك البريد',
      email: 'mail-engine@al-fadaa.internal',
      passwordHash: await bcrypt.hash('DISABLED-SYSTEM-ACCOUNT', 10),
      role: 'EMPLOYEE' as Role,
      isActive: false,
      jobTitle: 'حساب نظامي — محرك سحب البريد الآلي',
    },
  });
  console.log('  ✓ تم إنشاء/تأكيد حساب محرك البريد النظامي (mail-engine@al-fadaa.internal)');

  // ─── 3) بيانات نموذجية (تُنشأ مرة واحدة فقط على قاعدة نظيفة) ───
  if ((await prisma.correspondence.count()) === 0) {
    // مراسلة واردة #1: وصلت للتو — بانتظار دراسة المدير العام
    const c1 = await prisma.correspondence.create({
      data: {
        refNumber: `INC-${year}-00001`,
        type: CorrespondenceType.INCOMING,
        subject: 'طلب عرض سعر لتنفيذ أعمال العزل المائي',
        body: 'تحية طيبة،\n\nنرغب في الحصول على عرض سعر لتنفيذ أعمال العزل المائي لمشروعنا في منطقة العبدلي، على أن يشمل العرض الكميات والمدة الزمنية للتنفيذ.\n\nوتفضلوا بقبول فائق الاحترام،',
        priority: Priority.HIGH,
        status: CorrespondenceStatus.RECEIVED,
        senderName: 'شركة الأفق للمقاولات',
        senderEmail: 'info@ofoq-contracting.com',
        receivedAt: hoursAgo(26),
        createdById: u.admin.id,
      },
    });

    // مراسلة واردة #2: محالة للقسم الهندسي + تكليف موظف + مسودة رد قيد الإعداد
    const c2 = await prisma.correspondence.create({
      data: {
        refNumber: `INC-${year}-00002`,
        type: CorrespondenceType.INCOMING,
        subject: 'استفسار عن موعد تسليم المخططات التنفيذية',
        body: 'تحية طيبة،\n\nنرجو التكرم بإفادتنا بالموعد المتوقع لتسليم المخططات التنفيذية لمشروع برج الفضاء، وذلك لتنظيم جدول أعمال المقاول من الباطن.\n\nشاكرين لكم حسن تعاونكم،',
        priority: Priority.NORMAL,
        status: CorrespondenceStatus.IN_PROGRESS,
        senderName: 'مؤسسة النور التجارية',
        senderEmail: 'projects@alnoor-trade.com',
        receivedAt: hoursAgo(50),
        createdById: u.admin.id,
        departmentId: dept.ENG,
      },
    });

    const ref2 = await prisma.referral.create({
      data: {
        correspondenceId: c2.id,
        fromUserId: u.gm.id,
        toUserId: u.engMgr.id,
        note: 'للدراسة وإعداد الرد خلال يومي عمل',
        status: ReferralStatus.OPEN,
        dueDate: new Date(Date.now() + 48 * 60 * 60 * 1000),
        createdAt: hoursAgo(48),
      },
    });

    const task2 = await prisma.task.create({
      data: {
        correspondenceId: c2.id,
        referralId: ref2.id,
        title: 'إعداد رد بخصوص موعد تسليم المخططات',
        description: 'التنسيق مع فريق التصميم وتحديد الموعد النهائي للتسليم',
        assignedById: u.engMgr.id,
        assignedToId: u.engEmp1.id,
        dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        status: TaskStatus.IN_PROGRESS,
        createdAt: hoursAgo(40),
      },
    });

    await prisma.reply.create({
      data: {
        correspondenceId: c2.id,
        taskId: task2.id,
        authorId: u.engEmp1.id,
        body: 'يسرّنا إفادتكم بأن المخططات التنفيذية لمشروع برج الفضاء ستكون جاهزة للتسليم خلال عشرة أيام عمل من تاريخه، وسنوافيكم بأي مستجدات أولاً بأول.\n\nوتفضلوا بقبول فائق الاحترام،',
        status: ReplyStatus.DRAFT,
        createdAt: hoursAgo(2),
      },
    });

    // عدّاد الأرقام المرجعية: أصبح لدينا مراسلتان واردتان
    await prisma.counter.upsert({
      where: { key: `INC-${year}` },
      update: { value: 2 },
      create: { key: `INC-${year}`, value: 2 },
    });

    // سجل تدقيق واقعي للمراسلة الثانية
    await prisma.auditLog.createMany({
      data: [
        {
          userId: u.admin.id,
          action: AuditAction.CREATE,
          entityType: 'Correspondence',
          entityId: c2.id,
          summary: `تم تسجيل مراسلة واردة برقم INC-${year}-00002 من مؤسسة النور التجارية`,
          createdAt: hoursAgo(49),
        },
        {
          userId: u.gm.id,
          action: AuditAction.REFER,
          entityType: 'Correspondence',
          entityId: c2.id,
          summary: `أحال المدير العام المراسلة INC-${year}-00002 إلى مدير القسم الهندسي`,
          metadata: { note: 'للدراسة وإعداد الرد خلال يومي عمل' },
          createdAt: hoursAgo(48),
        },
        {
          userId: u.engMgr.id,
          action: AuditAction.ASSIGN,
          entityType: 'Correspondence',
          entityId: c2.id,
          summary: `كلّف مدير القسم الهندسي الموظف ${u.engEmp1.name} بإعداد رد على المراسلة INC-${year}-00002`,
          createdAt: hoursAgo(40),
        },
      ],
    });

    console.log(`تم إنشاء بيانات نموذجية: ${c1.refNumber} (بانتظار الدراسة) و ${c2.refNumber} (محالة + تكليف + مسودة رد)`);
  }

  console.log('\n✅ اكتملت تهيئة البيانات الأولية\n');
  console.log('الحسابات التجريبية (كلمة المرور للجميع: %s):\n', DEV_PASSWORD);
  for (const x of userDefs) {
    console.log(`  ${x.role.padEnd(13)} | ${x.email.padEnd(32)} | ${x.name}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
