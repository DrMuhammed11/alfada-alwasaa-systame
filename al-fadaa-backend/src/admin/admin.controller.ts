import { Controller, ForbiddenException, Get, UseGuards } from '@nestjs/common';
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
}
