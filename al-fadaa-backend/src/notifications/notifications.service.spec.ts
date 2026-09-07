import { Test } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser } from '../common/types';

/** اختبارات وحدة لخدمة الإشعارات — العزل، عدم الفشل، ومنطق الوسم كمقروء */
describe('NotificationsService', () => {
  let service: NotificationsService;
  const createMock = jest.fn().mockResolvedValue({});
  const createManyMock = jest.fn().mockResolvedValue({ count: 2 });
  const countMock = jest.fn().mockResolvedValue(3);
  const findUniqueMock = jest.fn();
  const findUniqueOrThrowMock = jest.fn();
  const updateMock = jest.fn();
  const updateManyMock = jest.fn().mockResolvedValue({ count: 4 });

  const gm: AuthUser = {
    id: 'user-gm',
    email: 'gm@al-fadaa.com',
    name: 'المدير العام',
    role: 'GM',
  };
  const employee: AuthUser = {
    id: 'user-emp',
    email: 'emp@al-fadaa.com',
    name: 'موظف',
    role: 'EMPLOYEE',
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        NotificationsService,
        {
          provide: PrismaService,
          useValue: {
            notification: {
              create: createMock,
              createMany: createManyMock,
              count: countMock,
              findUnique: findUniqueMock,
              findUniqueOrThrow: findUniqueOrThrowMock,
              update: updateMock,
              updateMany: updateManyMock,
            },
          },
        },
      ],
    }).compile();
    service = moduleRef.get(NotificationsService);
  });

  beforeEach(() => {
    createMock.mockClear();
    createManyMock.mockClear();
    countMock.mockClear();
    findUniqueMock.mockClear();
    findUniqueOrThrowMock.mockClear();
    updateMock.mockClear();
    updateManyMock.mockClear();
    updateManyMock.mockResolvedValue({ count: 4 });
  });

  it('notify — ينشئ الإشعار كامل الحقول كما مُرِّرت', async () => {
    await service.notify({
      userId: 'user-9',
      type: NotificationType.NEW_REFERRAL,
      title: 'إحالة جديدة بانتظارك',
      body: 'أحال إليك المدير المراسلة INC-2026-00001',
      link: '/correspondences/corr-1',
      entityType: 'Correspondence',
      entityId: 'corr-1',
    });

    expect(createMock).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'user-9',
        type: NotificationType.NEW_REFERRAL,
        title: 'إحالة جديدة بانتظارك',
        entityType: 'Correspondence',
        entityId: 'corr-1',
      }),
    });
  });

  it('notify — لا يرمي استثناءً إذا فشلت الكتابة — حتى لا تتعطل العملية التجارية', async () => {
    createMock.mockRejectedValueOnce(new Error('DB down'));
    await expect(
      service.notify({ userId: 'u', type: NotificationType.NEW_TASK, title: 'تكليف' }),
    ).resolves.not.toThrow();
  });

  it('notifyMany — يزيل التكرار ويتجاهل المعرفات الفارغة', async () => {
    await service.notifyMany(['a', 'a', '', 'b'], {
      type: NotificationType.REPLY_SENT,
      title: 'أُرسل الرد للعميل',
    });

    expect(createManyMock).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({ userId: 'a' }),
        expect.objectContaining({ userId: 'b' }),
      ],
    });
  });

  it('notifyMany — لا يستدعي قاعدة البيانات إذا لم يبق مستلمون', async () => {
    await service.notifyMany(['', ''], { type: NotificationType.NEW_TASK, title: 'x' });
    expect(createManyMock).not.toHaveBeenCalled();
  });

  it('unreadCount — يعيد { count } لمستخدم معين', async () => {
    const result = await service.unreadCount(gm.id);
    expect(result).toEqual({ count: 3 });
    expect(countMock).toHaveBeenCalledWith({
      where: { userId: gm.id, isRead: false },
    });
  });

  it('markRead — يرفض وسم إشعار لا يخص المستخدم (عزل الصناديق)', async () => {
    findUniqueMock.mockResolvedValueOnce({ userId: gm.id, isRead: false });
    await expect(service.markRead('notif-1', employee)).rejects.toThrow(
      'هذا الإشعار لا يخصك',
    );
    expect(updateMock).not.toHaveBeenCalled();
  });

  it('markRead — يوسم غير المقروء ويضبط readAt', async () => {
    findUniqueMock.mockResolvedValueOnce({ userId: employee.id, isRead: false });
    updateMock.mockResolvedValueOnce({ id: 'notif-1', isRead: true });
    await service.markRead('notif-1', employee);
    expect(updateMock).toHaveBeenCalledWith({
      where: { id: 'notif-1' },
      data: { isRead: true, readAt: expect.any(Date) },
      select: expect.anything(),
    });
  });

  it('markRead — مقروء سابقًا لا يسبب خطأ ولا تحديثًا (idempotent)', async () => {
    findUniqueMock.mockResolvedValueOnce({ userId: employee.id, isRead: true });
    findUniqueOrThrowMock.mockResolvedValueOnce({ id: 'notif-1', isRead: true });
    await expect(service.markRead('notif-1', employee)).resolves.not.toThrow();
    expect(updateMock).not.toHaveBeenCalled();
  });

  it('markAllRead — يوسم غير المقروء للمستخدم نفسه فقط', async () => {
    const result = await service.markAllRead(employee);
    expect(result).toEqual({ updated: 4 });
    expect(updateManyMock).toHaveBeenCalledWith({
      where: { userId: employee.id, isRead: false },
      data: { isRead: true, readAt: expect.any(Date) },
    });
  });
});
