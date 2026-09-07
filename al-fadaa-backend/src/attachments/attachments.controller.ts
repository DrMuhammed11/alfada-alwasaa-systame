import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import * as fs from 'fs';
import * as path from 'path';
import type { Response } from 'express';
import { AttachmentsService } from './attachments.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';

/** إعدادات الرفع: تخزين محلي + حد 15MB + أنواع ملفات مسموحة */
const UPLOAD_OPTIONS = {
  storage: diskStorage({
    destination: (_req: Express.Request, _file: Express.Multer.File, cb: (error: Error | null, destination: string) => void) => {
      const dir = process.env.UPLOAD_DIR || './uploads';
      fs.mkdirSync(dir, { recursive: true });
      cb(null, dir);
    },
    filename: (_req: Express.Request, file: Express.Multer.File, cb: (error: Error | null, filename: string) => void) => {
      const unique = `${Date.now()}-${Math.round(Math.random() * 1_000_000_000)}`;
      cb(null, `${unique}${path.extname(file.originalname) || ''}`);
    },
  }),
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (
    _req: Express.Request,
    file: Express.Multer.File,
    cb: (error: Error | null, acceptFile: boolean) => void,
  ) => {
    const allowed = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/zip',
      'text/plain',
    ];
    const ext = path.extname(file.originalname).toLowerCase();
    const mimeByExt: Record<string, string> = {
      '.pdf': 'application/pdf',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.zip': 'application/zip',
      '.txt': 'text/plain',
    };
    if (file.mimetype === 'application/octet-stream' && mimeByExt[ext]) {
      file.mimetype = mimeByExt[ext];
    }
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new BadRequestException(
          'نوع الملف غير مدعوم (PDF / صور / Word / Excel / ZIP / نصوص)',
        ),
        false,
      );
    }
  },
};

const FILE_BODY_SCHEMA = {
  schema: {
    type: 'object',
    properties: { file: { type: 'string', format: 'binary' } },
  },
};

@ApiTags('المرفقات')
@ApiBearerAuth()
@Controller()
export class AttachmentsController {
  constructor(private readonly attachmentsService: AttachmentsService) {}

  @Post('correspondences/:correspondenceId/attachments')
  @UseInterceptors(FileInterceptor('file', UPLOAD_OPTIONS))
  @ApiConsumes('multipart/form-data')
  @ApiBody(FILE_BODY_SCHEMA)
  @ApiOperation({ summary: 'رفع مرفق لمراسلة (حتى 15MB)' })
  uploadForCorrespondence(
    @Param('correspondenceId', ParseUUIDPipe) correspondenceId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() user: AuthUser,
  ) {
    if (!file) throw new BadRequestException('الملف مطلوب (الحقل: file)');
    return this.attachmentsService.createForCorrespondence(correspondenceId, file, user);
  }

  @Post('replies/:replyId/attachments')
  @UseInterceptors(FileInterceptor('file', UPLOAD_OPTIONS))
  @ApiConsumes('multipart/form-data')
  @ApiBody(FILE_BODY_SCHEMA)
  @ApiOperation({ summary: 'رفع مرفق لمسودة رد' })
  uploadForReply(
    @Param('replyId', ParseUUIDPipe) replyId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() user: AuthUser,
  ) {
    if (!file) throw new BadRequestException('الملف مطلوب (الحقل: file)');
    return this.attachmentsService.createForReply(replyId, file, user);
  }

  @Get('attachments/:id/download')
  @ApiOperation({ summary: 'تنزيل مرفق' })
  download(
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
    @CurrentUser() user: AuthUser,
  ) {
    return this.attachmentsService.download(id, res, user);
  }

  @Delete('attachments/:id')
  @ApiOperation({ summary: 'حذف مرفق (رافعه فقط — وقبل إرسال المراسلة)' })
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.attachmentsService.remove(id, user);
  }
}
