import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { TaskStatus } from '@prisma/client';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';
import { PaginationDto } from '../common/dto/pagination.dto';

export class CreateTaskDto {
  @ApiProperty({ description: 'عنوان التكليف', example: 'إعداد رد بخصوص موعد التسليم' })
  @IsString({ message: 'عنوان التكليف يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'عنوان التكليف مطلوب' })
  title!: string;

  @ApiPropertyOptional({ description: 'وصف التكليف' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'الموظف المكلَّف (UUID)' })
  @IsUUID('4', { message: 'معرف الموظف غير صالح' })
  assignedToId!: string;

  @ApiPropertyOptional({ description: 'الموعد النهائي (ISO)' })
  @IsOptional()
  @IsDateString({}, { message: 'صيغة التاريخ غير صالحة' })
  dueDate?: string;

  @ApiPropertyOptional({ description: 'الإحالة المرتبطة (UUID) — إن وجدت' })
  @IsOptional()
  @IsUUID('4', { message: 'معرف الإحالة غير صالح' })
  referralId?: string;
}

export class UpdateTaskDto {
  @ApiPropertyOptional({ description: 'العنوان' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ description: 'الوصف' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'الموعد النهائي (ISO)' })
  @IsOptional()
  @IsDateString({}, { message: 'صيغة التاريخ غير صالحة' })
  dueDate?: string;
}

export class UpdateTaskStatusDto {
  @ApiProperty({
    enum: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED, TaskStatus.DONE],
    description: 'الحالة الجديدة',
  })
  @IsEnum(TaskStatus, { message: 'الحالة غير صالحة' })
  status!: TaskStatus;

  @ApiPropertyOptional({ description: 'تقرير أو ملخص الإنجاز' })
  @IsOptional()
  @IsString()
  completionNote?: string;
}

export class TasksQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: TaskStatus, description: 'تصفية بحسب الحالة' })
  @IsOptional()
  @IsEnum(TaskStatus, { message: 'الحالة غير صالحة' })
  status?: TaskStatus;
}
