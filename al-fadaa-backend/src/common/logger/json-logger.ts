import { LoggerService, LogLevel } from '@nestjs/common';
import { getRequestContext } from '../context/request-context';

/**
 * Logger بصيغة JSON — يُستخدم في بيئة الإنتاج فقط.
 * كل سطر سجل يتضمن:
 *   - timestamp: الطابع الزمني ISO 8601
 *   - level: مستوى السجل (info/warn/error/debug/verbose)
 *   - context: سياق Nest (اسم الوحدة/الخدمة)
 *   - requestId: معرف الطلب المرتبط (إن وُجد)
 *   - message: نص الرسالة
 *   - trace: أثر الخطأ (في حالة error فقط)
 */
export class JsonLogger implements LoggerService {
  log(message: string, context?: string): void {
    this.write('info', message, context);
  }

  error(message: string, trace?: string, context?: string): void {
    this.write('error', message, context, trace);
  }

  warn(message: string, context?: string): void {
    this.write('warn', message, context);
  }

  debug?(message: string, context?: string): void {
    this.write('debug', message, context);
  }

  verbose?(message: string, context?: string): void {
    this.write('verbose', message, context);
  }

  setLogLevels?(levels: LogLevel[]): void {
    // no-op — مستويات السجل تُدار من خارج هذا الكائن
  }

  private write(level: string, message: string, context?: string, trace?: string): void {
    const ctx = getRequestContext();
    const entry: Record<string, unknown> = {
      timestamp: new Date().toISOString(),
      level,
      context: context ?? undefined,
      requestId: ctx.requestId ?? undefined,
      message,
    };
    if (trace) {
      entry.trace = trace;
    }
    process.stdout.write(JSON.stringify(entry) + '\n');
  }
}
