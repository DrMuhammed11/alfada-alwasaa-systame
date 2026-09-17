import * as crypto from 'crypto';
import { Injectable, Logger } from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { getRequestContext } from '../common/context/request-context';
import { buildPageMeta, Paginated } from '../common/types';
import { AuditQueryDto } from './dto';

export const GENESIS_HASH = '0000000000000000000000000000000000000000000000000000000000000000';

export interface AuditVerificationResult {
  isTamperFree: boolean;
  totalVerified: number;
  chainStatus: 'VERIFIED_INTACT' | 'TAMPER_DETECTED' | 'EMPTY';
  verifiedUntil: string;
  details: string;
  brokenRecordId: string | null;
}

export function computeAuditHash(payload: {
  previousHash: string;
  action: string;
  userId?: string | null;
  entityType?: string | null;
  entityId?: string | null;
  createdAt: string;
  summary?: string | null;
  metadata?: unknown;
}): string {
  const content = JSON.stringify({
    previousHash: payload.previousHash,
    action: payload.action,
    userId: payload.userId ?? '',
    entityType: payload.entityType ?? '',
    entityId: payload.entityId ?? '',
    createdAt: payload.createdAt,
    summary: payload.summary ?? '',
    metadata: payload.metadata ?? null,
  });
  return crypto.createHash('sha256').update(content).digest('hex');
}

export type AuditLogWithUser = Prisma.AuditLogGetPayload<{
  include: { user: { select: { id: true; name: true; email: true; role: true } } };
}>;

export interface AuditEntry {
  action: AuditAction;
  summary?: string;
  entityType?: string;
  entityId?: string;
  metadata?: Prisma.InputJsonValue;
  /** تجاوز هوية المستخدم — مثل تسجيل الدخول قبل توفر سياق JWT */
  userId?: string;
}

/**
 * خدمة سجل التدقيق — القلب الرقابي للنظام.
 * كل حدث مهم (إحالة/تكليف/اعتماد/إرسال...) يمر من هنا.
 * الجدول غير قابل للتعديل أو الحذف ومحمي بسلسلة تشفير SHA-256 (Merkle Hash Chain).
 */
@Injectable()
export class AuditService {
  private readonly logger = new Logger('Audit');

  constructor(private readonly prisma: PrismaService) {}

  /**
   * كتابة حدث في سجل التدقيق موقّعاً بهاش SHA-256 ومربوطاً بالسجل السابق.
   * لا يرمي استثناءً أبدًا — فشل التسجيل يُسجَّل كخطأ ولا يُفشل العملية التجارية.
   */
  async log(entry: AuditEntry): Promise<void> {
    try {
      const ctx = getRequestContext();
      let metadata = entry.metadata;
      if (ctx.requestId) {
        if (metadata && typeof metadata === 'object' && !Array.isArray(metadata)) {
          metadata = { ...(metadata as Record<string, unknown>), requestId: ctx.requestId };
        } else if (!metadata) {
          metadata = { requestId: ctx.requestId };
        }
      }

      // جلب بصمة السجل السابق لربط السلسلة المشفرة
      let previousHash = GENESIS_HASH;
      try {
        const lastLog = await this.prisma.auditLog.findFirst({
          orderBy: { createdAt: 'desc' },
          select: { recordHash: true },
        });
        if (lastLog?.recordHash) {
          previousHash = lastLog.recordHash;
        }
      } catch {
        // في حال تعذر جلب السجل الأخير يتم الاعتماد على الـ Genesis Hash
      }

      const now = new Date();
      const recordHash = computeAuditHash({
        previousHash,
        action: entry.action,
        userId: entry.userId ?? ctx.userId ?? null,
        entityType: entry.entityType,
        entityId: entry.entityId,
        createdAt: now.toISOString(),
        summary: entry.summary,
        metadata,
      });

      await this.prisma.auditLog.create({
        data: {
          action: entry.action,
          summary: entry.summary,
          entityType: entry.entityType,
          entityId: entry.entityId,
          metadata,
          userId: entry.userId ?? ctx.userId ?? null,
          ipAddress: ctx.ip,
          userAgent: ctx.userAgent,
          previousHash,
          recordHash,
          createdAt: now,
        },
      });
    } catch (e) {
      this.logger.error(
        `تعذّر تسجيل حدث التدقيق (${entry.action}): ${(e as Error).message}`,
      );
    }
  }

  /**
   * فحص النزاهة التشفيرية لسلسلة سجلات التدقيق والتأكد من خلوها من أي تلاعب
   */
  async verifyIntegrity(limit: number = 1000): Promise<AuditVerificationResult> {
    const logs = await this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'asc' },
      take: limit,
      select: {
        id: true,
        action: true,
        userId: true,
        entityType: true,
        entityId: true,
        summary: true,
        metadata: true,
        createdAt: true,
        previousHash: true,
        recordHash: true,
      },
    });

    if (logs.length === 0) {
      return {
        isTamperFree: true,
        totalVerified: 0,
        chainStatus: 'EMPTY',
        verifiedUntil: new Date().toISOString(),
        details: 'لا توجد سجلات تدقيق في قاعدة البيانات بعد',
        brokenRecordId: null,
      };
    }

    let verifiedCount = 0;
    let expectedPreviousHash: string | null = null;

    for (const log of logs) {
      if (!log.recordHash) {
        continue;
      }

      const expectedRecordHash = computeAuditHash({
        previousHash: log.previousHash ?? GENESIS_HASH,
        action: log.action,
        userId: log.userId,
        entityType: log.entityType,
        entityId: log.entityId,
        createdAt: log.createdAt.toISOString(),
        summary: log.summary,
        metadata: log.metadata,
      });

      // 1. فحص صحة محتوى السجل
      if (log.recordHash !== expectedRecordHash) {
        return {
          isTamperFree: false,
          totalVerified: verifiedCount,
          chainStatus: 'TAMPER_DETECTED',
          verifiedUntil: log.createdAt.toISOString(),
          details: `تم اكتشاف تلاعب في محتوى السجل [${log.id}]: البصمة المحسوبة لا تطابق البصمة المسجلة!`,
          brokenRecordId: log.id,
        };
      }

      // 2. فحص سلامة الربط بالسجل السابق
      if (expectedPreviousHash !== null && log.previousHash !== expectedPreviousHash) {
        return {
          isTamperFree: false,
          totalVerified: verifiedCount,
          chainStatus: 'TAMPER_DETECTED',
          verifiedUntil: log.createdAt.toISOString(),
          details: `تم اكتشاف انقطاع في سلسلة التدقيق عند السجل [${log.id}]: رابط السجل السابق مكسور!`,
          brokenRecordId: log.id,
        };
      }

      expectedPreviousHash = log.recordHash;
      verifiedCount++;
    }

    return {
      isTamperFree: true,
      totalVerified: verifiedCount,
      chainStatus: 'VERIFIED_INTACT',
      verifiedUntil: logs[logs.length - 1].createdAt.toISOString(),
      details: `تم فحص وتأكيد سلامة سلسلة التدقيق المشفرة بنجاح لـ ${verifiedCount} سجلاً خالية تماماً من أي تلاعب`,
      brokenRecordId: null,
    };
  }

  /** استعراض السجل مع تصفية وتقسيم صفحات — للمسؤول والمدير العام فقط */
  async findAll(dto: AuditQueryDto): Promise<Paginated<AuditLogWithUser>> {
    const { page, limit, skip, take } = {
      page: dto.page ?? 1,
      limit: dto.limit ?? 20,
      skip: ((dto.page ?? 1) - 1) * (dto.limit ?? 20),
      take: dto.limit ?? 20,
    };

    const where: Prisma.AuditLogWhereInput = {};
    if (dto.userId) where.userId = dto.userId;
    if (dto.action) where.action = dto.action;
    if (dto.entityType) where.entityType = dto.entityType;
    if (dto.entityId) where.entityId = dto.entityId;
    if (dto.from || dto.to) {
      where.createdAt = {
        ...(dto.from ? { gte: new Date(dto.from) } : {}),
        ...(dto.to ? { lte: new Date(dto.to) } : {}),
      };
    }

    const [total, data] = await this.prisma.$transaction([
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take,
        include: {
          user: { select: { id: true, name: true, email: true, role: true } },
        },
      }),
    ]);

    return { data, meta: buildPageMeta(page, limit, total) };
  }
}
