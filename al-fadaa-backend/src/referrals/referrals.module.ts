import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { ReferralsController } from './referrals.controller';
import { ReferralsService } from './referrals.service';

@Module({
  imports: [CorrespondencesModule],
  controllers: [ReferralsController],
  providers: [ReferralsService],
})
export class ReferralsModule {}
