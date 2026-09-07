import { NotificationType, ReferralStatus, Role, SlaReminderType, TaskStatus } from '@prisma/client';
import { SlaService } from './sla.service';

describe('SlaService (SLA Engine & Smart Alerts Specifications)', () => {
  let service: SlaService;
  let mockPrisma: any;
  let mockNotifications: any;
  let mockConfig: any;

  let inMemorySlaStates: any[];
  let inMemoryReferrals: any[];
  let inMemoryTasks: any[];
  let inMemoryUsers: any[];

  beforeEach(() => {
    inMemorySlaStates = [];
    inMemoryReferrals = [];
    inMemoryTasks = [];
    inMemoryUsers = [
      { id: 'user-gm-1', role: Role.GM, isActive: true },
      { id: 'user-gm-2', role: Role.GM, isActive: true },
    ];

    mockNotifications = {
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    mockConfig = {
      get: jest.fn((key: string) => {
        if (key === 'REMINDER_HOURS_BEFORE') return '24';
        return undefined;
      }),
    };

    mockPrisma = {
      slaState: {
        findUnique: jest.fn(async ({ where }) => {
          const key = where.entityType_entityId_lastReminderType;
          return (
            inMemorySlaStates.find(
              (s) =>
                s.entityType === key.entityType &&
                s.entityId === key.entityId &&
                s.lastReminderType === key.lastReminderType,
            ) || null
          );
        }),
        create: jest.fn(async ({ data }) => {
          const state = { id: `sla-${inMemorySlaStates.length + 1}`, ...data };
          inMemorySlaStates.push(state);
          return state;
        }),
        upsert: jest.fn(async ({ where, create, update }) => {
          const key = where.entityType_entityId_lastReminderType;
          const existing = inMemorySlaStates.find(
            (s) =>
              s.entityType === key.entityType &&
              s.entityId === key.entityId &&
              s.lastReminderType === key.lastReminderType,
          );
          if (existing) {
            Object.assign(existing, update);
            return existing;
          }
          const state = { id: `sla-${inMemorySlaStates.length + 1}`, ...create };
          inMemorySlaStates.push(state);
          return state;
        }),
      },
      referral: {
        findMany: jest.fn(async ({ where }) => {
          return inMemoryReferrals.filter((r) => {
            if (where.status && r.status !== where.status) return false;
            if (where.dueDate?.gt && !(r.dueDate > where.dueDate.gt)) return false;
            if (where.dueDate?.lte && !(r.dueDate <= where.dueDate.lte)) return false;
            if (where.dueDate?.lt && !(r.dueDate < where.dueDate.lt)) return false;
            return true;
          });
        }),
      },
      task: {
        findMany: jest.fn(async ({ where }) => {
          return inMemoryTasks.filter((t) => {
            if (where.status?.in && !where.status.in.includes(t.status)) return false;
            if (where.dueDate?.gt && !(t.dueDate > where.dueDate.gt)) return false;
            if (where.dueDate?.lte && !(t.dueDate <= where.dueDate.lte)) return false;
            if (where.dueDate?.lt && !(t.dueDate < where.dueDate.lt)) return false;
            return true;
          });
        }),
      },
      user: {
        findMany: jest.fn(async ({ where }) => {
          return inMemoryUsers.filter((u) => {
            if (where.role && u.role !== where.role) return false;
            if (where.isActive !== undefined && u.isActive !== where.isActive) return false;
            return true;
          });
        }),
      },
    };

    service = new SlaService(mockPrisma, mockNotifications, mockConfig);
  });

  it('1. يرسل تذكير اقتراب الاستحقاق (APPROACHING) قبل 24 ساعة مرة واحدة فقط دون تكرار', async () => {
    const now = new Date('2026-09-10T10:00:00Z');
    // مهمة تستحق بعد 12 ساعة (ضمن نافذة الـ 24 ساعة)
    const taskDueIn12h = {
      id: 'task-approaching-1',
      title: 'إعداد جدول الكميات',
      status: TaskStatus.IN_PROGRESS,
      dueDate: new Date('2026-09-10T22:00:00Z'),
      assignedToId: 'emp-1',
      assignedTo: { id: 'emp-1', name: 'مهندس 1' },
      correspondence: { id: 'corr-1', refNumber: 'INC-2026-00100', subject: 'مشروع الفضاء' },
    };
    inMemoryTasks.push(taskDueIn12h);

    // الفحص الأول: يولد تذكير ويحفظه في SlaState
    const countFirst = await service.checkApproachingDeadlines(now);
    expect(countFirst).toBe(1);
    expect(mockNotifications.notifyMany).toHaveBeenCalledTimes(1);
    expect(mockNotifications.notifyMany).toHaveBeenCalledWith(
      ['emp-1'],
      expect.objectContaining({
        title: expect.stringContaining('إعداد جدول الكميات'),
      }),
    );
    expect(inMemorySlaStates.length).toBe(1);
    expect(inMemorySlaStates[0].lastReminderType).toBe(SlaReminderType.APPROACHING);

    // الفحص الثاني بعد ساعة (نفس المهمة لا تزال ضمن النافذة): لا يكرر التنبيه
    const later = new Date('2026-09-10T11:00:00Z');
    const countSecond = await service.checkApproachingDeadlines(later);
    expect(countSecond).toBe(0);
    expect(mockNotifications.notifyMany).toHaveBeenCalledTimes(1); // لم يزد عدد الاستدعاءات
  });

  it('2. يرسل تنبيه التأخير (OVERDUE) عند تجاوز الموعد للمكلف والمسند مرة واحدة فقط دون إزعاج متكرر', async () => {
    const now = new Date('2026-09-11T12:00:00Z');
    // إحالة تأخرت بيوم
    const overdueReferral = {
      id: 'ref-overdue-1',
      status: ReferralStatus.OPEN,
      dueDate: new Date('2026-09-10T12:00:00Z'),
      toUserId: 'mgr-contracts',
      fromUserId: 'gm-user',
      toUser: { id: 'mgr-contracts', name: 'مدير العقود' },
      fromUser: { id: 'gm-user', name: 'المدير العام' },
      correspondence: { id: 'corr-2', refNumber: 'INC-2026-00200', subject: 'عقد توريد' },
    };
    inMemoryReferrals.push(overdueReferral);

    const alertsSent = await service.checkOverdueItems(now);
    expect(alertsSent).toBe(1);
    expect(mockNotifications.notifyMany).toHaveBeenCalledWith(
      expect.arrayContaining(['mgr-contracts', 'gm-user']),
      expect.objectContaining({
        title: expect.stringContaining('تنبيه تأخير'),
      }),
    );

    // التحقق من الحفظ في SlaState
    expect(inMemorySlaStates.some((s) => s.lastReminderType === SlaReminderType.OVERDUE)).toBe(true);

    // محاولة فحص ثانية: لا يكرر التنبيه
    const secondCheck = await service.checkOverdueItems(now);
    expect(secondCheck).toBe(0);
  });

  it('3. يرسل تصعيداً أسبوعياً مجمّعاً واحداً للمدير العام يذكر عدد المتأخرات وأقدم تأخير حسب القسم بدل إغراق الصندوق', async () => {
    const now = new Date('2026-09-20T08:00:00Z');

    // قسم الهندسة: 3 تكليفات متأخرة بأيام مختلفة (2 أيام، 5 أيام، 12 يوماً)
    inMemoryTasks.push(
      {
        id: 't-1',
        title: 'مهمة 1',
        status: TaskStatus.IN_PROGRESS,
        dueDate: new Date('2026-09-18T08:00:00Z'), // متأخرة يومين
        assignedTo: { id: 'e-1', name: 'مهندس 1', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
        correspondence: { id: 'c-1', refNumber: 'INC-001', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
      },
      {
        id: 't-2',
        title: 'مهمة 2',
        status: TaskStatus.PENDING,
        dueDate: new Date('2026-09-15T08:00:00Z'), // متأخرة 5 أيام
        assignedTo: { id: 'e-2', name: 'مهندس 2', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
        correspondence: { id: 'c-2', refNumber: 'INC-002', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
      },
      {
        id: 't-3',
        title: 'مهمة 3',
        status: TaskStatus.IN_PROGRESS,
        dueDate: new Date('2026-09-08T08:00:00Z'), // متأخرة 12 يوماً (الأقدم)
        assignedTo: { id: 'e-3', name: 'مهندس 3', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
        correspondence: { id: 'c-3', refNumber: 'INC-003', departmentId: 'dept-eng', department: { id: 'dept-eng', name: 'الهندسة' } },
      },
    );

    const escalations = await service.escalateOverdueToGM(now);
    // إشعار مجمّع واحد لقسم الهندسة
    expect(escalations).toBe(1);
    expect(mockNotifications.notifyMany).toHaveBeenCalledTimes(1);
    expect(mockNotifications.notifyMany).toHaveBeenCalledWith(
      ['user-gm-1', 'user-gm-2'],
      expect.objectContaining({
        title: expect.stringContaining('3 مهام متأخرة في قسم «الهندسة»'),
        body: expect.stringContaining('أقدمها متأخر بـ12 يومًا'),
      }),
    );

    // التحقق من تسجيل حالة التصعيد للعناصر الثلاثة
    expect(inMemorySlaStates.filter((s) => s.lastReminderType === SlaReminderType.ESCALATED).length).toBe(3);
  });
});
