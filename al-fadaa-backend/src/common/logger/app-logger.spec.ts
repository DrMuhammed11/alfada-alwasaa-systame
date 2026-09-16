import { AppLogger, LogEntry } from './app-logger';
import { requestContextStorage } from '../context/request-context';

describe('AppLogger', () => {
  let stdoutSpy: jest.SpyInstance;
  let stderrSpy: jest.SpyInstance;

  beforeEach(() => {
    stdoutSpy = jest.spyOn(process.stdout, 'write').mockImplementation(() => true);
    stderrSpy = jest.spyOn(process.stderr, 'write').mockImplementation(() => true);
  });

  afterEach(() => {
    stdoutSpy.mockRestore();
    stderrSpy.mockRestore();
  });

  describe('وضع الإنتاج (Production / JSON)', () => {
    const logger = new AppLogger(true);

    it('يطبع سجل log بصيغة JSON إلى stdout ويتضمن الحقول الأساسية', () => {
      logger.log('رسالة تجريبية', 'TestContext');

      expect(stdoutSpy).toHaveBeenCalledTimes(1);
      const output = stdoutSpy.mock.calls[0][0];
      const parsed: LogEntry = JSON.parse(output);

      expect(parsed.level).toBe('info');
      expect(parsed.message).toBe('رسالة تجريبية');
      expect(parsed.context).toBe('TestContext');
      expect(parsed.timestamp).toBeDefined();
    });

    it('يطبع سجل error بصيغة JSON إلى stderr مع تفاصيل الأثر trace', () => {
      logger.error('حدث خطأ في النظام', 'Error: Stack trace here', 'AuthModule');

      expect(stderrSpy).toHaveBeenCalledTimes(1);
      const output = stderrSpy.mock.calls[0][0];
      const parsed: LogEntry = JSON.parse(output);

      expect(parsed.level).toBe('error');
      expect(parsed.message).toBe('حدث خطأ في النظام');
      expect(parsed.trace).toBe('Error: Stack trace here');
      expect(parsed.context).toBe('AuthModule');
    });

    it('يلتقط معرّف الطلب requestId تلقائيًا من سياق الطلب requestContextStorage', () => {
      requestContextStorage.run({ requestId: 'req-abc-999' }, () => {
        logger.warn('تحذير تجريبي مع معرف طلب', 'Audit');
      });

      expect(stdoutSpy).toHaveBeenCalledTimes(1);
      const output = stdoutSpy.mock.calls[0][0];
      const parsed: LogEntry = JSON.parse(output);

      expect(parsed.level).toBe('warn');
      expect(parsed.requestId).toBe('req-abc-999');
    });

    it('يتعامل بشكل صحيح مع الكائنات البرمجية objects بدلاً من النصوص البسيطة', () => {
      logger.debug?.({ detail: 'معلومات تفصيلية', count: 42 }, 'DebugContext');

      expect(stdoutSpy).toHaveBeenCalledTimes(1);
      const output = stdoutSpy.mock.calls[0][0];
      const parsed: LogEntry = JSON.parse(output);

      expect(parsed.level).toBe('debug');
      expect(parsed.message).toContain('معلومات تفصيلية');
    });
  });

  describe('وضع التطوير (Development / Colorized)', () => {
    const logger = new AppLogger(false);

    it('يطبع السجل ملونًا إلى stdout ويشمل اسم السياق', () => {
      logger.log('تشغيل الخدمة في التطوير', 'Bootstrap');

      expect(stdoutSpy).toHaveBeenCalledTimes(1);
      const output = stdoutSpy.mock.calls[0][0];

      expect(output).toContain('INFO');
      expect(output).toContain('[Bootstrap]');
      expect(output).toContain('تشغيل الخدمة في التطوير');
    });

    it('يطبع معرف الطلب [req: id] في وضع التطوير عند وجوده في السياق', () => {
      requestContextStorage.run({ requestId: 'dev-req-777' }, () => {
        logger.log('طلب وارد للتطوير', 'Http');
      });

      expect(stdoutSpy).toHaveBeenCalledTimes(1);
      const output = stdoutSpy.mock.calls[0][0];

      expect(output).toContain('[req: dev-req-777]');
    });

    it('يطبع سجل error إلى stderr في وضع التطوير', () => {
      logger.error('خطأ غير متوقع', 'Error: trace', 'ErrorHandler');

      expect(stderrSpy).toHaveBeenCalled();
      const output = stderrSpy.mock.calls[0][0];
      expect(output).toContain('ERROR');
      expect(output).toContain('خطأ غير متوقع');
    });
  });
});
