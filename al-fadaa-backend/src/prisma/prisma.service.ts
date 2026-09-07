import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/** غلاف Prisma Client بدورة حياة NestJS — يُستخدم في كل الخدمات عبر الحقن */
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger('Prisma');

  constructor() {
    super({
      log: process.env.NODE_ENV === 'production' ? ['error'] : ['warn', 'error'],
    });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
    this.logger.log('تم الاتصال بقاعدة البيانات بنجاح');
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
