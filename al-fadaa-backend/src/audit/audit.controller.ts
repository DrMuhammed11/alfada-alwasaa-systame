import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuditService } from './audit.service';
import { AuditQueryDto } from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permission } from '../security/permissions';

@ApiTags('سجل التدقيق')
@ApiBearerAuth()
@Controller('audit')
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  @RequirePermission(Permission.AUDIT_VIEW)
  @ApiOperation({
    summary: 'استعراض سجل التدقيق (مسؤول النظام والمدير العام فقط) — للقراءة فقط',
  })
  findAll(@Query() dto: AuditQueryDto) {
    return this.auditService.findAll(dto);
  }
}
