import { Controller, Post, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { IncomingMailService } from './incoming-mail.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('mail')
export class MailController {
  constructor(private readonly incomingMailService: IncomingMailService) {}

  /**
   * مزامنة فورية للبريد الوارد — يُستدعى من زر المزامنة في الواجهة الأمامية
   */
  @Post('sync')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
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
