import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { SsePubSubService, SsePubSubMessage } from './sse-pubsub.service';

describe('SsePubSubService', () => {
  let service: SsePubSubService;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        SsePubSubService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue(undefined), // لا يوجد Redis في بيئة الاختبار
          },
        },
      ],
    }).compile();

    service = moduleRef.get(SsePubSubService);
    await service.onModuleInit();
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('يجب أن يعمل في وضع الذاكرة المحلي عند عدم توفر إعدادات Redis', () => {
    expect(service.isRedisConnected).toBe(false);
    expect(service.instanceId).toBeDefined();
    expect(service.instanceId).toMatch(/^node-/);
  });

  it('يجب أن يبث الحدث لجميع المشتركين المسجلين في الوضع المحلي', async () => {
    const received: SsePubSubMessage[] = [];
    service.subscribe((msg) => received.push(msg));

    expect(service.subscriberCount).toBe(1);

    await service.publish(['user-1', 'user-2'], 'NEW_NOTIFICATION', { title: 'إشعار تجريبي' });

    expect(received.length).toBe(1);
    expect(received[0].userIds).toEqual(['user-1', 'user-2']);
    expect(received[0].event).toBe('NEW_NOTIFICATION');
    expect(received[0].data).toEqual({ title: 'إشعار تجريبي' });
    expect(received[0].senderInstanceId).toBe(service.instanceId);
  });

  it('يجب أن يدعم تسجيل عدة مشتركين وتوزيع الحدث عليهم بالتساوي', async () => {
    let count1 = 0;
    let count2 = 0;

    service.subscribe(() => { count1++; });
    service.subscribe(() => { count2++; });

    expect(service.subscriberCount).toBe(2);

    await service.publish(['user-gm'], 'SLA_ALERT', { level: 'CRITICAL' });

    expect(count1).toBe(1);
    expect(count2).toBe(1);
  });

  it('يجب أن يفرغ المستمعين عند استدعاء onModuleDestroy', () => {
    service.subscribe(() => {});
    expect(service.subscriberCount).toBe(1);

    service.onModuleDestroy();
    expect(service.subscriberCount).toBe(0);
  });
});
