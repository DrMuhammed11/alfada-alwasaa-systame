import { Body, Controller, ForbiddenException, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
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
}
