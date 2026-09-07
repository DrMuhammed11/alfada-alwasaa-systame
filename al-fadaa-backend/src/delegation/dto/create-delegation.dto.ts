import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateDelegationDto {
  @IsUUID('4', { message: 'معرف الوكيل المفوَّض إليه يجب أن يكون UUID صالحًا' })
  @IsNotEmpty({ message: 'معرف الوكيل مطلوب' })
  delegateId: string;

  @IsNotEmpty({ message: 'تاريخ بدء التفويض مطلوب' })
  startsAt: string;

  @IsNotEmpty({ message: 'تاريخ انتهاء التفويض مطلوب' })
  endsAt: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsUUID('4')
  delegatorId?: string; // للأدمن عند إنشاء تفويض نيابة عن مستخدم آخر
}
