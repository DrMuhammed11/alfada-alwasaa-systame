import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReferralStatus } from '@prisma/client';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

export class CreateReferralDto {
  @ApiProperty({ description: 'المستخدم المحال إليه (UUID) — نائب المدير أو مدير قسم' })
  @IsUUID('4', { message: 'معرف المستخدم غير صالح' })
  toUserId!: string;

  @ApiPropertyOptional({ description: 'ملاحظة الإحالة', example: 'للدراسة وإعداد الرد خلال يومي عمل' })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({ description: 'الموعد النهائي (ISO)', example: '2026-09-10T23:59:59Z' })
  @IsOptional()
  @IsDateString({}, { message: 'صيغة التاريخ غير صالحة' })
  dueDate?: string;
}

export class MyReferralsQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: ReferralStatus, description: 'تصفية بحسب الحالة' })
  @IsOptional()
  @IsEnum(ReferralStatus, { message: 'الحالة غير صالحة' })
  status?: ReferralStatus;
}
