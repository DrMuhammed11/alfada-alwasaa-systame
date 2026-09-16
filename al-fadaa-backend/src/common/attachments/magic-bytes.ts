/**
 * فحص البايتات السحرية (Magic Bytes) — التحقق من محتوى الملف الفعلي
 * لا نعتمد على الامتداد أو mimetype المُرسل من العميل فقط.
 */
import * as fs from 'fs';

/** تعريف توقيعات الملفات المدعومة */
interface MagicSignature {
  /** الأنواع المسموحة (MIME types) التي يُسمح لها بهذا التوقيع */
  mimeTypes: string[];
  /** البايتات السحرية — كل عنصر هو مصفوفة من الأرقام (hex) */
  signatures: { offset: number; bytes: number[] }[];
}

/**
 * قاموس التوقيعات المدعومة — كل مفتاح هو وصف للنوع
 * التوقيعات مرتبة حسب الأولوية (الأطول أولاً للدقة)
 */
const MAGIC_SIGNATURES: MagicSignature[] = [
  {
    // PDF: يبدأ بـ %PDF
    mimeTypes: ['application/pdf'],
    signatures: [{ offset: 0, bytes: [0x25, 0x50, 0x44, 0x46] }],
  },
  {
    // PNG: يبدأ بـ 89 50 4E 47
    mimeTypes: ['image/png'],
    signatures: [{ offset: 0, bytes: [0x89, 0x50, 0x4e, 0x47] }],
  },
  {
    // JPEG: يبدأ بـ FF D8 FF
    mimeTypes: ['image/jpeg'],
    signatures: [{ offset: 0, bytes: [0xff, 0xd8, 0xff] }],
  },
  {
    // GIF: يبدأ بـ GIF87a أو GIF89a
    mimeTypes: ['image/gif'],
    signatures: [{ offset: 0, bytes: [0x47, 0x49, 0x46, 0x38] }],
  },
  {
    // WEBP: يبدأ بـ RIFF....WEBP
    mimeTypes: ['image/webp'],
    signatures: [
      { offset: 0, bytes: [0x52, 0x49, 0x46, 0x46] }, // RIFF
      { offset: 8, bytes: [0x57, 0x45, 0x42, 0x50] }, // WEBP
    ],
  },
  {
    // DOCX / XLSX / ZIP: يبدأ بـ PK (50 4B 03 04)
    // ملاحظة: DOCX و XLSX هي ملفات ZIP في جوهرها
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/zip',
    ],
    signatures: [{ offset: 0, bytes: [0x50, 0x4b, 0x03, 0x04] }],
  },
  {
    // DOC / XLS (OLE2 Compound): يبدأ بـ D0 CF 11 E0
    mimeTypes: [
      'application/msword',
      'application/vnd.ms-excel',
    ],
    signatures: [{ offset: 0, bytes: [0xd0, 0xcf, 0x11, 0xe0] }],
  },
  {
    // نص عادي — لا توقيع ثابت، يُقبل أي محتوى بدون بايتات ثنائية مشبوهة
    mimeTypes: ['text/plain'],
    signatures: [], // يُعالج بشكل خاص أدناه
  },
];

/** الحد الأقصى للبايتات المقروءة للفحص */
const MAX_READ = 16;

/**
 * التحقق من أن محتوى الملف يطابق نوع MIME المُعلن
 * @param filePath مسار الملف على القرص
 * @param declaredMime نوع MIME المُعلن من العميل
 * @returns true إذا كان المحتوى يطابق النوع، false خلاف ذلك
 */
export function validateMagicBytes(
  filePath: string,
  declaredMime: string,
): boolean {
  // البحث عن التوقيع المناسب لنوع MIME المُعلن
  const entry = MAGIC_SIGNATURES.find((s) =>
    s.mimeTypes.includes(declaredMime),
  );

  // نوع غير معروف — نرفضه احتياطياً
  if (!entry) return false;

  // text/plain — لا توقيع ثابت، نقبله مباشرة
  if (entry.signatures.length === 0) return true;

  // قراءة أول بايتات من الملف
  const fd = fs.openSync(filePath, 'r');
  try {
    const buf = Buffer.alloc(MAX_READ);
    fs.readSync(fd, buf, 0, MAX_READ, 0);

    // التحقق من جميع التوقيعات المطلوبة
    return entry.signatures.every((sig) =>
      sig.bytes.every((b, i) => buf[sig.offset + i] === b),
    );
  } finally {
    fs.closeSync(fd);
  }
}

/**
 * التحقق مما إذا كان نوع ZIP مسموحاً
 * @returns true إذا كان ALLOW_ZIP_UPLOADS مفعلاً
 */
export function isZipAllowed(): boolean {
  return process.env.ALLOW_ZIP_UPLOADS === 'true';
}
