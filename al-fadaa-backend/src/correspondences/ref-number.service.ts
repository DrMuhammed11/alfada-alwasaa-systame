import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type RefType = 'INC' | 'OUT' | 'INT';

/**
 * مولّد الأرقام المرجعية التسلسلية — ذري فعليًا:
 *   INC-2026-000001 (وارد) / OUT-2026-000001 (صادر) / INT-2026-000001 (داخلي)
 *
 * استعلام خام واحد ذري (INSERT ON CONFLICT … RETURNING) على مستوى قاعدة البيانات.
 * العداد هو مصدر الحقيقة الوحيد — لا مسح ولا حلقة اصطدام.
 * إعادة محاولة واحدة عند اصطدام نادر على refNumber.
 */
@Injectable()
export class RefNumberService {
  private readonly logger = new Logger('RefNumber');

  constructor(private readonly prisma: PrismaService) {}

  async generate(type: RefType): Promise<string> {
    const year = new Date().getFullYear();
    const key = `${type}-${year}`;

    const next = await this.nextValue(key);
    const candidate = `${key}-${String(next).padStart(6, '0')}`;

    // فحص نادر للتأكد من عدم وجود اصطدام مسبق
    const existing = await this.prisma.correspondence.findUnique({
      where: { refNumber: candidate },
      select: { id: true },
    });

    if (existing) {
      this.logger.warn(`اصطدام نادر على ${candidate} — إعادة محاولة`);
      const retry = await this.nextValue(key);
      return `${key}-${String(retry).padStart(6, '0')}`;
    }

    return candidate;
  }

  /** استعلام ذري واحد: زيادة العداد وإرجاع القيمة في خطوة واحدة */
  private async nextValue(key: string): Promise<number> {
    const rows = await this.prisma.$queryRawUnsafe<{ value: number }[]>(
      `INSERT INTO "Counter" (id, key, value)
       VALUES (gen_random_uuid(), $1, 1)
       ON CONFLICT (key) DO UPDATE SET value = "Counter".value + 1
       RETURNING value`,
      key,
    );
    return rows[0].value;
  }
}
