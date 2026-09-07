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
import { ReferralsService } from './referrals.service';
import { CreateReferralDto, MyReferralsQueryDto } from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';

@ApiTags('الإحالات')
@ApiBearerAuth()
@Controller()
export class ReferralsController {
  constructor(private readonly referralsService: ReferralsService) {}

  @Post('correspondences/:correspondenceId/referrals')
  @RequirePermission(Permission.CORR_REFER)
  @ApiOperation({
    summary: 'إحالة مراسلة (المدير العام → نائبه/مديري الأقسام، النائب → مديري الأقسام)',
  })
  create(
    @Param('correspondenceId', ParseUUIDPipe) correspondenceId: string,
    @Body() dto: CreateReferralDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.referralsService.create(correspondenceId, dto, user);
  }

  @Get('referrals/my')
  @ApiOperation({ summary: 'الإحالات الواردة إليّ (صندوق الإحالات)' })
  mine(@Query() dto: MyReferralsQueryDto, @CurrentUser() user: AuthUser) {
    return this.referralsService.findMine(dto, user);
  }

  @Get('correspondences/:correspondenceId/referrals')
  @ApiOperation({ summary: 'سجل إحالات مراسلة معينة' })
  history(
    @Param('correspondenceId', ParseUUIDPipe) correspondenceId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.referralsService.findForCorrespondence(correspondenceId, user);
  }

  @Patch('referrals/:id/close')
  @ApiOperation({ summary: 'إغلاق إحالة (الجهة المحال إليها أو الإدارة العليا)' })
  close(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.referralsService.close(id, user);
  }

  @Patch('referrals/:id/answer')
  @ApiOperation({ summary: 'إجابة إحالة (الجهة المحال إليها أو الإدارة العليا)' })
  answer(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.referralsService.answerReferral(id, user);
  }
}
