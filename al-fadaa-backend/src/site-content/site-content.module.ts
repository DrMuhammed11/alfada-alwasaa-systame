import { Module } from '@nestjs/common';
import { SiteContentController } from './site-content.controller';
import { SiteContentService } from './site-content.service';

// خدمة التدقيق عامة (AuditModule @Global) — لا حاجة لاستيرادها
@Module({
  controllers: [SiteContentController],
  providers: [SiteContentService],
})
export class SiteContentModule {}
