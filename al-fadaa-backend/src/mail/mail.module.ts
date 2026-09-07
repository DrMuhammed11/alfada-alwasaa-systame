import { Module } from '@nestjs/common';
import { MailService } from './mail.service';
import { IncomingMailService } from './incoming-mail.service';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { MailController } from './mail.controller';

@Module({
  imports: [CorrespondencesModule],
  controllers: [MailController],
  providers: [MailService, IncomingMailService],
  exports: [MailService, IncomingMailService],
})
export class MailModule {}
