import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { CorrespondencesQueryDto } from './dto';
import {
  CorrespondenceDetailRow,
  CorrespondenceListRow,
  DETAIL_INCLUDE,
  LIST_INCLUDE,
} from './correspondences.constants';

@Injectable()
export class CorrespondencesQueryService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * نطاق الرؤية:
   *  - ADMIN / GM / DEPUTY_GM : كل المراسلات
   *  - DEPT_MANAGER           : مراسلات قسمه + ما أُحيل إليه + ما كوّن تكليفاته
   *  - EMPLOYEE               : ما كُلّف به أو أُحيل إليه أو صاغ ردوده فقط
   */
  buildScope(user: AuthUser): Prisma.CorrespondenceWhereInput {
    if (user.role === 'ADMIN' || user.role === 'GM' || user.role === 'DEPUTY_GM') {
      return {};
    }
    if (user.role === 'DEPT_MANAGER') {
      const or: Prisma.CorrespondenceWhereInput[] = [
        { referrals: { some: { toUserId: user.id } } },
        { tasks: { some: { assignedById: user.id } } },
      ];
      if (user.departmentId) or.push({ departmentId: user.departmentId });
      return { OR: or };
    }
    // EMPLOYEE
    return {
      OR: [
        { tasks: { some: { assignedToId: user.id } } },
        { referrals: { some: { toUserId: user.id } } },
        { replies: { some: { authorId: user.id } } },
      ],
    };
  }

  /** استعراض المراسلات الجذرية بنطاق الرؤية والفلترة والترقيم */
  async findAll(
    dto: CorrespondencesQueryDto,
    user: AuthUser,
  ): Promise<Paginated<CorrespondenceListRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    const filters: Prisma.CorrespondenceWhereInput[] = [this.buildScope(user)];
    // حصر القائمة في المحادثات الجذرية فقط حتى لا تتكرر الردود في صندوق البريد كبنود منفصلة
    filters.push({ parentId: null });

    if (dto.type) filters.push({ type: dto.type });
    if (dto.status) filters.push({ status: dto.status });
    if (dto.priority) filters.push({ priority: dto.priority });
    if (dto.departmentId) filters.push({ departmentId: dto.departmentId });
    if (dto.channel) filters.push({ channel: dto.channel });
    if (dto.q) {
      filters.push({
        OR: [
          { subject: { contains: dto.q, mode: 'insensitive' } },
          { refNumber: { contains: dto.q, mode: 'insensitive' } },
          { senderName: { contains: dto.q, mode: 'insensitive' } },
        ],
      });
    }
    const where: Prisma.CorrespondenceWhereInput = { AND: filters };

    const [total, data] = await this.prisma.$transaction([
      this.prisma.correspondence.count({ where }),
      this.prisma.correspondence.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: LIST_INCLUDE,
      }),
    ]);

    const now = new Date();
    const enrichedData = data.map((item: any) => {
      let isOverdue = false;
      let maxOverdueDays = 0;

      const dueDates: Date[] = [];
      if (item.referrals) {
        for (const r of item.referrals) {
          if (r.dueDate) dueDates.push(new Date(r.dueDate));
        }
      }
      if (item.tasks) {
        for (const t of item.tasks) {
          if (t.dueDate) dueDates.push(new Date(t.dueDate));
        }
      }

      for (const d of dueDates) {
        if (d < now) {
          isOverdue = true;
          const diffMs = now.getTime() - d.getTime();
          const days = Math.max(1, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
          if (days > maxOverdueDays) {
            maxOverdueDays = days;
          }
        }
      }

      return {
        ...item,
        isOverdue,
        overdueDays: maxOverdueDays,
      };
    });

    return { data: enrichedData, meta: buildPageMeta(page, limit, total) };
  }

  /** تفاصيل مراسلة — مع فرض نطاق الرؤية نفسه */
  async findOne(id: string, user: AuthUser): Promise<CorrespondenceDetailRow> {
    const corr = await this.prisma.correspondence.findUnique({
      where: { id },
      include: DETAIL_INCLUDE,
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');
    if (!(await this.canView(corr, user))) {
      throw new ForbiddenException('ليست لديك صلاحية الاطلاع على هذه المراسلة');
    }
    return corr;
  }

  /** فحص صلاحية الاطلاع على مراسلة محددة (تُستخدم أيضًا من وحدات أخرى) */
  async canView(
    corr: { id: string; departmentId: string | null },
    user: AuthUser,
  ): Promise<boolean> {
    if (user.role === 'ADMIN' || user.role === 'GM' || user.role === 'DEPUTY_GM') {
      return true;
    }
    const [assigned, referred, replied] = await Promise.all([
      this.prisma.task.count({
        where: { correspondenceId: corr.id, assignedToId: user.id },
      }),
      this.prisma.referral.count({
        where: { correspondenceId: corr.id, toUserId: user.id },
      }),
      this.prisma.reply.count({
        where: { correspondenceId: corr.id, authorId: user.id },
      }),
    ]);
    if (assigned + referred + replied > 0) return true;

    if (user.role === 'DEPT_MANAGER') {
      if (corr.departmentId && corr.departmentId === user.departmentId) return true;
      const createdByMe = await this.prisma.task.count({
        where: { correspondenceId: corr.id, assignedById: user.id },
      });
      return createdByMe > 0;
    }
    return false;
  }
}
