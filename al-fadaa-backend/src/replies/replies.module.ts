import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { MailModule } from '../mail/mail.module';
import { RepliesController } from './replies.controller';
import { RepliesService } from './replies.service';
import { RepliesApprovalService } from './replies-approval.service';
import { RepliesSendService } from './replies-send.service';

@Module({
  imports: [CorrespondencesModule, MailModule],
  controllers: [RepliesController],
  providers: [RepliesService, RepliesApprovalService, RepliesSendService],
  exports: [RepliesService, RepliesApprovalService, RepliesSendService],
})
export class RepliesModule {}
