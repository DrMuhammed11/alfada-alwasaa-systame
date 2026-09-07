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
import { RepliesService } from './replies.service';
import {
  CreateReplyDto,
  DirectReplyDto,
  RejectReplyDto,
  RepliesQueryDto,
  UpdateReplyDto,
} from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';

@ApiTags('الردود')
@ApiBearerAuth()
@Controller('replies')
export class RepliesController {
  constructor(private readonly repliesService: RepliesService) {}

  @Post('direct')
  @RequirePermission(Permission.CORR_SEND)
  @ApiOperation({ summary: 'إرسال رد مباشر وفوري للعميل عبر البريد الإلكتروني' })
  sendDirect(@Body() dto: DirectReplyDto, @CurrentUser() user: AuthUser) {
    return this.repliesService.sendDirect(dto, user);
  }

  @Post()
  @RequirePermission(Permission.REPLY_DRAFT)
  @ApiOperation({ summary: 'إنشاء مسودة رد على مراسلة (المكلف أو المحال إليه أو المشرفون)' })
  create(@Body() dto: CreateReplyDto, @CurrentUser() user: AuthUser) {
    return this.repliesService.create(dto, user);
  }

  @Get()
  @ApiOperation({
    summary: 'الردود — ردودي افتراضيًا، أو ردود مراسلة محددة عبر ?correspondenceId=',
  })
  findAll(@Query() dto: RepliesQueryDto, @CurrentUser() user: AuthUser) {
    return this.repliesService.findAll(dto, user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'تفاصيل رد (مع سلسلة الاعتماد)' })
  findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.repliesService.findOne(id, user);
  }

  @Patch(':id')
  @RequirePermission(Permission.REPLY_DRAFT)
  @ApiOperation({ summary: 'تعديل المسودة (صاحبها فقط — متاح أيضًا بعد الرفض)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateReplyDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.repliesService.update(id, dto, user);
  }

  @Post(':id/submit')
  @RequirePermission(Permission.REPLY_SUBMIT)
  @ApiOperation({ summary: 'رفع المسودة للاعتماد (صاحبها فقط)' })
  submit(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.repliesService.submit(id, user);
  }

  @Post(':id/approve')
  @RequirePermission(Permission.REPLY_APPROVE)
  @ApiOperation({
    summary: 'اعتماد الرد (المشرفون — لا يجوز اعتماد رد صاغه المعتمد نفسه)',
  })
  approve(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.repliesService.approve(id, user);
  }

  @Post(':id/reject')
  @RequirePermission(Permission.REPLY_APPROVE)
  @ApiOperation({ summary: 'رفض الرد مع سبب — يعود للموظف لتعديله' })
  reject(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectReplyDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.repliesService.reject(id, dto, user);
  }

  @Post(':id/send')
  @RequirePermission(Permission.CORR_SEND)
  @ApiOperation({
    summary: 'الإرسال النهائي للعميل من بريد الشركة الموحد (المدير العام فقط)',
  })
  send(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.repliesService.send(id, user);
  }

  @Get(':id/versions')
  @ApiOperation({ summary: 'استعراض تاريخ إصدارات الرد' })
  getVersions(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.repliesService.getVersions(id, user);
  }

  @Get(':id/diff')
  @ApiOperation({ summary: 'مقارنة الفروق السطرية بين نسختين للرد' })
  getDiff(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('from') fromVersion?: string,
    @Query('to') toVersion?: string,
  ) {
    return this.repliesService.getDiff(
      id,
      fromVersion ? parseInt(fromVersion, 10) : undefined,
      toVersion ? parseInt(toVersion, 10) : undefined,
    );
  }
}
