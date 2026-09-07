import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MinLength,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

export class CreateUserDto {
  @ApiProperty({ description: 'الاسم الكامل', example: 'مهندس عمار' })
  @IsString({ message: 'الاسم يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'الاسم مطلوب' })
  name!: string;

  @ApiProperty({ description: 'البريد الإلكتروني (فريد)', example: 'eng.employee3@al-fadaa.com' })
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email!: string;

  @ApiProperty({ description: 'كلمة المرور المؤقتة (8 أحرف على الأقل)', example: 'Temp@12345' })
  @IsString()
  @MinLength(8, { message: 'كلمة المرور يجب أن تكون 8 أحرف على الأقل' })
  password!: string;

  @ApiProperty({ enum: Role, description: 'الدور الوظيفي', example: Role.EMPLOYEE })
  @IsEnum(Role, { message: 'الدور غير صالح' })
  role!: Role;

  @ApiPropertyOptional({ description: 'القسم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string;

  @ApiPropertyOptional({ description: 'المسمى الوظيفي', example: 'مهندس مدني' })
  @IsOptional()
  @IsString()
  jobTitle?: string;

  @ApiPropertyOptional({ description: 'رقم الهاتف', example: '0790000000' })
  @IsOptional()
  @IsString()
  phone?: string;
}

export class UpdateUserDto {
  @ApiPropertyOptional({ description: 'الاسم الكامل' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'البريد الإلكتروني' })
  @IsOptional()
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email?: string;

  @ApiPropertyOptional({ description: 'كلمة مرور جديدة (تُشفَّر تلقائيًا)' })
  @IsOptional()
  @IsString()
  @MinLength(8, { message: 'كلمة المرور يجب أن تكون 8 أحرف على الأقل' })
  password?: string;

  @ApiPropertyOptional({ enum: Role, description: 'الدور الوظيفي' })
  @IsOptional()
  @IsEnum(Role, { message: 'الدور غير صالح' })
  role?: Role;

  @ApiPropertyOptional({ description: 'القسم (UUID) — أرسل null لإلغاء الربط' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string | null;

  @ApiPropertyOptional({ description: 'المسمى الوظيفي' })
  @IsOptional()
  @IsString()
  jobTitle?: string;

  @ApiPropertyOptional({ description: 'رقم الهاتف' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ description: 'تفعيل / تعطيل الحساب' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UsersQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: Role, description: 'تصفية بحسب الدور' })
  @IsOptional()
  @IsEnum(Role, { message: 'الدور غير صالح' })
  role?: Role;

  @ApiPropertyOptional({ description: 'تصفية بحسب القسم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string;

  @ApiPropertyOptional({ description: 'تصفية بحسب حالة الحساب', example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
