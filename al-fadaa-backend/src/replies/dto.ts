import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReplyStatus } from '@prisma/client';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MinLength,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

export class CreateReplyDto {
  @ApiProperty({ description: 'المراسلة المراد الرد عليها (UUID)' })
  @IsUUID('4', { message: 'معرف المراسلة غير صالح' })
  correspondenceId!: string;

  @ApiPropertyOptional({ description: 'التكليف المرتبط (UUID) — إن وُجد' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف التكليف غير صالح' })
  taskId?: string;

  @ApiProperty({ description: 'نص الرد (المسودة)' })
  @IsString({ message: 'نص الرد يجب أن يكون نصًا' })
  @MinLength(10, { message: 'نص الرد قصير جدًا (10 أحرف على الأقل)' })
  body!: string;
}

export class DirectReplyDto {
  @ApiProperty({ description: 'المراسلة المراد الرد عليها (UUID)' })
  @IsUUID('4', { message: 'معرف المراسلة غير صالح' })
  correspondenceId!: string;

  @ApiProperty({ description: 'نص الرد المباشر' })
  @IsString({ message: 'نص الرد يجب أن يكون نصًا' })
  @MinLength(10, { message: 'نص الرد قصير جدًا (10 أحرف على الأقل)' })
  body!: string;

  @ApiPropertyOptional({ description: 'معرفات المرفقات المرتبطة بالرد المباشر' })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true, message: 'معرف المرفق يجب أن يكون UUID صالح' })
  attachmentIds?: string[];
}

export class UpdateReplyDto {
  @ApiProperty({ description: 'نص الرد المعدَّل' })
  @IsString()
  @MinLength(10, { message: 'نص الرد قصير جدًا (10 أحرف على الأقل)' })
  body!: string;
}

export class RejectReplyDto {
  @ApiProperty({ description: 'سبب الرفض — يصل للموظف لتعديل المسودة', example: 'أضف الجدول الزمني للتنفيذ' })
  @IsString({ message: 'سبب الرفض يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'سبب الرفض مطلوب' })
  note!: string;
}

export class RepliesQueryDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'تصفية بحسب المراسلة (UUID)' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف المراسلة غير صالح' })
  correspondenceId?: string;

  @ApiPropertyOptional({ enum: ReplyStatus, description: 'تصفية بحسب الحالة' })
  @IsOptional()
  @IsEnum(ReplyStatus, { message: 'الحالة غير صالحة' })
  status?: ReplyStatus;
}
