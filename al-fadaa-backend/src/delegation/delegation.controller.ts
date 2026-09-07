import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types';
import { DelegationService } from './delegation.service';
import { CreateDelegationDto } from './dto/create-delegation.dto';

@ApiTags('delegations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('delegations')
export class DelegationController {
  constructor(private readonly delegationService: DelegationService) {}

  @ApiOperation({ summary: 'إنشاء تفويض جديد للصلاحيات' })
  @Post()
  create(@Body() dto: CreateDelegationDto, @CurrentUser() user: AuthUser) {
    return this.delegationService.create(dto, user);
  }

  @ApiOperation({ summary: 'إنهاء تفويض نشط مبكرًا' })
  @Patch(':id/terminate')
  terminate(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.delegationService.terminate(id, user);
  }

  @ApiOperation({ summary: 'قائمة التفويضات الممنوحة مني' })
  @Get('my')
  findMy(@CurrentUser() user: AuthUser) {
    return this.delegationService.findMy(user);
  }

  @ApiOperation({ summary: 'قائمة التفويضات الممنوحة لي (أنا الوكيل فيها)' })
  @Get('for-me')
  findForMe(@CurrentUser() user: AuthUser) {
    return this.delegationService.findForMe(user);
  }

  @ApiOperation({ summary: 'سجل كافة التفويضات في النظام (للأدمن فقط)' })
  @Get()
  findAll(@CurrentUser() user: AuthUser) {
    return this.delegationService.findAll(user);
  }
}
