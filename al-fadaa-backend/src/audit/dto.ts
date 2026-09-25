import { ApiPropertyOptional } from '@nestjs/swagger';
import { AuditAction } from '@prisma/client';
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';
import { IsRealDate } from '../common/utils/dates';

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

  @ApiPropertyOptional({
    description: 'من تاريخ (YYYY-MM-DD أو ISO 8601 كامل)',
    example: '2026-01-01T00:00:00Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة التاريخ غير صالحة' })
  from?: string;

  @ApiPropertyOptional({
    description: 'إلى تاريخ (YYYY-MM-DD يشمل كامل اليوم، أو ISO 8601 كامل)',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة التاريخ غير صالحة' })
  to?: string;

  @ApiPropertyOptional({
    description: 'بحث نصي حر في الإجراء، البيان، نوع الكيان، عنوان IP، البصمات التشفيرية، واسم/بريد المستخدم',
    example: 'LOGIN',
  })
  @IsOptional()
  @IsString({ message: 'البحث يجب أن يكون نصًا' })
  @MaxLength(200, { message: 'نص البحث طويل جدًا (200 حرف كحد أقصى)' })
  q?: string;
}
