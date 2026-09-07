import { Global, Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OutboxService } from './outbox.service';
import { OutboxProcessor } from './outbox.processor';

@Global()
@Module({
  imports: [
    ScheduleModule.forRoot(),
    PrismaModule,
    AuditModule,
    NotificationsModule,
  ],
  providers: [OutboxService, OutboxProcessor],
  exports: [OutboxService, OutboxProcessor],
})
export class OutboxModule {}
