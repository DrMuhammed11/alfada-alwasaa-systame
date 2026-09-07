import { Module } from '@nestjs/common';
import { MailService } from './mail.service';
import { IncomingMailService } from './incoming-mail.service';
import { IncomingMailAttachmentService } from './incoming-mail-attachment.service';
import { IncomingMailMatcherService } from './incoming-mail-matcher.service';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { MailController } from './mail.controller';

@Module({
  imports: [CorrespondencesModule],
  controllers: [MailController],
  providers: [
    MailService,
    IncomingMailService,
    IncomingMailAttachmentService,
    IncomingMailMatcherService,
  ],
  exports: [
    MailService,
    IncomingMailService,
    IncomingMailAttachmentService,
    IncomingMailMatcherService,
  ],
})
export class MailModule {}
