import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { IncomingMailService } from './incoming-mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('IncomingMailService', () => {
  let service: IncomingMailService;
  const countMock = jest.fn().mockResolvedValue(5);

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        IncomingMailService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue(undefined), // لا توجد إعدادات IMAP في بيئة الاختبار
          },
        },
        {
          provide: PrismaService,
          useValue: {
            correspondence: {
              count: countMock,
            },
            user: {
              findUnique: jest.fn().mockResolvedValue(null),
              findFirst: jest.fn().mockResolvedValue(null),
            },
          },
        },
        {
          provide: CorrespondencesService,
          useValue: {},
        },
        {
          provide: RefNumberService,
          useValue: {},
        },
        {
          provide: AuditService,
          useValue: {},
        },
        {
          provide: NotificationsService,
          useValue: {},
        },
      ],
    }).compile();

    service = moduleRef.get(IncomingMailService);
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('يجب أن يعمل بهدوء ولا يبدأ IDLE عند عدم توفر بيانات IMAP في البيئة', async () => {
    await service.onModuleInit();
    expect(service.isIdleActive).toBe(false);
  });

  it('يجب أن يُرجع إجمالي عدد المراسلات الواردة عبر getCorrespondenceCount', async () => {
    const count = await service.getCorrespondenceCount();
    expect(count).toBe(5);
    expect(countMock).toHaveBeenCalledWith({ where: { type: 'INCOMING' } });
  });

  it('يجب أن ينظف الموارد والاتصالات بسلاسة عند استدعاء onModuleDestroy', () => {
    expect(() => service.onModuleDestroy()).not.toThrow();
  });
});
