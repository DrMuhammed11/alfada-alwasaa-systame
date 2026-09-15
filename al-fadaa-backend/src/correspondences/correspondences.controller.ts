import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CorrespondencesService } from './correspondences.service';
import {
  CorrespondencesQueryDto,
  CreateIncomingDto,
  CreateInternalDto,
  PublicInquiryDto,
  UpdateCorrespondenceDto,
} from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';
import { Throttle } from '@nestjs/throttler';
import { ThrottlerLimits } from '../common/throttler/throttler-config';

@ApiTags('المراسلات')
@ApiBearerAuth()
@Controller('correspondences')
export class CorrespondencesController {
  constructor(private readonly correspondencesService: CorrespondencesService) {}

  @Public()
  @Throttle(ThrottlerLimits.publicInquiry)
  @Post('public/inquiry')
  @ApiOperation({
    summary: 'تقديم طلب عرض سعر أو استشارة من الموقع الإلكتروني الرسمي للشركة',
  })
  createPublicInquiry(@Body() dto: PublicInquiryDto) {
    return this.correspondencesService.createPublicInquiry(dto);
  }

  @Public()
  @Throttle(ThrottlerLimits.publicTrack)
  @Get('public/track/:refNumber')
  @ApiOperation({
    summary: 'استعلام عام لعملاء الموقع عن حالة معاملة برقمها المرجعي',
  })
  trackPublicInquiry(@Param('refNumber') refNumber: string) {
    return this.correspondencesService.trackPublicInquiry(refNumber);
  }

  @Post('incoming')
  @RequirePermission(Permission.CORR_REGISTER)
  @ApiOperation({
    summary: 'تسجيل مراسلة واردة (وصلت إلى بريد الشركة الموحد info@al-fadaa.com)',
  })
  createIncoming(
    @Body() dto: CreateIncomingDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.correspondencesService.createIncoming(dto, user);
  }

  @Post('internal')
  @RequirePermission(Permission.CORR_REGISTER)
  @ApiOperation({ summary: 'إنشاء تعميم داخلي بين الأقسام (ينشر فورًا)' })
  createInternal(
    @Body() dto: CreateInternalDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.correspondencesService.createInternal(dto, user);
  }

  @Get()
  @ApiOperation({
    summary: 'قائمة المراسلات — النطاق حسب الدور (الإدارة العليا: الكل / مدير قسم: قسمه / موظف: مهامه)',
  })
  findAll(@Query() dto: CorrespondencesQueryDto, @CurrentUser() user: AuthUser) {
    return this.correspondencesService.findAll(dto, user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'تفاصيل مراسلة كاملة (الإحالات / التكليفات / الردود / المرفقات)' })
  findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.correspondencesService.findOne(id, user);
  }

  @Patch(':id')
  @RequirePermission(Permission.CORR_REGISTER)
  @ApiOperation({ summary: 'تعديل البيانات الأساسية (قبل الإحالة فقط)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCorrespondenceDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.correspondencesService.update(id, dto, user);
  }

  @Post(':id/close')
  @RequirePermission(Permission.CORR_ARCHIVE)
  @ApiOperation({ summary: 'إغلاق المراسلة (المدير العام / مسؤول النظام)' })
  close(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthUser,
    @Body() body?: { force?: boolean },
  ) {
    return this.correspondencesService.close(id, user, body);
  }

  @Post(':id/archive')
  @RequirePermission(Permission.CORR_ARCHIVE)
  @ApiOperation({ summary: 'أرشفة المراسلة — نهاية دورة الحياة' })
  archive(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.correspondencesService.archive(id, user);
  }
}
