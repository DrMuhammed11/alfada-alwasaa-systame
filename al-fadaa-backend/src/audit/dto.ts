import { ApiPropertyOptional } from '@nestjs/swagger';
import { AuditAction } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

/** استعلام استعراض سجل التدقيق — تصفية وتقسيم صفحات */
export class AuditQueryDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'تصفية بحسب المستخدم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف المستخدم غير صالح' })
  userId?: string;

  @ApiPropertyOptional({
    enum: AuditAction,
    description: 'نوع الحدث: LOGIN / REFER / ASSIGN / SUBMIT / APPROVE / REJECT / SEND ...',
  })
  @IsOptional()
  @IsEnum(AuditAction, { message: 'نوع الحدث غير صالح' })
  action?: AuditAction;

  @ApiPropertyOptional({
    description: 'نوع الكيان: Correspondence / Reply / User / Task ...',
  })
  @IsOptional()
  @IsString()
  entityType?: string;

  @ApiPropertyOptional({ description: 'معرف الكيان (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف الكيان غير صالح' })
  entityId?: string;

  @ApiPropertyOptional({ description: 'من تاريخ (ISO 8601)', example: '2026-01-01T00:00:00Z' })
  @IsOptional()
  @IsDateString({}, { message: 'صيغة التاريخ غير صالحة' })
  from?: string;

  @ApiPropertyOptional({ description: 'إلى تاريخ (ISO 8601)' })
  @IsOptional()
  @IsDateString({}, { message: 'صيغة التاريخ غير صالحة' })
  to?: string;
}
