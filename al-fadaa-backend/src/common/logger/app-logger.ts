import { LoggerService, LogLevel } from '@nestjs/common';
import { getRequestContext } from '../context/request-context';

export interface LogEntry {
  timestamp: string;
  level: string;
  context?: string;
  requestId?: string;
  message: string;
  trace?: string;
}

/**
 * فئة مسجل الأحداث الموحد للنظام (AppLogger)
 * تدعم وضعين تلقائيًا:
 * 1. وضع الإنتاج (production): مخرجات JSON أحادية السطر مناسبة لأنظمة التجميع والتحليل (ELK / CloudWatch / Datadog).
 * 2. وضع التطوير (development): مخرجات ملونة ومقروءة توضح الوقت، المستوى، سياق الوحدة، ومعرف الطلب [req: id].
 */
export class AppLogger implements LoggerService {
  private readonly isProduction: boolean;

  constructor(isProduction?: boolean) {
    this.isProduction = isProduction ?? process.env.NODE_ENV === 'production';
  }

  log(message: any, context?: string): void {
    this.write('info', message, context);
  }

  error(message: any, trace?: string, context?: string): void {
    this.write('error', message, context, trace);
  }

  warn(message: any, context?: string): void {
    this.write('warn', message, context);
  }

  debug?(message: any, context?: string): void {
    this.write('debug', message, context);
  }

  verbose?(message: any, context?: string): void {
    this.write('verbose', message, context);
  }

  setLogLevels?(_levels: LogLevel[]): void {
    // مستويات التسجيل تدار مركزيًا
  }

  /** صياغة مدخل السجل وتوجيهه للمخرج المناسب */
  private write(level: string, rawMessage: any, context?: string, trace?: string): void {
    const ctx = getRequestContext();
    const message = typeof rawMessage === 'object' ? JSON.stringify(rawMessage) : String(rawMessage);
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      context: context || undefined,
      requestId: ctx.requestId || undefined,
      message,
    };

    if (trace) {
      entry.trace = trace;
    }

    if (this.isProduction) {
      this.writeJson(entry);
    } else {
      this.writeDev(entry);
    }
  }

  /** كتابة السجل بصيغة JSON القياسية للإنتاج */
  private writeJson(entry: LogEntry): void {
    const stream = entry.level === 'error' ? process.stderr : process.stdout;
    stream.write(JSON.stringify(entry) + '\n');
  }

  /** كتابة السجل بصيغة ملونة ومفصلة للتطوير */
  private writeDev(entry: LogEntry): void {
    const colors = {
      reset: '\x1b[0m',
      dim: '\x1b[2m',
      bright: '\x1b[1m',
      green: '\x1b[32m',
      yellow: '\x1b[33m',
      red: '\x1b[31m',
      magenta: '\x1b[35m',
      cyan: '\x1b[36m',
      gray: '\x1b[90m',
    };

    let levelColor = colors.green;
    if (entry.level === 'error') levelColor = colors.red;
    else if (entry.level === 'warn') levelColor = colors.yellow;
    else if (entry.level === 'debug') levelColor = colors.magenta;
    else if (entry.level === 'verbose') levelColor = colors.gray;

    const timeStr = `${colors.gray}${entry.timestamp}${colors.reset}`;
    const lvlStr = `${levelColor}${colors.bright}${entry.level.toUpperCase().padEnd(7)}${colors.reset}`;
    const ctxStr = entry.context ? `${colors.yellow}[${entry.context}]${colors.reset} ` : '';
    const reqStr = entry.requestId ? `${colors.cyan}[req: ${entry.requestId}]${colors.reset} ` : '';

    const stream = entry.level === 'error' ? process.stderr : process.stdout;
    stream.write(`${timeStr} ${lvlStr} ${ctxStr}${reqStr}${entry.message}\n`);

    if (entry.trace) {
      stream.write(`${colors.red}${entry.trace}${colors.reset}\n`);
    }
  }
}
