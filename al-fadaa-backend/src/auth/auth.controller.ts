import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { LoginDto, RefreshTokenDto } from './dto';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ThrottlerLimits } from '../common/throttler/throttler-config';
import type { AuthUser } from '../common/types';

@ApiTags('المصادقة')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Throttle(ThrottlerLimits.login)
  @Post('login')
  @ApiOperation({ summary: 'تسجيل الدخول — يعيد رمز الوصول' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @Throttle(ThrottlerLimits.login)
  @Post('login-v2')
  @ApiOperation({ summary: 'تسجيل الدخول (الإصدار الثاني) — يعيد رموز الوصول والتحديث وبيانات المستخدم' })
  loginV2(@Body() dto: LoginDto, @Req() req: Request) {
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    const ipAddress = req.ip;
    return this.authService.loginWithRefresh(dto, { userAgent, ipAddress });
  }

  @Post('refresh')
  @Public()
  @ApiOperation({ summary: 'تجديد رمز الوصول باستخدام رمز التحديث' })
  refresh(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    const ipAddress = req.ip;
    return this.authService.refreshTokens(dto.refreshToken, { userAgent, ipAddress });
  }

  @Post('logout')
  @ApiOperation({ summary: 'تسجيل الخروج — إبطال رمز التحديث' })
  logout(@Body() dto: RefreshTokenDto, @CurrentUser() user: AuthUser) {
    return this.authService.logout(dto.refreshToken);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'بيانات المستخدم الحالي' })
  me(@CurrentUser('id') userId: string) {
    return this.authService.me(userId);
  }
}
