import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { buildPageMeta, Paginated } from '../common/types';
import { CreateUserDto, UpdateUserDto, UsersQueryDto } from './dto';

/** الحقول الآمنة — لا تُعاد كلمة المرور المشفرة أبدًا */
const SAFE_SELECT = {
  id: true,
  name: true,
  email: true,
  role: true,
  phone: true,
  jobTitle: true,
  isActive: true,
  departmentId: true,
  lastLoginAt: true,
  createdAt: true,
  updatedAt: true,
  department: { select: { id: true, name: true } },
} satisfies Prisma.UserSelect;

export type SafeUserRow = Prisma.UserGetPayload<{ select: typeof SAFE_SELECT }>;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async findAll(dto: UsersQueryDto): Promise<Paginated<SafeUserRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    const where: Prisma.UserWhereInput = {};
    if (dto.role) where.role = dto.role;
    if (dto.departmentId) where.departmentId = dto.departmentId;
    if (dto.isActive !== undefined) where.isActive = dto.isActive;
    if (dto.search && dto.search.trim().length > 0) {
      const q = dto.search.trim();
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
      ];
    }

    const [total, data] = await this.prisma.$transaction([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: SAFE_SELECT,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  async findOne(id: string): Promise<SafeUserRow> {
    const user = await this.prisma.user.findUnique({ where: { id }, select: SAFE_SELECT });
    if (!user) throw new NotFoundException('المستخدم غير موجود');
    return user;
  }

  async create(dto: CreateUserDto): Promise<SafeUserRow> {
    const email = dto.email.toLowerCase().trim();
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new BadRequestException('البريد الإلكتروني مستخدم مسبقًا');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        email,
        passwordHash,
        role: dto.role,
        departmentId: dto.departmentId,
        jobTitle: dto.jobTitle,
        phone: dto.phone,
      },
      select: SAFE_SELECT,
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'User',
      entityId: user.id,
      summary: `إنشاء حساب: ${user.name} (${user.email}) بدور ${user.role}`,
    });
    return user;
  }

  async update(id: string, dto: UpdateUserDto): Promise<SafeUserRow> {
    const existing = await this.prisma.user.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('المستخدم غير موجود');

    const data: Prisma.UserUpdateInput = {};
    if (dto.name) data.name = dto.name.trim();
    if (dto.email) data.email = dto.email.toLowerCase().trim();
    if (dto.role) data.role = dto.role;
    if (dto.jobTitle !== undefined) data.jobTitle = dto.jobTitle;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.isActive !== undefined) data.isActive = dto.isActive;
    if (dto.password) data.passwordHash = await bcrypt.hash(dto.password, 10);
    if (dto.departmentId !== undefined) {
      data.department = dto.departmentId
        ? { connect: { id: dto.departmentId } }
        : { disconnect: true };
    }

    const user = await this.prisma.user.update({ where: { id }, data, select: SAFE_SELECT });

    // إبطال كل جلسات المستخدم عند تغيير كلمة المرور أو الدور أو التعطيل
    const mustRevokeSessions = Boolean(dto.password) || Boolean(dto.role) || dto.isActive === false;
    if (mustRevokeSessions) {
      await this.prisma.refreshToken.updateMany({
        where: { userId: id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'User',
      entityId: id,
      summary: `تعديل حساب ${user.name} (${user.email})${mustRevokeSessions ? ' — وأُبطلت جلساته' : ''}`,
      metadata: { updatedFields: Object.keys(dto) },
    });
    return user;
  }

  /**
   * تعطيل الحساب بدلًا من حذفه —
   * الحذف ممنوع تصميميًا للحفاظ على سلامة سجل التدقيق وسلسلة المراسلات.
   */
  async deactivate(id: string): Promise<SafeUserRow> {
    const [user] = await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id },
        data: { isActive: false },
        select: SAFE_SELECT,
      }),
      // إنهاء كل جلسات الحساب المعطل فورًا
      this.prisma.refreshToken.updateMany({
        where: { userId: id, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);
    await this.audit.log({
      action: AuditAction.DEACTIVATE,
      entityType: 'User',
      entityId: id,
      summary: `تعطيل حساب ${user.name} (${user.email}) وإبطال جلساته`,
    });
    return user;
  }
}
