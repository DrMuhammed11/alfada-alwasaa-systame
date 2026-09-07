import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
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

@Module({
  imports: [
    // متغيرات البيئة متاحة عالميًا
    ConfigModule.forRoot({ isGlobal: true }),
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
    // الحارسان العامان — الترتيب مهم: توثيق أولاً ثم الصلاحيات
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
  ],
})
export class AppModule {}
