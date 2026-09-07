import { Module } from '@nestjs/common';
import { CorrespondencesController } from './correspondences.controller';
import { CorrespondencesService } from './correspondences.service';
import { RefNumberService } from './ref-number.service';

/**
 * وحدة المراسلات — تُصدِّر خدمتيها لأن بقية الوحدات
 * (الإحالات / التكليفات / الردود / المرفقات) تعتمد عليهما:
 *  - CorrespondencesService : فحص نطاق الرؤية + عمليات المراسلة
 *  - RefNumberService       : توليد الأرقام المرجعية
 */
@Module({
  controllers: [CorrespondencesController],
  providers: [CorrespondencesService, RefNumberService],
  exports: [CorrespondencesService, RefNumberService],
})
export class CorrespondencesModule {}
