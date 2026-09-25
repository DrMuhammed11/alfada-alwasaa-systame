import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import { IsStrongPassword } from '../common/validation/password-policy';

export class LoginDto {
  @ApiProperty({ description: 'البريد الإلكتروني للموظف', example: 'gm@al-fadaa.com' })
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email!: string;

  @ApiProperty({ description: 'كلمة المرور' })
  @IsNotEmpty({ message: 'كلمة المرور مطلوبة' })
  password!: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'رمز التحديث' })
  @IsString({ message: 'رمز التحديث يجب أن يكون نصًا' })
  @IsNotEmpty({ message: 'رمز التحديث مطلوب' })
  refreshToken!: string;
}

export class ChangePasswordDto {
  @ApiProperty({ description: 'كلمة المرور الحالية' })
  @IsString({ message: 'كلمة المرور الحالية يجب أن تكون نصًا' })
  @IsNotEmpty({ message: 'كلمة المرور الحالية مطلوبة' })
  currentPassword!: string;

  @ApiProperty({ description: 'كلمة المرور الجديدة — 10 خانات مع حرف كبير وصغير ورقم ورمز' })
  @IsString({ message: 'كلمة المرور الجديدة يجب أن تكون نصًا' })
  @IsNotEmpty({ message: 'كلمة المرور الجديدة مطلوبة' })
  @IsStrongPassword()
  newPassword!: string;
}
