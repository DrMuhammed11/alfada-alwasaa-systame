import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { AdminService } from './admin.service';
import { MailRetryService } from '../mail/mail-retry.service';
import { CorrespondenceStatus, CorrespondenceType, Priority, TaskStatus } from '@prisma/client';

describe('Admin Analytics (Dashboard KPIs & SLA)', () => {
  let adminService: AdminService;
  let prisma: {
    correspondence: {
      count: jest.Mock;
      findMany: jest.Mock;
    };
    department: {
      findMany: jest.Mock;
    };
    task: {
      findMany: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      correspondence: {
        count: jest.fn().mockImplementation(({ where }) => {
          if (where?.type === CorrespondenceType.INCOMING) return Promise.resolve(10);
          if (where?.type === CorrespondenceType.OUTGOING) return Promise.resolve(5);
          if (where?.type === CorrespondenceType.INTERNAL) return Promise.resolve(3);
          if (where?.status === CorrespondenceStatus.CLOSED) return Promise.resolve(8);
          if (where?.status === CorrespondenceStatus.ARCHIVED) return Promise.resolve(2);
          if (where?.priority === Priority.URGENT) return Promise.resolve(2);
          if (where?.priority === Priority.HIGH) return Promise.resolve(4);
          if (where?.priority === Priority.NORMAL) return Promise.resolve(10);
          if (where?.priority === Priority.LOW) return Promise.resolve(2);
          return Promise.resolve(18); // total
        }),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'c-1',
            createdAt: new Date('2026-03-01T08:00:00Z'),
            type: CorrespondenceType.INCOMING,
            status: CorrespondenceStatus.CLOSED,
            departmentId: 'dept-1',
          },
          {
            id: 'c-2',
            createdAt: new Date('2026-03-02T09:00:00Z'),
            type: CorrespondenceType.OUTGOING,
            status: CorrespondenceStatus.CLOSED,
            departmentId: 'dept-2',
          },
        ]),
      },
      department: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'dept-1', name: 'تقنية المعلومات', code: 'IT' },
          { id: 'dept-2', name: 'الشؤون الإدارية', code: 'ADMIN' },
        ]),
      },
      task: {
        findMany: jest.fn().mockResolvedValue([
          // مهمة منجزة في الموعد
          {
            id: 't-1',
            status: TaskStatus.DONE,
            dueDate: new Date('2026-03-10T00:00:00Z'),
            doneAt: new Date('2026-03-08T00:00:00Z'),
            correspondence: { departmentId: 'dept-1' },
          },
          // مهمة متأخرة
          {
            id: 't-2',
            status: TaskStatus.DONE,
            dueDate: new Date('2026-03-05T00:00:00Z'),
            doneAt: new Date('2026-03-09T00:00:00Z'),
            correspondence: { departmentId: 'dept-2' },
          },
        ]),
      },
    };

  const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        {
          provide: PrismaService,
          useValue: prisma,
        },
        {
          provide: MailRetryService,
          useValue: {},
        },
      ],
    }).compile();

    adminService = module.get<AdminService>(AdminService);
  });

  it('يحسب الإحصائيات العامة للمراسلات بنجاح', async () => {
    const analytics = await adminService.getAnalytics({ period: '30d' });

    expect(analytics.summary.total).toBe(18);
    expect(analytics.summary.incoming).toBe(10);
    expect(analytics.summary.outgoing).toBe(5);
    expect(analytics.summary.internal).toBe(3);
    expect(analytics.summary.closed).toBe(8);
    expect(analytics.summary.archived).toBe(2);
    expect(analytics.summary.active).toBe(8); // 18 - (8 + 2)
  });

  it('يحسب مؤشر الالتزام بالـ SLA ونسب الإنجاز', async () => {
    const analytics = await adminService.getAnalytics({ period: '30d' });

    expect(analytics.sla.totalTasks).toBe(2);
    expect(analytics.sla.onTimeTasks).toBe(1);
    expect(analytics.sla.overdueTasks).toBe(1);
    expect(analytics.sla.complianceRate).toBe(50.0); // 1 on time / 2 total = 50%
  });

  it('يوزع إحصائيات الأداء حسب الأقسام', async () => {
    const analytics = await adminService.getAnalytics({ period: '30d' });

    expect(analytics.departmentPerformance).toHaveLength(2);
    const itDept = analytics.departmentPerformance.find((d) => d.code === 'IT');
    expect(itDept).toBeDefined();
    expect(itDept?.correspondences).toBe(1);
    expect(itDept?.tasksCompleted).toBe(1);
  });

  it('يبني سلسلة البيانات الزمنية Trend للرسوم البيانية', async () => {
    const analytics = await adminService.getAnalytics({ period: '30d' });

    expect(analytics.trend).toBeDefined();
    expect(analytics.trend.length).toBeGreaterThan(0);
    expect(analytics.trend[0].date).toBe('2026-03-01');
    expect(analytics.trend[0].incoming).toBe(1);
  });
});
