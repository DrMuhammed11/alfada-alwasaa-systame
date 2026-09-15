import { ConfigService } from '@nestjs/config';
import { buildThrottlerOptions, ThrottlerLimits } from './throttler-config';

describe('throttler-config', () => {
  it('يبني الخيارات الافتراضية بشكل سليم', () => {
    const configMock = {
      get: jest.fn().mockReturnValue(undefined),
    } as unknown as ConfigService;

    const options = buildThrottlerOptions(configMock);
    expect(options).toBeDefined();
    expect(options.throttlers).toHaveLength(1);
    expect(options.throttlers[0].name).toBe('default');
    expect(options.throttlers[0].ttl).toBe(60000); // 60s * 1000
    expect(options.throttlers[0].limit).toBe(60);
  });

  it('يقرأ الحدود المخصصة من ConfigService', () => {
    const configMock = {
      get: jest.fn((key: string) => {
        if (key === 'THROTTLE_TTL') return '120';
        if (key === 'THROTTLE_LIMIT') return '100';
        return undefined;
      }),
    } as unknown as ConfigService;

    const options = buildThrottlerOptions(configMock);
    expect(options.throttlers[0].ttl).toBe(120000);
    expect(options.throttlers[0].limit).toBe(100);
  });

  it('يعيد حدود تسجيل الدخول المخصصة من بيئة التشغيل', () => {
    process.env.THROTTLE_LOGIN_LIMIT = '7';
    process.env.THROTTLE_LOGIN_TTL = '45';

    const limitFn = ThrottlerLimits.login.default.limit;
    const ttlFn = ThrottlerLimits.login.default.ttl;

    expect(limitFn()).toBe(7);
    expect(ttlFn()).toBe(45000);

    delete process.env.THROTTLE_LOGIN_LIMIT;
    delete process.env.THROTTLE_LOGIN_TTL;
  });

  it('يعيد حدود الاستفسار والتتبع المخصصة من بيئة التشغيل', () => {
    process.env.THROTTLE_INQUIRY_LIMIT = '10';
    process.env.THROTTLE_TRACK_LIMIT = '20';

    expect(ThrottlerLimits.publicInquiry.default.limit()).toBe(10);
    expect(ThrottlerLimits.publicTrack.default.limit()).toBe(20);

    delete process.env.THROTTLE_INQUIRY_LIMIT;
    delete process.env.THROTTLE_TRACK_LIMIT;
  });
});
