import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

/** أساس مشترك لكل استعلامات القوائم المقسّمة إلى صفحات */
export class PaginationDto {
  @ApiPropertyOptional({ description: 'رقم الصفحة (يبدأ من 1)', example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'رقم الصفحة يجب أن يكون رقمًا' })
  @Min(1, { message: 'رقم الصفحة يبدأ من 1' })
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'عدد النتائج في الصفحة (1 - 100)',
    example: 20,
    default: 20,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'عدد النتائج يجب أن يكون رقمًا' })
  @Min(1, { message: 'الحد الأدنى نتيجة واحدة' })
  @Max(100, { message: 'الحد الأقصى 100 نتيجة في الصفحة' })
  limit?: number = 20;
}

/** حساب معاملات التقسيم skip/take من الـ DTO */
export function pageParams(dto: PaginationDto): {
  page: number;
  limit: number;
  skip: number;
  take: number;
} {
  const page = dto.page ?? 1;
  const limit = dto.limit ?? 20;
  return { page, limit, skip: (page - 1) * limit, take: limit };
}
