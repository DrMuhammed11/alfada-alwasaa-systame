import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsUUID } from 'class-validator';
import { IsRealDate } from '../../common/utils/dates';

export class AdminAnalyticsQueryDto {
  @ApiPropertyOptional({
    description: 'الفترة الزمنية للإحصائيات: 7d | 30d | 90d | year | all',
    example: '30d',
    default: '30d',
  })
  @IsOptional()
  @IsIn(['7d', '30d', '90d', 'year', 'all'], {
    message: 'الفترة غير صالحة، الخيارات: 7d, 30d, 90d, year, all',
  })
  period?: '7d' | '30d' | '90d' | 'year' | 'all';

  @ApiPropertyOptional({
    description: 'تاريخ بداية مخصص (YYYY-MM-DD أو ISO كامل)',
    example: '2026-01-01T00:00:00Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة تاريخ البداية غير صالحة' })
  from?: string;

  @ApiPropertyOptional({
    description: 'تاريخ نهاية مخصص (YYYY-MM-DD يشمل كامل اليوم، أو ISO كامل)',
    example: '2026-12-31T23:59:59Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة تاريخ النهاية غير صالحة' })
  to?: string;

  @ApiPropertyOptional({ description: 'تصفية إحصائيات قسم معين (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string;
}
