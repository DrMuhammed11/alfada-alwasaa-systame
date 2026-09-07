import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter } from 'events';

export interface SsePubSubMessage {
  userIds: string[];
  event: string;
  data: unknown;
  senderInstanceId: string;
  timestamp: number;
}

export type SseMessageHandler = (msg: SsePubSubMessage) => void;

/**
 * وسيط البث الموزع لاتصالات SSE (Pub/Sub Broker).
 * يتيح بث الأحداث الحية لجميع الخوادم الموزعة (Cluster Nodes) في حال تشغيل النظام على عدة نُسخ.
 * - في بيئة الإنتاج مع Redis: يُنشر الحدث عبر Redis Pub/Sub ليصل لكل المستخدمين المتصلين بأي نسخة.
 * - في بيئة التطوير أو عند غياب Redis: يسقط تلقائياً على وسيط الذاكرة المحلي (In-Memory Fallback) بدون أي أخطاء.
 */
@Injectable()
export class SsePubSubService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('SsePubSub');
  private readonly emitter = new EventEmitter();
  private readonly handlers: SseMessageHandler[] = [];
  readonly instanceId = `node-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
  private readonly CHANNEL = 'al-fadaa:sse:events';

  private redisClient: any = null;
  private redisSubscriber: any = null;
  private isUsingRedis = false;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const redisUrl = this.config.get<string>('REDIS_URL');
    const redisHost = this.config.get<string>('REDIS_HOST');

    if (redisUrl || redisHost) {
      try {
        await this.initRedis(redisUrl || redisHost!);
      } catch (err) {
        this.logger.warn(
          `تعذّر الاتصال بخادم Redis (${(err as Error).message}) — تم تفعيل وسيط الذاكرة المحلي (In-Memory) تلقائياً`,
        );
        this.isUsingRedis = false;
      }
    } else {
      this.logger.log(
        `لم يتم ضبط REDIS_URL/REDIS_HOST — وسيط SSE يعمل بنمط الذاكرة المحلي (In-Memory Pub/Sub) بنجاح`,
      );
    }
  }

  private async initRedis(endpoint: string): Promise<void> {
    try {
      // محاولة استيراد ioredis بشكل ديناميكي إذا كانت الحزمة متوفرة
      // @ts-ignore
      const RedisModule = await import('ioredis').catch(() => null);
      if (RedisModule && (RedisModule.default || RedisModule)) {
        const RedisConstructor = RedisModule.default || RedisModule;
        this.redisClient = new RedisConstructor(endpoint, {
          lazyConnect: true,
          retryStrategy: () => null, // عدم التعليق عند الفشل
        });
        this.redisSubscriber = new RedisConstructor(endpoint, {
          lazyConnect: true,
          retryStrategy: () => null,
        });

        await Promise.all([this.redisClient.connect(), this.redisSubscriber.connect()]);

        await this.redisSubscriber.subscribe(this.CHANNEL);
        this.redisSubscriber.on('message', (channel: string, messageStr: string) => {
          if (channel === this.CHANNEL) {
            this.dispatchRaw(messageStr);
          }
        });

        this.isUsingRedis = true;
        this.logger.log(`تم الاتصال بـ Redis بنجاح وتفعيل البث العنقودي SSE عبر القناة [${this.CHANNEL}]`);
        return;
      }
    } catch {
      // حزمة ioredis غير مثبتة أو فشل الاتصال — التراجع التلقائي للذاكرة
    }

    this.logger.log(
      `حزمة Redis غير مثبتة أو الخادم غير متاح — يتم استخدام وسيط الذاكرة المحلي (In-Memory)`,
    );
    this.isUsingRedis = false;
  }

  onModuleDestroy(): void {
    if (this.redisSubscriber) {
      try { this.redisSubscriber.disconnect(); } catch {}
    }
    if (this.redisClient) {
      try { this.redisClient.disconnect(); } catch {}
    }
    this.emitter.removeAllListeners();
    this.handlers.length = 0;
  }

  /**
   * تسجيل مستمع للأحداث الواردة (تستدعيه خدمة SseConnectionsService)
   */
  subscribe(handler: SseMessageHandler): void {
    this.handlers.push(handler);
    this.emitter.on('event', handler);
  }

  /**
   * نشر حدث لمجموعة من المستخدمين عبر الوسيط
   */
  async publish(userIds: string[], event: string, data: unknown): Promise<void> {
    const msg: SsePubSubMessage = {
      userIds,
      event,
      data,
      senderInstanceId: this.instanceId,
      timestamp: Date.now(),
    };

    if (this.isUsingRedis && this.redisClient) {
      try {
        await this.redisClient.publish(this.CHANNEL, JSON.stringify(msg));
        return;
      } catch (err) {
        this.logger.warn(`فشل النشر عبر Redis، التحويل للوسيط المحلي: ${(err as Error).message}`);
      }
    }

    // الوضع المحلي (In-Memory)
    this.emitter.emit('event', msg);
  }

  /** توزيع الرسالة القادمة من Redis على المستمعين المحليين */
  private dispatchRaw(raw: string): void {
    try {
      const msg: SsePubSubMessage = JSON.parse(raw);
      this.emitter.emit('event', msg);
    } catch (e) {
      this.logger.error(`تعذّر تحليل رسالة SSE الواردة: ${(e as Error).message}`);
    }
  }

  /** هل وسيط Redis نشط حالياً؟ */
  get isRedisConnected(): boolean {
    return this.isUsingRedis;
  }

  /** عدد المستمعين النشطين */
  get subscriberCount(): number {
    return this.handlers.length;
  }
}
