import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

/** حقول مشتركة للترتيب والتفعيل */
class OrderingFields {
  @ApiPropertyOptional({ description: 'ترتيب العرض (الأصغر أولًا)', default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'الترتيب يجب أن يكون رقمًا' })
  @Min(0, { message: 'الترتيب لا يقبل قيمًا سالبة' })
  order?: number;

  @ApiPropertyOptional({ description: 'مفعّل للعرض في الموقع؟', default: true })
  @IsOptional()
  @IsBoolean({ message: 'التفعيل يجب أن يكون true أو false' })
  isActive?: boolean;
}

export class CreateSiteServiceDto {
  @ApiProperty({ description: 'المعرف في روابط الموقع', example: 'contracting' })
  @IsString({ message: 'المعرف يجب أن يكون نصًا' })
  @MaxLength(60, { message: 'المعرف طويل جدًا' })
  slug!: string;

  @ApiProperty({ description: 'الاسم بالعربية' })
  @IsString({ message: 'الاسم العربي مطلوب' })
  @MaxLength(200, { message: 'الاسم العربي طويل جدًا' })
  titleAr!: string;

  @ApiProperty({ description: 'الاسم بالإنجليزية' })
  @IsString({ message: 'الاسم الإنجليزي مطلوب' })
  @MaxLength(200, { message: 'الاسم الإنجليزي طويل جدًا' })
  titleEn!: string;

  @ApiPropertyOptional({ description: 'وصف مختصر بالعربية' })
  @IsOptional()
  @IsString()
  @MaxLength(1000, { message: 'الوصف المختصر طويل جدًا' })
  shortAr?: string;

  @ApiPropertyOptional({ description: 'وصف مختصر بالإنجليزية' })
  @IsOptional()
  @IsString()
  @MaxLength(1000, { message: 'الوصف المختصر طويل جدًا' })
  shortEn?: string;

  @ApiPropertyOptional({ description: 'الوصف الكامل بالعربية' })
  @IsOptional()
  @IsString()
  @MaxLength(20000, { message: 'الوصف الكامل طويل جدًا' })
  fullAr?: string;

  @ApiPropertyOptional({ description: 'الوصف الكامل بالإنجليزية' })
  @IsOptional()
  @IsString()
  @MaxLength(20000, { message: 'الوصف الكامل طويل جدًا' })
  fullEn?: string;

  @ApiPropertyOptional({ description: 'اسم أيقونة lucide', example: 'HardHat' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  icon?: string;

  @ApiPropertyOptional({ description: 'مسار الصورة الرئيسية', example: '/profile/construction_building.webp' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  image?: string;

  @ApiPropertyOptional({ description: 'مزايا الخدمة (مصفوفة نصوص)', type: [String] })
  @IsOptional()
  @IsArray({ message: 'المزايا يجب أن تكون مصفوفة' })
  features?: string[];

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** تحديث الخدمة — كل الحقول اختيارية، ويُمنع تغيير المعرّف */
export class UpdateSiteServiceDto extends OrderingFields {
  @IsOptional()
  @IsString()
  @MaxLength(60)
  slug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  shortAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  shortEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20000)
  fullAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20000)
  fullEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  icon?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  image?: string;

  @IsOptional()
  @IsArray()
  features?: string[];
}

export class CreateSiteSectorDto {
  @ApiProperty({ description: 'اسم القطاع بالعربية' })
  @IsString({ message: 'اسم القطاع العربي مطلوب' })
  @MaxLength(200)
  titleAr!: string;

  @ApiProperty({ description: 'اسم القطاع بالإنجليزية' })
  @IsString({ message: 'اسم القطاع الإنجليزي مطلوب' })
  @MaxLength(200)
  titleEn!: string;

  @ApiPropertyOptional({ description: 'وصف القطاع بالعربية' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descAr?: string;

  @ApiPropertyOptional({ description: 'وصف القطاع بالإنجليزية' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descEn?: string;

  @ApiPropertyOptional({ description: 'اسم أيقونة lucide' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  icon?: string;

  @ApiPropertyOptional({ description: 'خدمات القطاع (مصفوفة نصوص)', type: [String] })
  @IsOptional()
  @IsArray()
  services?: string[];

  @ApiPropertyOptional({
    description: 'صور القطاع [{src, alt}]',
    type: 'object',
    additionalProperties: true,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  photos?: { src: string; alt?: string }[];

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateSiteSectorDto extends OrderingFields {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  icon?: string;

  @IsOptional()
  @IsArray()
  services?: string[];

  @IsOptional()
  @IsArray()
  photos?: { src: string; alt?: string }[];
}

export class CreateSiteProjectDto {
  @ApiProperty({ description: 'عنوان المشروع بالعربية' })
  @IsString({ message: 'عنوان المشروع مطلوب' })
  @MaxLength(200)
  titleAr!: string;

  @ApiProperty({ description: 'عنوان المشروع بالإنجليزية' })
  @IsString({ message: 'عنوان المشروع الإنجليزي مطلوب' })
  @MaxLength(200)
  titleEn!: string;

  @ApiPropertyOptional({ description: 'التصنيف بالعربية', example: 'مقاولات وأعمال مدنية' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  tagAr?: string;

  @ApiPropertyOptional({ description: 'التصنيف بالإنجليزية' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  tagEn?: string;

  @ApiPropertyOptional({ description: 'نطاق العمل ووصف المشروع بالعربية' })
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  scopeAr?: string;

  @ApiPropertyOptional({ description: 'نطاق العمل بالإنجليزية' })
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  scopeEn?: string;

  @ApiPropertyOptional({ description: 'مؤشرات المشروع (مصفوفة نصوص)', type: [String] })
  @IsOptional()
  @IsArray()
  metrics?: string[];

  @ApiPropertyOptional({ description: 'مسار صورة المشروع' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  image?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateSiteProjectDto extends OrderingFields {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  tagAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  tagEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10000)
  scopeAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10000)
  scopeEn?: string;

  @IsOptional()
  @IsArray()
  metrics?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(300)
  image?: string;
}

export class CreateSiteFaqDto {
  @ApiProperty({ description: 'السؤال بالعربية' })
  @IsString({ message: 'السؤال مطلوب' })
  @MaxLength(500)
  questionAr!: string;

  @ApiProperty({ description: 'السؤال بالإنجليزية' })
  @IsString({ message: 'السؤال الإنجليزي مطلوب' })
  @MaxLength(500)
  questionEn!: string;

  @ApiProperty({ description: 'الجواب بالعربية' })
  @IsString({ message: 'الجواب مطلوب' })
  @MaxLength(5000)
  answerAr!: string;

  @ApiProperty({ description: 'الجواب بالإنجليزية' })
  @IsString({ message: 'الجواب الإنجليزي مطلوب' })
  @MaxLength(5000)
  answerEn!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateSiteFaqDto extends OrderingFields {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  questionAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  questionEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  answerAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  answerEn?: string;
}

export class UpsertSiteSettingDto {
  @ApiProperty({
    description: 'محتوى الإعداد ككائن JSON حر',
    type: 'object',
    additionalProperties: true,
  })
  value!: unknown;

  @ApiPropertyOptional({ description: 'شرح عربي لما يحويه المفتاح' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  description?: string;
}
