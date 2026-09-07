import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { CorrespondenceStatus, ReferralStatus, Role } from '@prisma/client';
import { ReferralsService } from './referrals.service';
import type { AuthUser } from '../common/types';

describe('Referrals Lifecycle & Cascading Specifications', () => {
  let service: ReferralsService;
  let mockPrisma: any;
  let mockAudit: any;
  let mockNotifications: any;
  let mockCorrespondences: any;
  let mockOutbox: any;

  // مستودع الذاكرة لمحاكاة قاعدة البيانات
  let correspondences: any[];
  let referrals: any[];
  let users: Record<string, AuthUser & { departmentId?: string | null; isActive?: boolean }>;

  const gmUser: AuthUser = {
    id: 'user-gm',
    name: 'المدير العام',
    email: 'gm@al-fadaa.com',
    role: Role.GM,
  };

  const deputyUser: AuthUser = {
    id: 'user-deputy',
    name: 'نائب المدير العام',
    email: 'deputy@al-fadaa.com',
    role: Role.DEPUTY_GM,
  };

  const mgr1User: AuthUser & { departmentId: string } = {
    id: 'user-mgr-1',
    name: 'مدير العقود',
    email: 'contracts@al-fadaa.com',
    role: Role.DEPT_MANAGER,
    departmentId: 'dept-contracts',
  };

  const mgr2User: AuthUser & { departmentId: string } = {
    id: 'user-mgr-2',
    name: 'مدير الهندسة',
    email: 'engineering@al-fadaa.com',
    role: Role.DEPT_MANAGER,
    departmentId: 'dept-eng',
  };

  const empUser: AuthUser & { departmentId: string } = {
    id: 'user-emp-1',
    name: 'مهندس تنفيذ',
    email: 'engineer@al-fadaa.com',
    role: Role.EMPLOYEE,
    departmentId: 'dept-eng',
  };

  beforeEach(() => {
    correspondences = [
      {
        id: 'corr-parallel-1',
        refNumber: 'INC-2026-00010',
        subject: 'مشروع إنشاء مبنى الفضاء الجديد',
        status: CorrespondenceStatus.RECEIVED,
        version: 1,
        departmentId: null,
      },
      {
        id: 'corr-chained-1',
        refNumber: 'INC-2026-00020',
        subject: 'طلب توريد منظومة خوادم سحابية',
        status: CorrespondenceStatus.UNDER_REVIEW,
        version: 1,
        departmentId: null,
      },
    ];

    referrals = [];

    users = {
      [gmUser.id]: { ...gmUser, isActive: true, departmentId: null },
      [deputyUser.id]: { ...deputyUser, isActive: true, departmentId: null },
      [mgr1User.id]: { ...mgr1User, isActive: true },
      [mgr2User.id]: { ...mgr2User, isActive: true },
      [empUser.id]: { ...empUser, isActive: true },
    };

    mockAudit = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    mockNotifications = {
      notifyReferralReceived: jest.fn().mockResolvedValue(undefined),
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    mockCorrespondences = {
      canView: jest.fn().mockResolvedValue(true),
      findOne: jest.fn().mockResolvedValue({}),
    };

    mockOutbox = {
      emit: jest.fn().mockResolvedValue({ id: 'outbox-1' }),
    };

    let refIdCounter = 1;

    const mockTx = {
      correspondence: {
        updateMany: jest.fn(async ({ where, data }) => {
          const target = correspondences.find((c) => c.id === where.id);
          if (!target) return { count: 0 };
          if (where.status && where.status.in && !where.status.in.includes(target.status)) {
            return { count: 0 };
          }
          if (where.status && typeof where.status === 'string' && where.status !== target.status) {
            return { count: 0 };
          }
          if (data.status) target.status = data.status;
          if (data.departmentId !== undefined) target.departmentId = data.departmentId;
          if (data.version?.increment) target.version += data.version.increment;
          return { count: 1 };
        }),
        findUnique: jest.fn(async ({ where }) => {
          return correspondences.find((c) => c.id === where.id) || null;
        }),
      },
      referral: {
        create: jest.fn(async ({ data }) => {
          const newRef = {
            id: `ref-${refIdCounter++}`,
            correspondenceId: data.correspondenceId,
            fromUserId: data.fromUserId,
            toUserId: data.toUserId,
            note: data.note || null,
            status: ReferralStatus.OPEN,
            dueDate: data.dueDate || null,
            answeredAt: null,
            closedAt: null,
            createdAt: new Date(),
            fromUser: users[data.fromUserId],
            toUser: users[data.toUserId],
            correspondence: correspondences.find((c) => c.id === data.correspondenceId),
          };
          referrals.push(newRef);
          return newRef;
        }),
        findFirst: jest.fn(async ({ where }) => {
          return (
            referrals.find(
              (r) =>
                r.correspondenceId === where.correspondenceId &&
                r.toUserId === where.toUserId &&
                r.status === where.status,
            ) || null
          );
        }),
        findMany: jest.fn(async ({ where }) => {
          return referrals.filter((r) => {
            if (where.correspondenceId && r.correspondenceId !== where.correspondenceId) return false;
            if (where.status && r.status !== where.status) return false;
            return true;
          });
        }),
        count: jest.fn(async ({ where }) => {
          return referrals.filter((r) => {
            if (where.correspondenceId && r.correspondenceId !== where.correspondenceId) return false;
            if (where.status && r.status !== where.status) return false;
            return true;
          }).length;
        }),
        update: jest.fn(async ({ where, data }) => {
          const target = referrals.find((r) => r.id === where.id);
          if (!target) throw new Error('Referral not found');
          if (data.status) target.status = data.status;
          if (data.answeredAt) target.answeredAt = data.answeredAt;
          if (data.closedAt) target.closedAt = data.closedAt;
          return target;
        }),
      },
    };

    mockPrisma = {
      correspondence: {
        findUnique: jest.fn(async ({ where }) => {
          return correspondences.find((c) => c.id === where.id) || null;
        }),
      },
      user: {
        findUnique: jest.fn(async ({ where }) => {
          return users[where.id] || null;
        }),
      },
      referral: {
        findUnique: jest.fn(async ({ where }) => {
          return referrals.find((r) => r.id === where.id) || null;
        }),
        findFirst: jest.fn(async ({ where }) => {
          return (
            referrals.find(
              (r) =>
                r.correspondenceId === where.correspondenceId &&
                r.toUserId === where.toUserId &&
                r.status === where.status,
            ) || null
          );
        }),
        count: jest.fn(async ({ where }) => {
          return referrals.filter((r) => {
            if (where.correspondenceId && r.correspondenceId !== where.correspondenceId) return false;
            if (where.status && r.status !== where.status) return false;
            return true;
          }).length;
        }),
      },
      $transaction: jest.fn(async (cb: any) => {
        if (typeof cb === 'function') return cb(mockTx);
        return cb;
      }),
    };

    service = new ReferralsService(
      mockPrisma,
      mockAudit,
      mockCorrespondences,
      mockNotifications,
      mockOutbox,
      undefined,
    );
  });

  describe('السيناريو الأول: الإحالتان المتوازيتان (Parallel Referrals)', () => {
    it('يجب أن يدير إحالتين متوازيتين باستقلال، ويمنع التكرار، ولا ينقل المراسلة إلى IN_PROGRESS إلا بعد إجابة كلتيهما', async () => {
      const corrId = 'corr-parallel-1';

      // 1. المدير العام يحيل المراسلة إلى نائبه (إحالة 1)
      const ref1 = await service.create(
        corrId,
        { toUserId: deputyUser.id, note: 'يرجى مراجعة العرض المالي' },
        gmUser,
      );
      expect(ref1.id).toBeDefined();
      expect(ref1.status).toBe(ReferralStatus.OPEN);

      const corrAfterFirst = correspondences.find((c) => c.id === corrId);
      expect(corrAfterFirst.status).toBe(CorrespondenceStatus.REFERRED);

      // 2. المدير العام يحيل نفس المراسلة بالتوازي إلى مدير العقود (إحالة 2)
      const ref2 = await service.create(
        corrId,
        { toUserId: mgr1User.id, note: 'يرجى تدقيق الشروط القانونية' },
        gmUser,
      );
      expect(ref2.id).toBeDefined();
      expect(ref2.status).toBe(ReferralStatus.OPEN);

      // المراسلة لا تزال REFERRED
      const corrAfterSecond = correspondences.find((c) => c.id === corrId);
      expect(corrAfterSecond.status).toBe(CorrespondenceStatus.REFERRED);

      // 3. محاولة إحالة لنفس المستخدم (النائب) مرة أخرى بينما إحالته مفتوحة -> رفض صريح
      await expect(
        service.create(corrId, { toUserId: deputyUser.id, note: 'تذكير ثانٍ' }, gmUser),
      ).rejects.toThrow(
        new BadRequestException('توجد إحالة مفتوحة سابقة لهذا المستخدم على هذه المراسلة بالفعل'),
      );

      // 4. نائب المدير يجيب على إحالته الخاصة (إحالة 1)
      const answeredRef1 = await service.answerReferral(ref1.id, deputyUser);
      expect(answeredRef1.status).toBe(ReferralStatus.ANSWERED);
      expect(answeredRef1.answeredAt).toBeDefined();

      // المراسلة يجب أن تظل REFERRED لأن إحالة مدير العقود ما زالت OPEN!
      const corrAfterAnswer1 = correspondences.find((c) => c.id === corrId);
      expect(corrAfterAnswer1.status).toBe(CorrespondenceStatus.REFERRED);

      // 5. مدير العقود يجيب على إحالته (إحالة 2)
      const answeredRef2 = await service.answerReferral(ref2.id, mgr1User);
      expect(answeredRef2.status).toBe(ReferralStatus.ANSWERED);
      expect(answeredRef2.answeredAt).toBeDefined();

      // الآن أُجيبت كل الإحالات المفتوحة (OPEN count === 0) ➔ المراسلة تنتقل إلى IN_PROGRESS
      const corrFinal = correspondences.find((c) => c.id === corrId);
      expect(corrFinal.status).toBe(CorrespondenceStatus.IN_PROGRESS);
      expect(corrFinal.version).toBeGreaterThan(1);
    });

    it('يسمح بفتح إحالة جديدة للمستخدم بعد إجابة إحالته السابقة واكتمالها', async () => {
      const corrId = 'corr-parallel-1';

      // إحالة للنائب
      const ref1 = await service.create(corrId, { toUserId: deputyUser.id }, gmUser);
      // إجابة الإحالة
      await service.answerReferral(ref1.id, deputyUser);

      // استجدت حاجة إدارية لمشاورة النائب مرة أخرى بعد الإجابة ➔ مسموح
      const refNew = await service.create(corrId, { toUserId: deputyUser.id, note: 'استفسار تعقيبي' }, gmUser);
      expect(refNew.id).not.toBe(ref1.id);
      expect(refNew.status).toBe(ReferralStatus.OPEN);
    });
  });

  describe('السيناريو الثاني: الإحالة المتسلسلة (Chained / Cascading Referrals)', () => {
    it('يجب أن تبقي إحالة النائب مفتوحة عند إحالته لمدير القسم، وتُشعر جميع المرسلين المعنيين عند إجابة الإحالة الفرعية', async () => {
      const corrId = 'corr-chained-1';

      // 1. المدير العام يحيل إلى نائبه (إحالة 1: GM ➔ Deputy GM)
      const ref1 = await service.create(
        corrId,
        { toUserId: deputyUser.id, note: 'للتنسيق مع الهندسة' },
        gmUser,
      );
      expect(ref1.status).toBe(ReferralStatus.OPEN);

      // المراسلة تصبح REFERRED
      expect(correspondences.find((c) => c.id === corrId).status).toBe(CorrespondenceStatus.REFERRED);

      // 2. نائب المدير العام يحيل المراسلة إلى مدير الهندسة (إحالة 2: Deputy GM ➔ Mgr 2)
      const ref2 = await service.create(
        corrId,
        { toUserId: mgr2User.id, note: 'إبداء الرأي في مواصفات الخوادم' },
        deputyUser,
      );
      expect(ref2.status).toBe(ReferralStatus.OPEN);

      // إحالة النائب (إحالة 1) لا تزال مفتوحة OPEN
      expect(ref1.status).toBe(ReferralStatus.OPEN);

      // 3. مدير الهندسة يجيب على إحالته (إحالة 2)
      await service.answerReferral(ref2.id, mgr2User);
      expect(ref2.status).toBe(ReferralStatus.ANSWERED);

      // إحالة النائب لا تزال OPEN ➔ المراسلة تظل REFERRED
      expect(ref1.status).toBe(ReferralStatus.OPEN);
      expect(correspondences.find((c) => c.id === corrId).status).toBe(CorrespondenceStatus.REFERRED);

      // التحقق من نطاق الإشعار الموسع: إشعار النائب والمدير العام
      expect(mockNotifications.notifyMany).toHaveBeenCalledWith(
        expect.arrayContaining([deputyUser.id, gmUser.id]),
        expect.objectContaining({
          type: 'NEW_REFERRAL',
          title: expect.stringContaining('INC-2026-00020'),
        }),
      );

      // 4. نائب المدير العام (بعد اطلاعه على إفادة الهندسة) يجيب على إحالته (إحالة 1)
      await service.answerReferral(ref1.id, deputyUser);
      expect(ref1.status).toBe(ReferralStatus.ANSWERED);

      // الآن كافة الإحالات أُجيبت ➔ المراسلة تنتقل إلى IN_PROGRESS
      expect(correspondences.find((c) => c.id === corrId).status).toBe(CorrespondenceStatus.IN_PROGRESS);
    });
  });

  describe('الصلاحيات وقواعد الحماية (Permissions & Business Policy)', () => {
    it('يمنع مستخدماً ليس الجهة المحال إليها ولا إدارة عليا من إجابة الإحالة', async () => {
      const corrId = 'corr-parallel-1';
      const ref = await service.create(corrId, { toUserId: deputyUser.id }, gmUser);

      // موظف عادي يحاول إجابة إحالة موجهة لنائب المدير
      await expect(service.answerReferral(ref.id, empUser)).rejects.toThrow(
        new ForbiddenException('فقط الجهة المحال إليها أو الإدارة العليا تملك إجابة الإحالة'),
      );
    });

    it('يمنع إجابة إحالة تمت إجابتها مسبقاً', async () => {
      const corrId = 'corr-parallel-1';
      const ref = await service.create(corrId, { toUserId: deputyUser.id }, gmUser);

      await service.answerReferral(ref.id, deputyUser);

      // محاولة الإجابة مرة ثانية على نفس الإحالة
      await expect(service.answerReferral(ref.id, deputyUser)).rejects.toThrow(
        new BadRequestException('تمت إجابة هذه الإحالة أو إغلاقها مسبقًا'),
      );
    });

    it('يرمي NotFoundException عند طلب إجابة إحالة غير موجودة', async () => {
      await expect(service.answerReferral('non-existent-id', deputyUser)).rejects.toThrow(
        new NotFoundException('الإحالة غير موجودة'),
      );
    });
  });
});
