/**
 * اختبارات أمان المرفقات — فحص Magic Bytes + SHA-256 + حظر ZIP
 */
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { validateMagicBytes, isZipAllowed } from '../common/attachments/magic-bytes';

describe('أمان المرفقات — Magic Bytes', () => {
  let tmpDir: string;

  beforeAll(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'attach-test-'));
  });

  afterAll(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  /** مساعد لإنشاء ملف مؤقت بمحتوى محدد */
  function createTempFile(name: string, content: Buffer): string {
    const filePath = path.join(tmpDir, name);
    fs.writeFileSync(filePath, content);
    return filePath;
  }

  // ── ملف بامتداد PDF ولكن محتواه نص عادي — يجب رفضه ──
  it('يرفض ملفاً بامتداد PDF ومحتوى غير PDF', () => {
    const fakePdf = createTempFile(
      'fake.pdf',
      Buffer.from('هذا ليس ملف PDF حقيقي — إنه نص عادي', 'utf-8'),
    );
    const result = validateMagicBytes(fakePdf, 'application/pdf');
    expect(result).toBe(false);
  });

  // ── ملف PDF صالح — يجب قبوله ──
  it('يقبل ملف PDF صالح', () => {
    // أول 4 بايتات من ملف PDF حقيقي: %PDF
    const realPdf = createTempFile(
      'real.pdf',
      Buffer.from([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]),
    );
    const result = validateMagicBytes(realPdf, 'application/pdf');
    expect(result).toBe(true);
  });

  // ── ملف PNG صالح ──
  it('يقبل ملف PNG صالح', () => {
    const realPng = createTempFile(
      'real.png',
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
    const result = validateMagicBytes(realPng, 'image/png');
    expect(result).toBe(true);
  });

  // ── ملف JPEG صالح ──
  it('يقبل ملف JPEG صالح', () => {
    const realJpeg = createTempFile(
      'real.jpg',
      Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]),
    );
    const result = validateMagicBytes(realJpeg, 'image/jpeg');
    expect(result).toBe(true);
  });

  // ── ملف PNG يُدّعى أنه JPEG — يجب رفضه ──
  it('يرفض ملف PNG يدّعي أنه JPEG', () => {
    const pngAsJpeg = createTempFile(
      'fake.jpg',
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
    const result = validateMagicBytes(pngAsJpeg, 'image/jpeg');
    expect(result).toBe(false);
  });

  // ── ملف DOCX/XLSX (PK header) ──
  it('يقبل ملف DOCX (بنية PK/ZIP)', () => {
    const realDocx = createTempFile(
      'real.docx',
      Buffer.from([0x50, 0x4b, 0x03, 0x04, 0x14, 0x00, 0x06, 0x00]),
    );
    const result = validateMagicBytes(
      realDocx,
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    expect(result).toBe(true);
  });

  // ── نوع MIME غير معروف — يُرفض ──
  it('يرفض نوع MIME غير مدعوم', () => {
    const unknown = createTempFile(
      'unknown.bin',
      Buffer.from([0x00, 0x01, 0x02, 0x03]),
    );
    const result = validateMagicBytes(unknown, 'application/x-custom');
    expect(result).toBe(false);
  });

  // ── نص عادي — يُقبل بدون فحص magic bytes ──
  it('يقبل ملف نص عادي', () => {
    const textFile = createTempFile(
      'note.txt',
      Buffer.from('مرحباً بالعالم', 'utf-8'),
    );
    const result = validateMagicBytes(textFile, 'text/plain');
    expect(result).toBe(true);
  });
});

describe('حظر ZIP', () => {
  const originalEnv = process.env.ALLOW_ZIP_UPLOADS;

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.ALLOW_ZIP_UPLOADS;
    } else {
      process.env.ALLOW_ZIP_UPLOADS = originalEnv;
    }
  });

  it('يمنع ZIP افتراضياً', () => {
    delete process.env.ALLOW_ZIP_UPLOADS;
    expect(isZipAllowed()).toBe(false);
  });

  it('يسمح بـ ZIP عند تفعيل ALLOW_ZIP_UPLOADS', () => {
    process.env.ALLOW_ZIP_UPLOADS = 'true';
    expect(isZipAllowed()).toBe(true);
  });

  it('يمنع ZIP عندما تكون القيمة غير true', () => {
    process.env.ALLOW_ZIP_UPLOADS = 'false';
    expect(isZipAllowed()).toBe(false);
  });
});
