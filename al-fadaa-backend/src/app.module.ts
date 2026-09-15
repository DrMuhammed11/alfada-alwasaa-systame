import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { buildThrottlerOptions } from './common/throttler/throttler-config';
import { PrismaModule } from './prisma/prisma.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DepartmentsModule } from './departments/departments.module';
import { CorrespondencesModule } from './correspondences/correspondences.module';
import { ReferralsModule } from './referrals/referrals.module';
import { TasksModule } from './tasks/tasks.module';
import { RepliesModule } from './replies/replies.module';
import { AttachmentsModule } from './attachments/attachments.module';
import { MailModule } from './mail/mail.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OutboxModule } from './outbox/outbox.module';
import { AdminModule } from './admin/admin.module';
import { SlaModule } from './sla/sla.module';
import { DelegationModule } from './delegation/delegation.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { PermissionsGuard } from './common/guards/permissions.guard';
import { HealthController } from './health.controller';

import { validateEnv } from './common/config/env.validation';

@Module({
  imports: [
    // متغيرات البيئة متاحة عالميًا مع التحقق الصارم من صحتها واكتمالها
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    // تحديد معدل الطلبات لحماية النظام من الإغراق وهجمات الحرمان من الخدمة
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: buildThrottlerOptions,
    }),
    // وحدات عامة (Global)
    PrismaModule,
    AuditModule,
    NotificationsModule,
    OutboxModule,
    SlaModule,
    AdminModule,
    DelegationModule,
    // وحدات الأعمال
    AuthModule,
    UsersModule,
    DepartmentsModule,
    CorrespondencesModule,
    ReferralsModule,
    TasksModule,
    RepliesModule,
    AttachmentsModule,
    MailModule,
  ],
  controllers: [HealthController],
  providers: [
    // الحارس الأول: تحديد معدل الطلبات قبل أي معالجة ثقيلة
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    // الحارسان العامان — الترتيب مهم: توثيق أولاً ثم الصلاحيات
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
  ],
})
export class AppModule {}
