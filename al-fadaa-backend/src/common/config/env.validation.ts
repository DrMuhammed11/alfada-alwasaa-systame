import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, validateSync } from 'class-validator';

/**
 * فئة التحقق الصارم من متغيرات البيئة الأساسية للنظام
 */
export class EnvironmentVariables {
  @IsNotEmpty({ message: 'DATABASE_URL إلزامي للاتصال بقاعدة البيانات' })
  @IsString({ message: 'DATABASE_URL يجب أن يكون نصًا صالحًا' })
  DATABASE_URL: string;

  @IsNotEmpty({ message: 'JWT_SECRET إلزامي لتوقيع رموز المصادقة' })
  @IsString({ message: 'JWT_SECRET يجب أن يكون نصًا صالحًا' })
  JWT_SECRET: string;

  // اختياري بقيمة افتراضية — كاسمه القديم كان يُضبط يدوياً بلا داعٍ،
  // وأخوه JWT_ACCESS_EXPIRES_IN يحمل الافتراض نفسه
  @IsOptional()
  @IsString({ message: 'JWT_EXPIRES_IN يجب أن يكون نصًا صالحًا' })
  JWT_EXPIRES_IN?: string = '15m';

  @IsOptional()
  @IsString({ message: 'JWT_ACCESS_EXPIRES_IN يجب أن يكون نصًا صالحًا' })
  JWT_ACCESS_EXPIRES_IN?: string = '15m';

  @IsOptional()
  @IsString({ message: 'JWT_REFRESH_EXPIRES_IN_DAYS يجب أن يكون نصًا صالحًا' })
  JWT_REFRESH_EXPIRES_IN_DAYS?: string = '30';

  @IsOptional()
  @IsString({ message: 'JWT_ISSUER يجب أن يكون نصًا صالحًا' })
  JWT_ISSUER?: string = 'alfadaa-api';

  @IsOptional()
  @IsString({ message: 'JWT_AUDIENCE يجب أن يكون نصًا صالحًا' })
  JWT_AUDIENCE?: string = 'alfadaa-app';

  @IsOptional()
  PORT?: string | number;

  @IsOptional()
  @IsString()
  NODE_ENV?: string;

  @IsOptional()
  @IsString()
  CORS_ORIGIN?: string;

  @IsOptional()
  @IsString()
  IMAP_TLS_REJECT_UNAUTHORIZED?: string; // 'false' للتطوير فقط
}

/**
 * دالة التحقق المستخدمة في ConfigModule.forRoot({ validate: validateEnv })
 */
export function validateEnv(config: Record<string, unknown>): Record<string, unknown> {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, { skipMissingProperties: false });

  if (errors.length > 0) {
    const errorDetails = errors
      .map((e) => Object.values(e.constraints ?? {}).join(' | '))
      .join('\n');
    throw new Error(`خطأ في التحقق من صحة متغيرات البيئة الإلزامية:\n${errorDetails}`);
  }

  return {
    ...config,
    JWT_ISSUER: validatedConfig.JWT_ISSUER || 'alfadaa-api',
    JWT_AUDIENCE: validatedConfig.JWT_AUDIENCE || 'alfadaa-app',
  };
}
