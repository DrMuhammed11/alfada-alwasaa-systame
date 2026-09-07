import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { MailModule } from '../mail/mail.module';
import { RepliesController } from './replies.controller';
import { RepliesService } from './replies.service';

@Module({
  imports: [CorrespondencesModule, MailModule],
  controllers: [RepliesController],
  providers: [RepliesService],
})
export class RepliesModule {}
