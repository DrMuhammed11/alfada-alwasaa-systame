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
  MaxLength,
  MinLength,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';
import { IsStrongPassword } from '../common/validation/password-policy';

export class CreateUserDto {
  @ApiProperty({ description: 'الاسم الكامل', example: 'مهندس عمار' })
  @IsString({ message: 'الاسم يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'الاسم مطلوب' })
  name!: string;

  @ApiProperty({ description: 'البريد الإلكتروني (فريد)', example: 'eng.employee3@al-fadaa.com' })
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email!: string;

  @ApiProperty({ description: 'كلمة المرور المؤقتة (10 خانات مع حرف كبير وصغير ورقم ورمز)', example: 'Temp@12345x' })
  @IsString()
  @MinLength(10, { message: 'كلمة المرور يجب أن تكون 10 أحرف على الأقل' })
  @IsStrongPassword()
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

  @ApiPropertyOptional({ description: 'كلمة مرور جديدة (تُشفَّر تلقائيًا وتُبطل جلسات المستخدم)' })
  @IsOptional()
  @IsString()
  @MinLength(10, { message: 'كلمة المرور يجب أن تكون 10 أحرف على الأقل' })
  @IsStrongPassword()
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

  @ApiPropertyOptional({
    description: 'بحث نصي حر في الاسم أو البريد الإلكتروني',
    example: 'أحمد',
  })
  @IsOptional()
  @IsString({ message: 'البحث يجب أن يكون نصًا' })
  @MaxLength(200, { message: 'نص البحث طويل جدًا (200 حرف كحد أقصى)' })
  search?: string;
}
