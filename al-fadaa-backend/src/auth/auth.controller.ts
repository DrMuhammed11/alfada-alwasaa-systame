import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { LoginDto, RefreshTokenDto } from './dto';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ThrottlerLimits } from '../common/throttler/throttler-config';

@ApiTags('المصادقة')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Throttle(ThrottlerLimits.login)
  @Post('login')
  @ApiOperation({ summary: 'تسجيل الدخول — يعيد رموز الوصول والتحديث وبيانات المستخدم' })
  login(@Body() dto: LoginDto, @Req() req: Request) {
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    const ipAddress = req.ip;
    return this.authService.loginWithRefresh(dto, { userAgent, ipAddress });
  }

  @Public()
  @Post('refresh')
  @ApiOperation({ summary: 'تجديد الرموز عبر تدوير Refresh Token' })
  refresh(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    const ipAddress = req.ip;
    return this.authService.refreshTokens(dto.refreshToken, { userAgent, ipAddress });
  }

  @Public()
  @Post('logout')
  @ApiOperation({ summary: 'تسجيل الخروج وإبطال رمز التحديث' })
  logout(@Body() dto: Partial<RefreshTokenDto>) {
    return this.authService.logout(dto.refreshToken);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'بيانات المستخدم الحالي' })
  me(@CurrentUser('id') userId: string) {
    return this.authService.me(userId);
  }
}
