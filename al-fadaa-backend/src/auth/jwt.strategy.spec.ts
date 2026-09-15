import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { JwtStrategy, JwtPayload } from './jwt.strategy';

describe('JwtStrategy', () => {
  it('يُنشأ بنجاح عند توفر JWT_SECRET', () => {
    const configMock = {
      getOrThrow: jest.fn().mockReturnValue('my-secure-secret-key'),
      get: jest.fn((key: string) => {
        if (key === 'JWT_ISSUER') return 'alfadaa-api';
        if (key === 'JWT_AUDIENCE') return 'alfadaa-app';
        return undefined;
      }),
    } as unknown as ConfigService;

    const strategy = new JwtStrategy(configMock);
    expect(strategy).toBeDefined();
    expect(configMock.getOrThrow).toHaveBeenCalledWith('JWT_SECRET');
  });

  it('يفشل في الإنشاء ويلقي خطأ عند غياب JWT_SECRET', () => {
    const configMock = {
      getOrThrow: jest.fn().mockImplementation((key: string) => {
        if (key === 'JWT_SECRET') throw new Error('JWT_SECRET is required');
      }),
      get: jest.fn().mockReturnValue(undefined),
    } as unknown as ConfigService;

    expect(() => new JwtStrategy(configMock)).toThrow('JWT_SECRET is required');
  });

  it('يتحقق من payload الرمز ويعيد كائن المستخدم الصالح', async () => {
    const configMock = {
      getOrThrow: jest.fn().mockReturnValue('my-secure-secret-key'),
      get: jest.fn().mockReturnValue(undefined),
    } as unknown as ConfigService;

    const strategy = new JwtStrategy(configMock);
    const payload: JwtPayload = {
      sub: 'user-uuid-1',
      email: 'user@al-fadaa.com',
      name: 'موظف تجريبي',
      role: 'EMPLOYEE',
      departmentId: 'dept-1',
    };

    const user = await strategy.validate(payload);
    expect(user.id).toBe('user-uuid-1');
    expect(user.email).toBe('user@al-fadaa.com');
    expect(user.role).toBe('EMPLOYEE');
  });

  it('يرفض الرمز إذا كان sub مفقودًا', async () => {
    const configMock = {
      getOrThrow: jest.fn().mockReturnValue('my-secure-secret-key'),
      get: jest.fn().mockReturnValue(undefined),
    } as unknown as ConfigService;

    const strategy = new JwtStrategy(configMock);
    const invalidPayload = {
      sub: '',
      email: 'user@al-fadaa.com',
      name: 'موظف',
      role: 'EMPLOYEE',
    } as JwtPayload;

    await expect(strategy.validate(invalidPayload)).rejects.toThrow(UnauthorizedException);
  });
});
