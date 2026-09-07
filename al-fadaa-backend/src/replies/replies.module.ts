import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { MailModule } from '../mail/mail.module';
import { RepliesController } from './replies.controller';
import { RepliesService } from './replies.service';
import { RepliesApprovalService } from './replies-approval.service';
import { RepliesSendService } from './replies-send.service';
import { RepliesVersioningService } from './replies-versioning.service';

@Module({
  imports: [CorrespondencesModule, MailModule],
  controllers: [RepliesController],
  providers: [RepliesService, RepliesApprovalService, RepliesSendService, RepliesVersioningService],
  exports: [RepliesService, RepliesApprovalService, RepliesSendService, RepliesVersioningService],
})
export class RepliesModule {}
