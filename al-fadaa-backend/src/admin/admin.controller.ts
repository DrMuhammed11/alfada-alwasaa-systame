import { Body, Controller, ForbiddenException, Get, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { OutboxMailStatus, Role } from '@prisma/client';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';
import { AdminService } from './admin.service';

@ApiTags('لوحة تحكم النظام (Admin)')
@ApiBearerAuth()
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('orphans')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'تفتيش الكيانات التابعة اليتيمة والمعلقة على مراسلات منتهية (للأدمن فقط)' })
  findOrphans(@CurrentUser() user: AuthUser) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.findOrphans();
  }

  @Get('approval-workflows')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'استعراض مسارات الاعتماد المضبوطة للأولويات (للأدمن فقط)' })
  getWorkflows(@CurrentUser() user: AuthUser) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.getApprovalWorkflows();
  }

  @Put('approval-workflows')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'تحديث مسار الاعتماد لأولوية معينة (للأدمن فقط)' })
  setWorkflow(
    @Body() body: { priority: string; steps: { level: number; requiredRole: string }[] },
    @CurrentUser() user: AuthUser,
  ) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.setApprovalWorkflow(body.priority as any, body.steps as any);
  }

  @Get('outbox')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'استعراض رسائل صندوق البريد الصادر وحالات إعادة المحاولة (للأدمن فقط)' })
  @ApiQuery({ name: 'status', enum: OutboxMailStatus, required: false })
  @ApiQuery({ name: 'refNumber', type: String, required: false })
  @ApiQuery({ name: 'page', type: Number, required: false })
  @ApiQuery({ name: 'limit', type: Number, required: false })
  getOutbox(
    @Query('status') status?: OutboxMailStatus,
    @Query('refNumber') refNumber?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @CurrentUser() user?: AuthUser,
  ) {
    if (user && user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.getOutboxList({ status, refNumber, page, limit });
  }

  @Post('outbox/:id/retry')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'إعادة محاولة إرسال رسالة صادر يدويًا (للأدمن فقط)' })
  retryOutboxMail(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.retryOutboxMail(id);
  }

  @Post('outbox/:id/pause')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'إيقاف إعادة محاولة إرسال رسالة صادر مؤقتًا (للأدمن فقط)' })
  pauseOutboxMail(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('هذه العملية متاحة للأدمن فقط');
    }
    return this.adminService.pauseOutboxMail(id);
  }
}

