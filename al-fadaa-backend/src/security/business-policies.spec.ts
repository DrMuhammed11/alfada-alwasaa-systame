import {
  CorrespondenceStatus,
  CorrespondenceType,
  ReplyStatus,
  Role,
} from '@prisma/client';
import {
  canRefer,
  canAssignTask,
  canApproveReply,
  canSendReply,
  canCloseCorrespondence,
  canArchiveCorrespondence,
} from './business-policies';

describe('BusinessPolicies Decision Table & Rules', () => {
  const dept1 = 'dept-eng-001';
  const dept2 = 'dept-sales-002';

  const gm = { id: 'u-gm', role: Role.GM, name: 'المدير العام', isActive: true };
  const admin = { id: 'u-admin', role: Role.ADMIN, name: 'مدير النظام', isActive: true };
  const deputyGm = { id: 'u-deputy', role: Role.DEPUTY_GM, name: 'نائب المدير', isActive: true };
  const deptManager1 = {
    id: 'u-mgr-1',
    role: Role.DEPT_MANAGER,
    name: 'مدير الهندسة',
    departmentId: dept1,
    isActive: true,
  };
  const deptManager2 = {
    id: 'u-mgr-2',
    role: Role.DEPT_MANAGER,
    name: 'مدير المبيعات',
    departmentId: dept2,
    isActive: true,
  };
  const employee1 = {
    id: 'u-emp-1',
    role: Role.EMPLOYEE,
    name: 'مهندس 1',
    departmentId: dept1,
    isActive: true,
  };
  const employee2 = {
    id: 'u-emp-2',
    role: Role.EMPLOYEE,
    name: 'مندوب 2',
    departmentId: dept2,
    isActive: true,
  };

  const sampleCorr = {
    id: 'corr-1',
    status: CorrespondenceStatus.RECEIVED,
    type: CorrespondenceType.INCOMING,
    departmentId: dept1,
    senderEmail: 'client@example.com',
  };

  describe('1. سياسة الإحالة (canRefer)', () => {
    it('يمنع الإحالة لمستخدم غير متوفر أو غير نشط', () => {
      const res = canRefer(gm, null);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('المستخدم المحال إليه غير متوفر');

      const inactiveTarget = { ...employee1, isActive: false };
      const resInactive = canRefer(gm, inactiveTarget);
      expect(resInactive.allowed).toBe(false);
      expect(resInactive.reason).toBe('المستخدم المحال إليه غير متوفر');
    });

    it('يمنع الإحالة للنفس مطلقاً', () => {
      const res = canRefer(gm, gm);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('لا يمكن إحالة المراسلة إلى نفسك');
    });

    it('المدير العام: يسمح له بالإحالة للنائب ولمديري الأقسام ويمنع الإحالة للموظفين العاديين', () => {
      expect(canRefer(gm, deputyGm).allowed).toBe(true);
      expect(canRefer(gm, deptManager1).allowed).toBe(true);

      const toEmp = canRefer(gm, employee1);
      expect(toEmp.allowed).toBe(false);
      expect(toEmp.reason).toContain('بصفتك (المدير العام)');
      expect(toEmp.reason).toContain('نائب المدير العام / مدير قسم');
    });

    it('نائب المدير العام: يسمح له بالإحالة لمديري الأقسام فقط', () => {
      expect(canRefer(deputyGm, deptManager1).allowed).toBe(true);

      const toEmp = canRefer(deputyGm, employee1);
      expect(toEmp.allowed).toBe(false);
      expect(toEmp.reason).toContain('نائب المدير العام');
      expect(toEmp.reason).toContain('مدير قسم');
    });

    it('مدير القسم: يسمح له بالإحالة لموظفي قسمه فقط ويمنع لموظفي قسم آخر', () => {
      expect(canRefer(deptManager1, employee1).allowed).toBe(true);

      const toOtherDeptEmp = canRefer(deptManager1, employee2);
      expect(toOtherDeptEmp.allowed).toBe(false);
      expect(toOtherDeptEmp.reason).toBe('بصفتك مدير قسم يمكنك الإحالة لموظفي قسمك فقط');

      const toAnotherMgr = canRefer(deptManager1, deptManager2);
      expect(toAnotherMgr.allowed).toBe(false);
      expect(toAnotherMgr.reason).toContain('موظف');
    });

    it('الموظف ومدير النظام: ليس لديهما صلاحية الإحالة', () => {
      const empRes = canRefer(employee1, employee2);
      expect(empRes.allowed).toBe(false);
      expect(empRes.reason).toBe('ليس لديك صلاحية إحالة المراسلات');

      const adminRes = canRefer(admin, deptManager1);
      expect(adminRes.allowed).toBe(false);
      expect(adminRes.reason).toBe('ليس لديك صلاحية إحالة المراسلات');
    });
  });

  describe('2. سياسة التكليف (canAssignTask)', () => {
    it('يمنع إنشاء تكليف على مراسلة مغلقة أو مؤرشفة', () => {
      const closedCorr = { ...sampleCorr, status: CorrespondenceStatus.CLOSED };
      expect(canAssignTask(deptManager1, employee1, closedCorr).allowed).toBe(false);
      expect(canAssignTask(deptManager1, employee1, closedCorr).reason).toBe(
        'لا يمكن إنشاء تكليف على مراسلة مغلقة أو مؤرشفة',
      );

      const archivedCorr = { ...sampleCorr, status: CorrespondenceStatus.ARCHIVED };
      expect(canAssignTask(deptManager1, employee1, archivedCorr).allowed).toBe(false);
    });

    it('يمنع التكليف إذا كان الموظف غير متوفر أو غير نشط', () => {
      expect(canAssignTask(gm, null).allowed).toBe(false);
      expect(canAssignTask(gm, null).reason).toBe('الموظف المكلَّف غير متوفر أو غير نشط');
    });

    it('يمنع الموظف من تكليف غيره', () => {
      const res = canAssignTask(employee1, employee2);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('ليس لديك صلاحية تكليف الموظفين');
    });

    it('مدير القسم يكلف موظفي قسمه فقط', () => {
      expect(canAssignTask(deptManager1, employee1).allowed).toBe(true);

      const crossDept = canAssignTask(deptManager1, employee2);
      expect(crossDept.allowed).toBe(false);
      expect(crossDept.reason).toBe('بصفتك مدير قسم يمكنك تكليف موظفي قسمك فقط');

      const nonEmp = canAssignTask(deptManager1, deptManager2);
      expect(nonEmp.allowed).toBe(false);
      expect(nonEmp.reason).toBe('مدير القسم يكلّف موظفي قسمه فقط');
    });

    it('المدير العام والنائب يمكنهما تكليف أي موظف نشط', () => {
      expect(canAssignTask(gm, employee1).allowed).toBe(true);
      expect(canAssignTask(deputyGm, employee2).allowed).toBe(true);
    });
  });

  describe('3. سياسة اعتماد الرد (canApproveReply)', () => {
    const submittedReply = {
      id: 'rep-1',
      authorId: employee1.id,
      status: ReplyStatus.SUBMITTED,
    };

    it('يمنع الاعتماد إذا كان الرد غير مرفوع للاعتماد (مثلاً DRAFT)', () => {
      const draftReply = { ...submittedReply, status: ReplyStatus.DRAFT };
      const res = canApproveReply(deptManager1, draftReply, sampleCorr);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('الرد غير مرفوع للاعتماد');
    });

    it('يمنع المستخدم من اعتماد رد أعده بنفسه (فصل الاختصاص)', () => {
      const myReply = { ...submittedReply, authorId: deptManager1.id };
      const res = canApproveReply(deptManager1, myReply, sampleCorr);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('لا يمكنك اعتماد أو رفض رد أعددته بنفسك');
    });

    it('يمنع الموظف من اعتماد الردود', () => {
      const res = canApproveReply(employee2, submittedReply, sampleCorr);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('ليس لديك صلاحية اعتماد الردود');
    });

    it('مدير القسم: يسمح له بالاعتماد لمراسلات قسمه أو المحالة إليه فقط', () => {
      // مراسلة لقسمه (dept1)
      expect(canApproveReply(deptManager1, submittedReply, sampleCorr).allowed).toBe(true);

      // مراسلة لقسم آخر بدون إحالة
      const otherDeptCorr = { ...sampleCorr, departmentId: dept2 };
      const denied = canApproveReply(deptManager1, submittedReply, otherDeptCorr, []);
      expect(denied.allowed).toBe(false);
      expect(denied.reason).toBe('يمكنك اعتماد ردود مراسلات قسمك أو المحالة إليك فقط');

      // مراسلة لقسم آخر لكن محالة إليه
      const openRef = [{ fromUserId: 'u-gm', toUserId: deptManager1.id }];
      const approvedWithRef = canApproveReply(deptManager1, submittedReply, otherDeptCorr, openRef);
      expect(approvedWithRef.allowed).toBe(true);
    });

    it('المدير العام ومدير النظام: يسمح لهما بالاعتماد', () => {
      expect(canApproveReply(gm, submittedReply, sampleCorr).allowed).toBe(true);
      expect(canApproveReply(admin, submittedReply, sampleCorr).allowed).toBe(true);
    });
  });

  describe('4. سياسة الإرسال النهائي للعميل (canSendReply)', () => {
    const approvedReply = {
      id: 'rep-1',
      authorId: employee1.id,
      status: ReplyStatus.APPROVED,
      sentAt: null,
    };

    it('يحصر الإرسال النهائي بالإدارة العليا', () => {
      const empRes = canSendReply(employee1, approvedReply, sampleCorr);
      expect(empRes.allowed).toBe(false);
      expect(empRes.reason).toBe('صلاحية الإرسال النهائي للعملاء محصورة بالإدارة العليا');

      const mgrRes = canSendReply(deptManager1, approvedReply, sampleCorr);
      expect(mgrRes.allowed).toBe(false);
      expect(mgrRes.reason).toBe('صلاحية الإرسال النهائي للعملاء محصورة بالإدارة العليا');
    });

    it('يمنع إرسال رد غير معتمد (إلا استثناء للمدير العام كإرسال مباشر)', () => {
      const unapproved = { ...approvedReply, status: ReplyStatus.REJECTED };
      const res = canSendReply(gm, unapproved, sampleCorr);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('لا يمكن إرسال رد غير معتمد');
    });

    it('يمنع إعادة إرسال رد تم إرساله مسبقاً', () => {
      const alreadySent = { ...approvedReply, sentAt: new Date() };
      const res = canSendReply(gm, alreadySent, sampleCorr);
      expect(res.allowed).toBe(false);
      expect(res.reason).toBe('تم إرسال هذا الرد مسبقًا');
    });

    it('يمنع الإرسال إذا لم تكن المراسلة واردة أو ينقصها بريد إلكتروني', () => {
      const noEmailCorr = { ...sampleCorr, senderEmail: null };
      const noEmailRes = canSendReply(gm, approvedReply, noEmailCorr);
      expect(noEmailRes.allowed).toBe(false);
      expect(noEmailRes.reason).toBe(
        'لا يوجد بريد إلكتروني للمرسل — حدّث بيانات المراسلة أولًا',
      );
    });

    it('يسمح بالإرسال عند اكتمال كافة الشروط للإدارة العليا', () => {
      expect(canSendReply(gm, approvedReply, sampleCorr).allowed).toBe(true);
      expect(canSendReply(deputyGm, approvedReply, sampleCorr).allowed).toBe(true);
      expect(canSendReply(admin, approvedReply, sampleCorr).allowed).toBe(true);
    });
  });

  describe('5 & 6. سياسات الإغلاق والأرشفة (canClose / canArchive)', () => {
    it('يحصر الإغلاق والأرشفة بالإدارة العليا', () => {
      expect(canCloseCorrespondence(employee1, sampleCorr).allowed).toBe(false);
      expect(canCloseCorrespondence(deptManager1, sampleCorr).allowed).toBe(false);

      expect(canArchiveCorrespondence(employee1, sampleCorr).allowed).toBe(false);
      expect(canArchiveCorrespondence(deptManager1, sampleCorr).allowed).toBe(false);
    });

    it('يتحقق من قابلية الإغلاق والأرشفة وفق آلة الحالات للإدارة العليا', () => {
      // RECEIVED قابلة للإغلاق والأرشفة
      expect(canCloseCorrespondence(gm, sampleCorr).allowed).toBe(true);
      expect(canArchiveCorrespondence(gm, sampleCorr).allowed).toBe(true);

      // PENDING_APPROVAL غير قابلة للإغلاق مباشرة
      const pendingCorr = { ...sampleCorr, status: CorrespondenceStatus.PENDING_APPROVAL };
      expect(canCloseCorrespondence(gm, pendingCorr).allowed).toBe(false);
    });
  });
});
