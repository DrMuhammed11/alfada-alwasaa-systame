import { Injectable, Logger } from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { getRequestContext } from '../common/context/request-context';
import { buildPageMeta, Paginated } from '../common/types';
import { AuditQueryDto } from './dto';

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
 * الجدول غير قابل للتعديل أو الحذف (يُفرض عبر Trigger في قاعدة البيانات).
 */
@Injectable()
export class AuditService {
  private readonly logger = new Logger('Audit');

  constructor(private readonly prisma: PrismaService) {}

  /**
   * كتابة حدث في سجل التدقيق.
   * لا يرمي استثناءً أبدًا — فشل التسجيل يُسجَّل كخطأ ولا يُفشل العملية التجارية.
   * (IP والمتصفح يُلتقطان تلقائيًا من سياق الطلب)
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
        },
      });
    } catch (e) {
      this.logger.error(
        `تعذّر تسجيل حدث التدقيق (${entry.action}): ${(e as Error).message}`,
      );
    }
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
