import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Put, Delete } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ThrottlerLimits } from '../common/throttler/throttler-config';
import { Public } from '../common/decorators/public.decorator';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';
import { SiteContentService } from './site-content.service';
import {
  CreateSiteFaqDto,
  CreateSiteProjectDto,
  CreateSiteSectorDto,
  CreateSiteServiceDto,
  UpdateSiteFaqDto,
  UpdateSiteProjectDto,
  UpdateSiteSectorDto,
  UpdateSiteServiceDto,
  UpsertSiteSettingDto,
} from './dto';

@ApiTags('محتوى الموقع الإلكتروني')
@Controller('site-content')
export class SiteContentController {
  constructor(private readonly siteContentService: SiteContentService) {}

  // ─── القراءة العامة — تُستهلك من الموقع الإلكتروني دون مصادقة ───

  @Public()
  @Throttle(ThrottlerLimits.publicContent)
  @Get('services')
  @ApiOperation({ summary: 'الخدمات المفعّلة للعرض في الموقع الإلكتروني' })
  getPublicServices() {
    return this.siteContentService.getPublicServices();
  }

  @Public()
  @Throttle(ThrottlerLimits.publicContent)
  @Get('sectors')
  @ApiOperation({ summary: 'القطاعات المفعّلة للعرض في الموقع الإلكتروني' })
  getPublicSectors() {
    return this.siteContentService.getPublicSectors();
  }

  @Public()
  @Throttle(ThrottlerLimits.publicContent)
  @Get('projects')
  @ApiOperation({ summary: 'مشاريع سابقة الأعمال المفعّلة للعرض في الموقع' })
  getPublicProjects() {
    return this.siteContentService.getPublicProjects();
  }

  @Public()
  @Throttle(ThrottlerLimits.publicContent)
  @Get('faqs')
  @ApiOperation({ summary: 'الأسئلة الشائعة المفعّلة للعرض في الموقع' })
  getPublicFaqs() {
    return this.siteContentService.getPublicFaqs();
  }

  @Public()
  @Throttle(ThrottlerLimits.publicContent)
  @Get('settings/:key')
  @ApiOperation({ summary: 'قراءة إعداد عام بمفتاحه (contacts / stats / pillars ...)' })
  getPublicSetting(@Param('key') key: string) {
    return this.siteContentService.getPublicSetting(key);
  }

  // ─── الإدارة الكاملة — بصلاحية إدارة محتويات الموقع ───

  @Get('manage/services')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'كل الخدمات (شاملة غير المفعّلة) — لوحة الإدارة' })
  getAllServices() {
    return this.siteContentService.getAllServices();
  }

  @Post('manage/services')
  @RequirePermission(Permission.CONTENT_MANAGE)
  createService(@Body() dto: CreateSiteServiceDto, @CurrentUser() user: AuthUser) {
    return this.siteContentService.createService(dto, user);
  }

  @Patch('manage/services/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  updateService(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSiteServiceDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.siteContentService.updateService(id, dto, user);
  }

  @Delete('manage/services/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  deleteService(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.siteContentService.deleteService(id, user);
  }

  @Get('manage/sectors')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'كل القطاعات (شاملة غير المفعّلة) — لوحة الإدارة' })
  getAllSectors() {
    return this.siteContentService.getAllSectors();
  }

  @Post('manage/sectors')
  @RequirePermission(Permission.CONTENT_MANAGE)
  createSector(@Body() dto: CreateSiteSectorDto, @CurrentUser() user: AuthUser) {
    return this.siteContentService.createSector(dto, user);
  }

  @Patch('manage/sectors/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  updateSector(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSiteSectorDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.siteContentService.updateSector(id, dto, user);
  }

  @Delete('manage/sectors/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  deleteSector(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.siteContentService.deleteSector(id, user);
  }

  @Get('manage/projects')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'كل مشاريع سابقة الأعمال (شاملة غير المفعّلة)' })
  getAllProjects() {
    return this.siteContentService.getAllProjects();
  }

  @Post('manage/projects')
  @RequirePermission(Permission.CONTENT_MANAGE)
  createProject(@Body() dto: CreateSiteProjectDto, @CurrentUser() user: AuthUser) {
    return this.siteContentService.createProject(dto, user);
  }

  @Patch('manage/projects/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  updateProject(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSiteProjectDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.siteContentService.updateProject(id, dto, user);
  }

  @Delete('manage/projects/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  deleteProject(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.siteContentService.deleteProject(id, user);
  }

  @Get('manage/faqs')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'كل الأسئلة الشائعة (شاملة غير المفعّلة)' })
  getAllFaqs() {
    return this.siteContentService.getAllFaqs();
  }

  @Post('manage/faqs')
  @RequirePermission(Permission.CONTENT_MANAGE)
  createFaq(@Body() dto: CreateSiteFaqDto, @CurrentUser() user: AuthUser) {
    return this.siteContentService.createFaq(dto, user);
  }

  @Patch('manage/faqs/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  updateFaq(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSiteFaqDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.siteContentService.updateFaq(id, dto, user);
  }

  @Delete('manage/faqs/:id')
  @RequirePermission(Permission.CONTENT_MANAGE)
  deleteFaq(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.siteContentService.deleteFaq(id, user);
  }

  @Get('manage/settings')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'كل الإعدادات العامة (اتصالات، إحصاءات، ركائز، قيم ...)' })
  getSettings() {
    return this.siteContentService.getSettings();
  }

  @Put('manage/settings/:key')
  @RequirePermission(Permission.CONTENT_MANAGE)
  @ApiOperation({ summary: 'إنشاء أو تحديث إعداد عام بمفتاحه (JSON حر)' })
  upsertSetting(
    @Param('key') key: string,
    @Body() dto: UpsertSiteSettingDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.siteContentService.upsertSetting(key, dto, user);
  }
}
