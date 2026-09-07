import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { buildPageMeta, Paginated } from '../common/types';
import { CreateDepartmentDto, DepartmentsQueryDto, UpdateDepartmentDto } from './dto';

const DEPT_INCLUDE = {
  manager: { select: { id: true, name: true, email: true } },
  _count: { select: { users: true, correspondences: true } },
} satisfies Prisma.DepartmentInclude;

export type DepartmentRow = Prisma.DepartmentGetPayload<{ include: typeof DEPT_INCLUDE }>;

@Injectable()
export class DepartmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async findAll(dto: DepartmentsQueryDto): Promise<Paginated<DepartmentRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const [total, data] = await this.prisma.$transaction([
      this.prisma.department.count(),
      this.prisma.department.findMany({
        orderBy: { createdAt: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
        include: DEPT_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  async findOne(id: string): Promise<DepartmentRow> {
    const dept = await this.prisma.department.findUnique({
      where: { id },
      include: DEPT_INCLUDE,
    });
    if (!dept) throw new NotFoundException('القسم غير موجود');
    return dept;
  }

  async create(dto: CreateDepartmentDto): Promise<DepartmentRow> {
    const dept = await this.prisma.department.create({
      data: {
        name: dto.name.trim(),
        code: dto.code,
        managerId: dto.managerId,
      },
      include: DEPT_INCLUDE,
    });
    if (dto.managerId) {
      // المدير الجديد بلا قسم → نربطه بهذا القسم تلقائيًا
      await this.prisma.user.updateMany({
        where: { id: dto.managerId, departmentId: null },
        data: { departmentId: dept.id },
      });
    }
    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Department',
      entityId: dept.id,
      summary: `إنشاء قسم جديد: ${dept.name} (${dept.code})`,
    });
    return dept;
  }

  async update(id: string, dto: UpdateDepartmentDto): Promise<DepartmentRow> {
    const existing = await this.prisma.department.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('القسم غير موجود');

    const data: Prisma.DepartmentUpdateInput = {};
    if (dto.name) data.name = dto.name.trim();
    if (dto.code) data.code = dto.code;
    if (dto.managerId !== undefined) {
      data.manager = dto.managerId
        ? { connect: { id: dto.managerId } }
        : { disconnect: true };
    }

    const dept = await this.prisma.department.update({
      where: { id },
      data,
      include: DEPT_INCLUDE,
    });

    if (dto.managerId) {
      await this.prisma.user.updateMany({
        where: { id: dto.managerId, departmentId: null },
        data: { departmentId: id },
      });
    }

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Department',
      entityId: id,
      summary: `تعديل القسم: ${dept.name}`,
      metadata: { updatedFields: Object.keys(dto) },
    });
    return dept;
  }

  async remove(id: string): Promise<{ deleted: true }> {
    const usersCount = await this.prisma.user.count({ where: { departmentId: id } });
    if (usersCount > 0) {
      throw new BadRequestException(
        `لا يمكن حذف القسم لاحتوائه ${usersCount} مستخدم — انقلهم إلى قسم آخر أولًا`,
      );
    }
    const dept = await this.prisma.department.delete({ where: { id } });
    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Department',
      entityId: id,
      summary: `حذف القسم: ${dept.name} (${dept.code})`,
    });
    return { deleted: true };
  }
}
