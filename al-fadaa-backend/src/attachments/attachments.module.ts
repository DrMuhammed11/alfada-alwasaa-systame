import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { AttachmentsController } from './attachments.controller';
import { AttachmentsService } from './attachments.service';

@Module({
  imports: [CorrespondencesModule],
  controllers: [AttachmentsController],
  providers: [AttachmentsService],
})
export class AttachmentsModule {}
