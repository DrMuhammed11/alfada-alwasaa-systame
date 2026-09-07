import { ApiPropertyOptional } from '@nestjs/swagger';
import { NotificationType } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

/** استعلام صندوق إشعاراتي — تصفية وتقسيم صفحات */
export class NotificationsQueryDto extends PaginationDto {
  @ApiPropertyOptional({
    description: 'الإشعارات غير المقروءة فقط',
    example: true,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true || value === 1)
  @IsBoolean({ message: 'قيمة unreadOnly يجب أن تكون منطقية' })
  unreadOnly?: boolean = false;

  @ApiPropertyOptional({
    enum: NotificationType,
    description: 'تصفية بحسب نوع الإشعار',
  })
  @IsOptional()
  @IsEnum(NotificationType, { message: 'نوع الإشعار غير صالح' })
  type?: NotificationType;
}
