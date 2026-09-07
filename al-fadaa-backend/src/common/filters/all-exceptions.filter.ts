import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Request, Response } from 'express';
import { getRequestContext } from '../context/request-context';

/**
 * معالج أخطاء موحد: يحوّل كل الأخطاء (Nest / Prisma / Multer)
 * إلى استجابة عربية منظمة بصيغة واحدة:
 * { success, statusCode, message, error, requestId, path, timestamp }
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const requestId = (request as any).requestId ?? getRequestContext().requestId;

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'حدث خطأ غير متوقع في الخادم';
    let error = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
      } else if (res && typeof res === 'object') {
        const obj = res as Record<string, unknown>;
        message = (obj.message as string | string[]) ?? exception.message;
        error = (obj.error as string) ?? error;
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      // أخطاء Prisma الشائعة → أكواد HTTP منطقية
      if (exception.code === 'P2002') {
        status = HttpStatus.CONFLICT;
        message = 'القيمة موجودة مسبقًا — حقل فريد مكرر';
        error = 'Conflict';
      } else if (exception.code === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        message = 'السجل المطلوب غير موجود';
        error = 'Not Found';
      } else if (exception.code === 'P2003') {
        status = HttpStatus.BAD_REQUEST;
        message = 'لا يمكن تنفيذ العملية لوجود بيانات مرتبطة';
        error = 'Bad Request';
      }
    } else if (
      typeof exception === 'object' &&
      exception !== null &&
      (exception as { name?: string }).name === 'MulterError'
    ) {
      const code = (exception as { code?: string }).code;
      status =
        code === 'LIMIT_FILE_SIZE' ? HttpStatus.PAYLOAD_TOO_LARGE : HttpStatus.BAD_REQUEST;
      message =
        code === 'LIMIT_FILE_SIZE'
          ? 'حجم الملف يتجاوز الحد المسموح (15MB)'
          : 'خطأ في رفع الملف';
      error = 'File Upload Error';
    }

    if (status >= 500) {
      this.logger.error(
        `خطأ غير متوقع [${requestId ?? 'N/A'}]: ${request.method} ${request.url}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json({
      success: false,
      statusCode: status,
      message,
      error,
      requestId,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
