import 'reflect-metadata';
import { validateEnv } from './env.validation';

describe('validateEnv', () => {
  const validConfig = {
    DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
    JWT_SECRET: 'super-secret-key-for-testing-only-12345',
    JWT_EXPIRES_IN: '12h',
  };

  it('ينجح عندما تكون جميع المتغيرات الإلزامية موجودة', () => {
    const result = validateEnv({ ...validConfig });
    expect(result.DATABASE_URL).toBe(validConfig.DATABASE_URL);
    expect(result.JWT_SECRET).toBe(validConfig.JWT_SECRET);
    expect(result.JWT_EXPIRES_IN).toBe(validConfig.JWT_EXPIRES_IN);
    expect(result.JWT_ISSUER).toBe('alfadaa-api');
    expect(result.JWT_AUDIENCE).toBe('alfadaa-app');
  });

  it('يقبل JWT_ISSUER و JWT_AUDIENCE المخصصة', () => {
    const result = validateEnv({
      ...validConfig,
      JWT_ISSUER: 'custom-issuer',
      JWT_AUDIENCE: 'custom-audience',
    });
    expect(result.JWT_ISSUER).toBe('custom-issuer');
    expect(result.JWT_AUDIENCE).toBe('custom-audience');
  });

  it('يفشل ويلقي خطأ عند غياب JWT_SECRET', () => {
    const invalidConfig = {
      DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
      JWT_EXPIRES_IN: '12h',
    };
    expect(() => validateEnv(invalidConfig)).toThrow('JWT_SECRET');
  });

  it('يفشل ويلقي خطأ عندما يكون JWT_SECRET نصًا فارغًا', () => {
    const invalidConfig = {
      ...validConfig,
      JWT_SECRET: '',
    };
    expect(() => validateEnv(invalidConfig)).toThrow('JWT_SECRET');
  });

  it('يفشل ويلقي خطأ عند غياب DATABASE_URL', () => {
    const invalidConfig = {
      JWT_SECRET: 'some-secret',
      JWT_EXPIRES_IN: '12h',
    };
    expect(() => validateEnv(invalidConfig)).toThrow('DATABASE_URL');
  });

  it('يفشل ويلقي خطأ عند غياب JWT_EXPIRES_IN', () => {
    const invalidConfig = {
      DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
      JWT_SECRET: 'some-secret',
    };
    expect(() => validateEnv(invalidConfig)).toThrow('JWT_EXPIRES_IN');
  });
});
