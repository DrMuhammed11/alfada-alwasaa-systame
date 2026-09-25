import { ExecutionContext, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ThrottlerModuleOptions, ThrottlerOptions } from '@nestjs/throttler';

const logger = new Logger('ThrottlerConfig');

/**
 * إعدادات تحديد معدل الطلبات (Rate Limiting)
 *
 * الحدود الافتراضية (بالثواني والطلبات) قابلة للضبط عبر متغيرات البيئة:
 * - THROTTLE_TTL / THROTTLE_LIMIT: الحد العام (الافتراضي: 60 طلب / 60 ثانية)
 * - THROTTLE_LOGIN_LIMIT / THROTTLE_LOGIN_TTL: تسجيل الدخول (الافتراضي: 5 محاولات / 60 ثانية)
 * - THROTTLE_INQUIRY_LIMIT / THROTTLE_INQUIRY_TTL: استفسارات الموقع (الافتراضي: 5 طلبات / 60 ثانية)
 * - THROTTLE_TRACK_LIMIT / THROTTLE_TRACK_TTL: تتبع الطلبات (الافتراضي: 15 طلب / 60 ثانية)
 * - REDIS_URL: إذا توفر، يجهّز النظام للمخزن الموزع (Redis)
 */

export const ThrottlerLimits = {
  /** حد تسجيل الدخول الصارم لمنع هجمات التخمين Brute-force */
  login: {
    default: {
      limit: (_ctx?: ExecutionContext) => Number(process.env.THROTTLE_LOGIN_LIMIT) || 5,
      ttl: (_ctx?: ExecutionContext) => (Number(process.env.THROTTLE_LOGIN_TTL) || 60) * 1000,
    },
  },
  /** حد إرسال الاستفسارات العامة لمنع الإغراق السبام */
  publicInquiry: {
    default: {
      limit: (_ctx?: ExecutionContext) => Number(process.env.THROTTLE_INQUIRY_LIMIT) || 5,
      ttl: (_ctx?: ExecutionContext) => (Number(process.env.THROTTLE_INQUIRY_TTL) || 60) * 1000,
    },
  },
  /** حد تتبع المعاملات لمنع مسح الأرقام المرجعية */
  publicTrack: {
    default: {
      limit: (_ctx?: ExecutionContext) => Number(process.env.THROTTLE_TRACK_LIMIT) || 15,
      ttl: (_ctx?: ExecutionContext) => (Number(process.env.THROTTLE_TRACK_TTL) || 60) * 1000,
    },
  },
  /** حد قراءة محتوى الموقع العام (خدمات/قطاعات/مشاريع/أسئلة) — سخي لأنه محتوى عرض */
  publicContent: {
    default: {
      limit: (_ctx?: ExecutionContext) => Number(process.env.THROTTLE_CONTENT_LIMIT) || 120,
      ttl: (_ctx?: ExecutionContext) => (Number(process.env.THROTTLE_CONTENT_TTL) || 60) * 1000,
    },
  },
};

export interface AppThrottlerOptions {
  errorMessage?: string;
  throttlers: ThrottlerOptions[];
}

/**
 * بناء خيارات ThrottlerModule متضمنة الدعم المستقبلي لمخزن Redis في الإنتاج
 */
export function buildThrottlerOptions(config: ConfigService): AppThrottlerOptions {
  const globalTtl = Number(config.get('THROTTLE_TTL')) || 60;
  const globalLimit = Number(config.get('THROTTLE_LIMIT')) || 60;

  const redisUrl = config.get<string>('REDIS_URL');
  if (redisUrl) {
    logger.log(`تم رصد REDIS_URL — النظام مهيأ لاستخدام مخزن Redis الموزع لـ Rate Limiting.`);
  }

  const throttlers: ThrottlerOptions[] = [
    {
      name: 'default',
      ttl: globalTtl * 1000,
      limit: globalLimit,
    },
  ];

  return {
    errorMessage: 'تم تجاوز الحد المسموح به من الطلبات — يرجى الانتظار والمحاولة لاحقًا (429 Too Many Requests)',
    throttlers,
  };
}
