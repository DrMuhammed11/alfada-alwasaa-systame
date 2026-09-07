import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

export class CreateDepartmentDto {
  @ApiProperty({ description: 'اسم القسم', example: 'قسم المشتريات' })
  @IsString({ message: 'اسم القسم يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'اسم القسم مطلوب' })
  name!: string;

  @ApiProperty({
    description: 'رمز القسم (فريد — حروف إنجليزية كبيرة)',
    example: 'PROC',
  })
  @IsString()
  @Matches(/^[A-Z]{2,10}$/, {
    message: 'رمز القسم: حروف إنجليزية كبيرة فقط (2-10 أحرف)',
  })
  code!: string;

  @ApiPropertyOptional({ description: 'معرف مدير القسم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف المدير غير صالح' })
  managerId?: string;
}

export class UpdateDepartmentDto {
  @ApiPropertyOptional({ description: 'اسم القسم' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'رمز القسم' })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Z]{2,10}$/, {
    message: 'رمز القسم: حروف إنجليزية كبيرة فقط (2-10 أحرف)',
  })
  code?: string;

  @ApiPropertyOptional({ description: 'معرف مدير القسم — أرسل null لإلغاء الربط' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف المدير غير صالح' })
  managerId?: string | null;
}

export class DepartmentsQueryDto extends PaginationDto {}
