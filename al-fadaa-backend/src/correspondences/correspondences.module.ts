import { Module } from '@nestjs/common';
import { CorrespondencesController } from './correspondences.controller';
import { CorrespondencesService } from './correspondences.service';
import { CorrespondencesQueryService } from './correspondences-query.service';
import { RefNumberService } from './ref-number.service';

/**
 * وحدة المراسلات — تُصدِّر خدماتها لأن بقية الوحدات
 * (الإحالات / التكليفات / الردود / المرفقات) تعتمد عليها:
 *  - CorrespondencesService      : عمليات الإنشاء والتعديل والأرشفة
 *  - CorrespondencesQueryService : فحص نطاق الرؤية + الاستعلامات
 *  - RefNumberService            : توليد الأرقام المرجعية
 */
@Module({
  controllers: [CorrespondencesController],
  providers: [CorrespondencesService, CorrespondencesQueryService, RefNumberService],
  exports: [CorrespondencesService, CorrespondencesQueryService, RefNumberService],
})
export class CorrespondencesModule {}
