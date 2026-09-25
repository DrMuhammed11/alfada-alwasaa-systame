import { Controller, Post, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IncomingMailService } from './incoming-mail.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permission } from '../security/permissions';

@ApiTags('البريد')
@ApiBearerAuth()
@Controller('mail')
export class MailController {
  constructor(private readonly incomingMailService: IncomingMailService) {}

  /**
   * مزامنة فورية للبريد الوارد — تُستدعى من زر المزامنة في الواجهة الأمامية.
   * محمية بصلاحية تسجيل المراسلات: لا يجوز لأي موظف أن يُجبر الخادم على استعلام IMAP.
   */
  @Post('sync')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @RequirePermission(Permission.CORR_REGISTER)
  async syncMail(): Promise<{ success: boolean; newCount: number; message: string }> {
    const beforeCount = await this.incomingMailService.getCorrespondenceCount();
    await this.incomingMailService.pollEmails();
    const afterCount = await this.incomingMailService.getCorrespondenceCount();
    const newCount = Math.max(0, afterCount - beforeCount);

    return {
      success: true,
      newCount,
      message: newCount > 0
        ? `تم استلام ${newCount} مراسلة جديدة`
        : 'لا توجد مراسلات جديدة',
    };
  }
}
