import {
  parseCorsOrigins,
  validateProductionOrigins,
  buildAllowedOrigins,
  buildCorsOriginFunction,
} from './build-cors-origin';

describe('build-cors-origin', () => {
  // ─── parseCorsOrigins ───────────────────────────────────────
  describe('parseCorsOrigins', () => {
    it('يعيد مصفوفة فارغة عند عدم وجود قيمة', () => {
      expect(parseCorsOrigins(undefined)).toEqual([]);
      expect(parseCorsOrigins('')).toEqual([]);
      expect(parseCorsOrigins('   ')).toEqual([]);
    });

    it('يفصل النطاقات بالفاصلة ويزيل المسافات', () => {
      expect(parseCorsOrigins('https://a.com, https://b.com , https://c.com')).toEqual([
        'https://a.com',
        'https://b.com',
        'https://c.com',
      ]);
    });

    it('يتعامل مع نطاق واحد', () => {
      expect(parseCorsOrigins('https://example.com')).toEqual(['https://example.com']);
    });
  });

  // ─── validateProductionOrigins ──────────────────────────────
  describe('validateProductionOrigins', () => {
    it('يلقي خطأ عند القائمة الفارغة', () => {
      expect(() => validateProductionOrigins([])).toThrow('فارغ');
    });

    it('يلقي خطأ عند وجود wildcard *', () => {
      expect(() => validateProductionOrigins(['https://a.com', '*'])).toThrow('wildcard');
    });

    it('لا يلقي خطأ مع نطاقات صحيحة', () => {
      expect(() =>
        validateProductionOrigins(['https://a.com', 'https://b.com']),
      ).not.toThrow();
    });
  });

  // ─── buildAllowedOrigins ────────────────────────────────────
  describe('buildAllowedOrigins', () => {
    it('في التطوير: يضيف نطاقات localhost تلقائيًا', () => {
      const result = buildAllowedOrigins('https://custom.dev', false);
      expect(result).toContain('https://custom.dev');
      expect(result).toContain('http://localhost:3000');
      expect(result).toContain('http://localhost:3001');
      expect(result).toContain('http://localhost:5000');
    });

    it('في التطوير: يتجاهل * ويضيف localhost', () => {
      const result = buildAllowedOrigins('*', false);
      expect(result).not.toContain('*');
      expect(result).toContain('http://localhost:3000');
    });

    it('في الإنتاج: يعيد النطاقات كما هي بدون localhost', () => {
      const result = buildAllowedOrigins('https://prod.com,https://api.prod.com', true);
      expect(result).toEqual(['https://prod.com', 'https://api.prod.com']);
      expect(result).not.toContain('http://localhost:3000');
    });

    it('في الإنتاج: يلقي خطأ عند القائمة الفارغة', () => {
      expect(() => buildAllowedOrigins('', true)).toThrow();
    });

    it('في الإنتاج: يلقي خطأ عند wildcard', () => {
      expect(() => buildAllowedOrigins('*', true)).toThrow();
    });
  });

  // ─── buildCorsOriginFunction ────────────────────────────────
  describe('buildCorsOriginFunction', () => {
    it('يقبل origin مصرح به', (done) => {
      const fn = buildCorsOriginFunction('https://allowed.com', false);
      fn('https://allowed.com', (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);
        done();
      });
    });

    it('يرفض origin غير مصرح به', (done) => {
      const fn = buildCorsOriginFunction('https://allowed.com', false);
      fn('https://evil.com', (err) => {
        expect(err).toBeInstanceOf(Error);
        expect(err!.message).toContain('غير مسموح');
        done();
      });
    });

    it('يسمح بالطلبات بدون Origin (خادم-لخادم)', (done) => {
      const fn = buildCorsOriginFunction('https://allowed.com', false);
      fn(undefined, (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);
        done();
      });
    });

    it('في التطوير: يقبل localhost تلقائيًا', (done) => {
      const fn = buildCorsOriginFunction('https://custom.com', false);
      fn('http://localhost:5000', (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);
        done();
      });
    });

    it('في الإنتاج: يلقي خطأ عند CORS_ORIGIN فارغ', () => {
      expect(() => buildCorsOriginFunction('', true)).toThrow();
    });

    it('في الإنتاج: يلقي خطأ عند CORS_ORIGIN = *', () => {
      expect(() => buildCorsOriginFunction('*', true)).toThrow();
    });
  });
});
