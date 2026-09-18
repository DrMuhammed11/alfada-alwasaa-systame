import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty } from 'class-validator';

export class LoginDto {
  @ApiProperty({ description: 'البريد الإلكتروني للموظف', example: 'gm@al-fadaa.com' })
  @IsEmail({}, { message: 'البريد الإلكتروني غير صالح' })
  email!: string;

  @ApiProperty({ description: 'كلمة المرور', example: 'Alfadaa@2026' })
  @IsNotEmpty({ message: 'كلمة المرور مطلوبة' })
  password!: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'رمز التحديث (Refresh Token)' })
  @IsNotEmpty({ message: 'رمز التحديث مطلوب' })
  refreshToken!: string;
}
