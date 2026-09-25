import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  CorrespondenceStatus,
  CorrespondenceType,
  Priority,
} from '@prisma/client';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { PaginationDto } from '../common/dto/pagination.dto';
import { IsRealDate } from '../common/utils/dates';

export class CreateIncomingDto {
  @ApiProperty({ description: 'موضوع المراسلة', example: 'طلب عرض سعر لأعمال الكهرباء' })
  @IsString({ message: 'الموضوع يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'موضوع المراسلة مطلوب' })
  subject!: string;

  @ApiPropertyOptional({ description: 'نص المراسلة (محتوى البريد)' })
  @IsOptional()
  @IsString()
  body?: string;

  @ApiProperty({ description: 'اسم المرسل (العميل / الجهة)', example: 'شركة الأفق للمقاولات' })
  @IsString({ message: 'اسم المرسل مطلوب' })
  @IsNotEmpty({ message: 'اسم المرسل مطلوب' })
  senderName!: string;

  @ApiPropertyOptional({ description: 'بريد المرسل — سيُرسل إليه الرد لاحقًا', example: 'info@client.com' })
  @IsOptional()
  @IsEmail({}, { message: 'بريد المرسل غير صالح' })
  senderEmail?: string;

  @ApiPropertyOptional({ description: 'هاتف المرسل' })
  @IsOptional()
  @IsString()
  senderPhone?: string;

  @ApiPropertyOptional({ enum: Priority, description: 'الأهمية', default: Priority.NORMAL })
  @IsOptional()
  @IsEnum(Priority, { message: 'الأهمية غير صالحة' })
  priority?: Priority;

  @ApiPropertyOptional({
    description: 'تاريخ الاستلام (YYYY-MM-DD أو ISO كامل) — الافتراضي: الآن',
    example: '2026-09-01T10:30:00Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة التاريخ غير صالحة' })
  receivedAt?: string;

  @ApiPropertyOptional({ description: 'معرف رأس الرسالة Message-ID' })
  @IsOptional()
  @IsString()
  messageId?: string;

  @ApiPropertyOptional({ description: 'قناة الاستلام: email | website | fax | hand', example: 'email' })
  @IsOptional()
  @IsString()
  channel?: string;
}

export class CreateInternalDto {
  @ApiProperty({ description: 'موضوع التعميم', example: 'تعميم بخصوص ساعات العمل الرمضانية' })
  @IsString()
  @IsNotEmpty({ message: 'موضوع التعميم مطلوب' })
  subject!: string;

  @ApiProperty({ description: 'نص التعميم' })
  @IsString()
  @MinLength(5, { message: 'نص التعميم قصير جدًا' })
  body!: string;

  @ApiPropertyOptional({ enum: Priority, description: 'الأهمية' })
  @IsOptional()
  @IsEnum(Priority, { message: 'الأهمية غير صالحة' })
  priority?: Priority;
}

export class UpdateCorrespondenceDto {
  @ApiPropertyOptional({ description: 'الموضوع' })
  @IsOptional()
  @IsString()
  subject?: string;

  @ApiPropertyOptional({ description: 'النص' })
  @IsOptional()
  @IsString()
  body?: string;

  @ApiPropertyOptional({ enum: Priority, description: 'الأهمية' })
  @IsOptional()
  @IsEnum(Priority, { message: 'الأهمية غير صالحة' })
  priority?: Priority;

  @ApiPropertyOptional({ description: 'اسم المرسل' })
  @IsOptional()
  @IsString()
  senderName?: string;

  @ApiPropertyOptional({ description: 'بريد المرسل' })
  @IsOptional()
  @IsEmail({}, { message: 'بريد المرسل غير صالح' })
  senderEmail?: string;

  @ApiPropertyOptional({ description: 'هاتف المرسل' })
  @IsOptional()
  @IsString()
  senderPhone?: string;

  @ApiPropertyOptional({
    enum: [CorrespondenceStatus.UNDER_REVIEW],
    description: 'وسم المراسلة «قيد الدراسة» (من RECEIVED فقط — يتحقق منه الخادم)',
  })
  @IsOptional()
  @IsEnum(CorrespondenceStatus, { message: 'الحالة غير صالحة' })
  status?: CorrespondenceStatus;
}

export class CorrespondencesQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: CorrespondenceType, description: 'النوع: وارد / صادر / داخلي' })
  @IsOptional()
  @IsEnum(CorrespondenceType, { message: 'النوع غير صالح' })
  type?: CorrespondenceType;

  @ApiPropertyOptional({ enum: CorrespondenceStatus, description: 'الحالة' })
  @IsOptional()
  @IsEnum(CorrespondenceStatus, { message: 'الحالة غير صالحة' })
  status?: CorrespondenceStatus;

  @ApiPropertyOptional({ enum: Priority, description: 'الأهمية' })
  @IsOptional()
  @IsEnum(Priority, { message: 'الأهمية غير صالحة' })
  priority?: Priority;

  @ApiPropertyOptional({ description: 'تصفية بحسب القسم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string;

  @ApiPropertyOptional({ description: 'تصفية بحسب قناة الوصول: website | email | fax | hand' })
  @IsOptional()
  @IsString()
  @MaxLength(50, { message: 'القناة طويلة جدًا' })
  channel?: string;

  @ApiPropertyOptional({
    description: 'بحث نصي في (الموضوع / الرقم المرجعي / اسم المرسل)',
    example: 'عرض سعر',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200, { message: 'نص البحث طويل جدًا (200 حرف كحد أقصى)' })
  q?: string;
}

export class PublicInquiryDto {
  @ApiProperty({ description: 'الاسم الكامل أو اسم الجهة', example: 'م. فهد العتيبي' })
  @IsString({ message: 'الاسم مطلوب' })
  @IsNotEmpty({ message: 'الاسم مطلوب' })
  name!: string;

  @ApiProperty({ description: 'رقم الهاتف / الجوال للتواصل', example: '777123456' })
  @IsString({ message: 'رقم الهاتف مطلوب' })
  @IsNotEmpty({ message: 'رقم الهاتف مطلوب' })
  phone!: string;

  @ApiPropertyOptional({ description: 'البريد الإلكتروني للعميل', example: 'client@example.com' })
  @IsOptional()
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email?: string;

  @ApiProperty({ description: 'المجال أو الخدمة المطلوبة', example: 'خدمات الاتصالات وتقنية المعلومات' })
  @IsString({ message: 'الخدمة المطلوبة يجب أن تكون نصًا' })
  @IsNotEmpty({ message: 'الخدمة المطلوبة مطلوبة' })
  service!: string;

  @ApiPropertyOptional({ description: 'تفاصيل المشروع أو الاستفسار' })
  @IsOptional()
  @IsString()
  message?: string;
}

export class SearchCorrespondencesDto extends PaginationDto {
  @ApiPropertyOptional({
    description: 'نص البحث الشامل (في الموضوع والمحتوى والردود والملاحظات والمرسل)',
    example: 'عقد توريد',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200, { message: 'نص البحث طويل جدًا (200 حرف كحد أقصى)' })
  q?: string;

  @ApiPropertyOptional({ enum: CorrespondenceType, description: 'النوع: وارد / صادر / داخلي' })
  @IsOptional()
  @IsEnum(CorrespondenceType, { message: 'النوع غير صالح' })
  type?: CorrespondenceType;

  @ApiPropertyOptional({ enum: CorrespondenceStatus, description: 'الحالة' })
  @IsOptional()
  @IsEnum(CorrespondenceStatus, { message: 'الحالة غير صالحة' })
  status?: CorrespondenceStatus;

  @ApiPropertyOptional({ enum: Priority, description: 'الأهمية' })
  @IsOptional()
  @IsEnum(Priority, { message: 'الأهمية غير صالحة' })
  priority?: Priority;

  @ApiPropertyOptional({ description: 'تصفية بحسب القسم (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف القسم غير صالح' })
  departmentId?: string;

  @ApiPropertyOptional({ description: 'تصفية بحسب قناة الوصول: website | email | fax | hand' })
  @IsOptional()
  @IsString()
  @MaxLength(50, { message: 'القناة طويلة جدًا' })
  channel?: string;

  @ApiPropertyOptional({
    description: 'تاريخ البداية (YYYY-MM-DD أو ISO كامل)',
    example: '2026-01-01T00:00:00Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة تاريخ البداية غير صالحة' })
  from?: string;

  @ApiPropertyOptional({
    description: 'تاريخ النهاية (YYYY-MM-DD يشمل كامل اليوم، أو ISO كامل)',
    example: '2026-12-31T23:59:59Z',
  })
  @IsOptional()
  @IsRealDate({ message: 'صيغة تاريخ النهاية غير صالحة' })
  to?: string;

  @ApiPropertyOptional({ description: 'هل تحتوي على مرفقات؟ — تقبل true/false فقط' })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === true || value === 'true') return true;
    if (value === false || value === 'false') return false;
    return undefined; // أي قيمة أخرى تُتجاهل بدل انقلاب الفلتر عكس مقصود المستخدم
  })
  hasAttachments?: boolean;
}


