import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { AuditAction, CorrespondenceStatus, NotificationType, Prisma, Role, TaskStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { CreateTaskDto, TasksQueryDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto';
import { NotificationsService } from '../notifications/notifications.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { canAssignTask } from '../security/business-policies';
import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { OutboxEventType } from '../outbox/outbox.types';

const USER_BRIEF = { id: true, name: true, email: true } as const;

const TASK_INCLUDE = {
  assignedTo: { select: USER_BRIEF },
  assignedBy: { select: USER_BRIEF },
  correspondence: {
    select: { id: true, refNumber: true, subject: true, status: true, priority: true },
  },
} satisfies Prisma.TaskInclude;

export type TaskRow = Prisma.TaskGetPayload<{ include: typeof TASK_INCLUDE }>;

@Injectable()
export class TasksService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    private readonly correspondences: CorrespondencesService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
  ) {}

  /** إنشاء تكليف — مدير القسم يكلّف موظفي قسمه فقط */
  async create(correspondenceId: string, dto: CreateTaskDto, user: AuthUser) {
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: correspondenceId },
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    // سد ثغرة الرؤية: فحص حق اطلاع المستخدم على المراسلة قبل كل شيء
    const canView = await this.correspondences.canView(corr, user);
    if (!canView) {
      throw new ForbiddenException('ليست لديك صلاحية الاطلاع على هذه المراسلة');
    }

    const assignee = await this.prisma.user.findUnique({
      where: { id: dto.assignedToId },
    });

    const policy = canAssignTask(user, assignee, corr);
    if (!policy.allowed) {
      throw new BadRequestException(policy.reason);
    }

    if (dto.referralId) {
      const referral = await this.prisma.referral.findUnique({
        where: { id: dto.referralId },
      });
      if (!referral || referral.correspondenceId !== correspondenceId) {
        throw new BadRequestException('الإحالة المحددة لا تنتمي لهذه المراسلة');
      }
    }

    const task = await this.prisma.$transaction(async (tx) => {
      const created = await tx.task.create({
        data: {
          correspondenceId,
          referralId: dto.referralId,
          title: dto.title.trim(),
          description: dto.description,
          assignedById: user.id,
          assignedToId: assignee!.id,
          dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        },
        include: TASK_INCLUDE,
      });

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.TASK_ASSIGNED,
          payload: {
            audit: {
              action: AuditAction.ASSIGN,
              entityType: 'Task',
              entityId: created.id,
              summary: `تكليف ${assignee!.name} بـ«${created.title}» على المراسلة ${corr.refNumber}`,
              metadata: {
                correspondenceId: corr.id,
                correspondenceRef: corr.refNumber,
                assignee: assignee!.email,
              },
              userId: user.id,
            },
            notification: {
              type: NotificationType.NEW_TASK,
              userId: assignee!.id,
              title: `تكليف جديد: ${created.title}`,
              body: `تم تكليفك بمهمة على المراسلة ${corr.refNumber}`,
              link: `/tasks/${created.id}`,
              entityType: 'Task',
              entityId: created.id,
            },
          },
        });
      }

      return created;
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.ASSIGN,
        entityType: 'Task',
        entityId: task.id,
        summary: `تكليف ${assignee!.name} بـ«${task.title}» على المراسلة ${corr.refNumber}`,
        metadata: {
          correspondenceId: corr.id,
          correspondenceRef: corr.refNumber,
          assignee: assignee!.email,
        },
      });

      // إشعار الموظف المكلّف فورًا
      await this.notifications.notifyTaskAssigned({
        toUserId: assignee!.id,
        actorName: user.name,
        taskTitle: task.title,
        refNumber: corr.refNumber,
        correspondenceId: corr.id,
        dueDate: task.dueDate,
      });
    }

    return task;
  }

  /** مهامي (الموظف) */
  async findMine(dto: TasksQueryDto, user: AuthUser): Promise<Paginated<TaskRow>> {
    return this.paginated(
      { assignedToId: user.id, ...(dto.status ? { status: dto.status } : {}) },
      dto,
    );
  }

  /** كل التكليفات (الإدارة ومديرو الأقسام) */
  async findAll(dto: TasksQueryDto, user: AuthUser): Promise<Paginated<TaskRow>> {
    if (user.role === Role.EMPLOYEE) {
      throw new ForbiddenException('استخدم المسار /tasks/my لعرض مهامك');
    }
    let where: Prisma.TaskWhereInput = dto.status ? { status: dto.status } : {};
    if (user.role === Role.DEPT_MANAGER) {
      where = {
        AND: [
          where,
          {
            OR: [
              { assignedById: user.id },
              ...(user.departmentId
                ? [{ correspondence: { departmentId: user.departmentId } }]
                : []),
            ],
          },
        ],
      };
    }
    return this.paginated(where, dto);
  }

  private async paginated(
    where: Prisma.TaskWhereInput,
    dto: TasksQueryDto,
  ): Promise<Paginated<TaskRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const [total, data] = await this.prisma.$transaction([
      this.prisma.task.count({ where }),
      this.prisma.task.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: TASK_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  /** تعديل بيانات التكليف — منشئه فقط وقبل اكتماله */
  async update(id: string, dto: UpdateTaskDto, user: AuthUser): Promise<TaskRow> {
    const task = await this.prisma.task.findUnique({
      where: { id },
      include: TASK_INCLUDE,
    });
    if (!task) throw new NotFoundException('التكليف غير موجود');

    if (task.assignedById !== user.id && user.role !== Role.ADMIN) {
      throw new ForbiddenException('فقط منشئ التكليف يمكنه تعديله');
    }
    if (task.status !== TaskStatus.PENDING && task.status !== TaskStatus.IN_PROGRESS) {
      throw new BadRequestException('لا يمكن تعديل تكليف منجز أو ملغى');
    }

    const data: Prisma.TaskUpdateInput = {};
    if (dto.title) data.title = dto.title.trim();
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.dueDate !== undefined) data.dueDate = dto.dueDate ? new Date(dto.dueDate) : null;

    const updated = await this.prisma.task.update({
      where: { id },
      data,
      include: TASK_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Task',
      entityId: id,
      summary: `تعديل التكليف «${updated.title}»`,
      metadata: { updatedFields: Object.keys(dto) },
    });
    return updated;
  }

  /**
   * تغيير حالة التكليف يدويًا:
   *  - IN_PROGRESS : المكلَّف يبدأ العمل (من PENDING)
   *  - CANCELLED   : منشئ التكليف يلغيه
   * أما SUBMITTED و DONE فتتغير تلقائيًا عبر دورة الردود.
   */
  async updateStatus(id: string, dto: UpdateTaskStatusDto, user: AuthUser): Promise<TaskRow> {
    const task = await this.prisma.task.findUnique({
      where: { id },
      include: TASK_INCLUDE,
    });
    if (!task) throw new NotFoundException('التكليف غير موجود');

    if (dto.status === TaskStatus.IN_PROGRESS) {
      if (task.assignedToId !== user.id) {
        throw new ForbiddenException('فقط المكلَّف يمكنه بدء التنفيذ');
      }
      if (task.status !== TaskStatus.PENDING) {
        throw new BadRequestException('يمكن البدء من حالة PENDING فقط');
      }
    } else if (dto.status === TaskStatus.CANCELLED) {
      if (task.assignedById !== user.id && user.role !== Role.ADMIN) {
        throw new ForbiddenException('فقط منشئ التكليف يمكنه إلغاءه');
      }
      if (task.status !== TaskStatus.PENDING && task.status !== TaskStatus.IN_PROGRESS) {
        throw new BadRequestException('لا يمكن إلغاء تكليف منجز');
      }
    } else if (dto.status === TaskStatus.DONE) {
      const canMarkDone =
        task.assignedToId === user.id ||
        task.assignedById === user.id ||
        user.role === Role.ADMIN ||
        user.role === Role.GM ||
        user.role === Role.DEPUTY_GM ||
        user.role === Role.DEPT_MANAGER;
      if (!canMarkDone) {
        throw new ForbiddenException('ليس لديك صلاحية إنجاز هذا التكليف');
      }
      if (task.status === TaskStatus.DONE) {
        throw new BadRequestException('التكليف منجز بالفعل');
      }
      if (task.status === TaskStatus.CANCELLED) {
        throw new BadRequestException('لا يمكن إنجاز تكليف ملغى');
      }
    } else {
      throw new BadRequestException(
        'هذه الحالة تتغير تلقائيًا عبر دورة الردود (SUBMITTED / DONE)',
      );
    }

    const updateData: Prisma.TaskUpdateInput = { status: dto.status };
    if (dto.status === TaskStatus.DONE) {
      updateData.doneAt = new Date();
      if (dto.completionNote?.trim()) {
        const note = dto.completionNote.trim();
        updateData.description = task.description
          ? `${task.description}\n\n[إنجاز المهمة]: ${note}`
          : `[إنجاز المهمة]: ${note}`;
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.task.updateMany({
        where: {
          id,
          status:
            dto.status === TaskStatus.IN_PROGRESS
              ? TaskStatus.PENDING
              : dto.status === TaskStatus.DONE
                ? { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS, TaskStatus.SUBMITTED] }
                : { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
        },
        data: updateData,
      });
      if (res.count === 0) {
        const current = await tx.task.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('التكليف غير موجود');
        throw new BadRequestException(
          `تم تغيير حالة التكليف للتو من قِبل مستخدم آخر (الحالة الحالية: «${current.status}»)`,
        );
      }

      if (dto.status === TaskStatus.DONE) {
        await tx.correspondence.update({
          where: { id: task.correspondenceId },
          data: { updatedAt: new Date() },
        });
      }

      return tx.task.findUniqueOrThrow({
        where: { id },
        include: TASK_INCLUDE,
      });
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Task',
      entityId: id,
      summary: `تغيير حالة التكليف «${updated.title}» إلى ${dto.status}`,
      metadata: { from: task.status, to: dto.status, completionNote: dto.completionNote },
    });

    // إشعار المكلّف بإلغاء التكليف (في حالة الإلغاء)
    if (dto.status === TaskStatus.CANCELLED) {
      await this.notifications.notifyTaskCancelled({
        toUserId: updated.assignedToId,
        actorName: user.name,
        taskTitle: updated.title,
        correspondenceId: updated.correspondenceId,
      });
    } else if (dto.status === TaskStatus.DONE && updated.assignedById !== user.id) {
      await this.notifications.notify({
        userId: updated.assignedById,
        type: NotificationType.NEW_TASK,
        title: `تم إنجاز التكليف: ${updated.title}`,
        body: `قام ${user.name} بإنجاز التكليف بنجاح${dto.completionNote ? ` — ملاحظة: ${dto.completionNote}` : ''}.`,
        entityType: 'Correspondence',
        entityId: updated.correspondenceId,
      });
    }

    return updated;
  }
}
