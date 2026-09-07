import { ArrayNotEmpty, IsArray, IsEnum, IsInt, IsNotEmpty, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { Priority, Role } from '@prisma/client';

export class ApprovalWorkflowStepDto {
  @IsInt()
  @Min(1)
  level: number;

  @IsEnum(Role, { message: 'الدور المطلوب يجب أن يكون دورًا نظاميًا صالحًا' })
  @IsNotEmpty({ message: 'الدور المطلوب للاعتماد إلزامي' })
  requiredRole: Role;
}

export class UpdateApprovalWorkflowDto {
  @IsEnum(Priority, { message: 'درجة الأولوية يجب أن تكون صالحة (LOW, NORMAL, HIGH, URGENT)' })
  @IsNotEmpty()
  priority: Priority;

  @IsArray()
  @ArrayNotEmpty({ message: 'يجب تحديد خطوة اعتماد واحدة على الأقل' })
  @ValidateNested({ each: true })
  @Type(() => ApprovalWorkflowStepDto)
  steps: ApprovalWorkflowStepDto[];
}
