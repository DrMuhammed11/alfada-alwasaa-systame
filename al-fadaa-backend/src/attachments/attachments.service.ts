import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
  Prisma,
  Role,
} from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import type { Response } from 'express';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import type { AuthUser } from '../common/types';

const ATTACHMENT_INCLUDE = {
  uploadedBy: { select: { id: true, name: true, email: true } },
} satisfies Prisma.AttachmentInclude;

export type AttachmentRow = Prisma.AttachmentGetPayload<{
  include: typeof ATTACHMENT_INCLUDE;
}>;

@Injectable()
export class AttachmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly correspondences: CorrespondencesService,
  ) {}

  private uploadDir(): string {
    return process.env.UPLOAD_DIR || './uploads';
  }

  /** رفع مرفق لمراسلة — متاح لمن يملك رؤيتها وقبل انتهاء دورتها */
  async createForCorrespondence(
    correspondenceId: string,
    file: Express.Multer.File,
    user: AuthUser,
  ): Promise<AttachmentRow> {
    const corr = await this.correspondences.findOne(correspondenceId, user);
    const closedStates: CorrespondenceStatus[] = [
      CorrespondenceStatus.SENT,
      CorrespondenceStatus.CLOSED,
      CorrespondenceStatus.ARCHIVED,
    ];
    if (closedStates.includes(corr.status)) {
      throw new BadRequestException('لا يمكن إرفاق ملفات لمراسلة منتهية');
    }
    return this.store(file, { correspondenceId }, user, corr.refNumber);
  }

  /** رفع مرفق لمسودة رد */
  async createForReply(
    replyId: string,
    file: Express.Multer.File,
    user: AuthUser,
  ): Promise<AttachmentRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id: replyId },
      include: { correspondence: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    await this.correspondences.findOne(reply.correspondenceId, user);
    if (reply.sentAt) {
      throw new BadRequestException('لا يمكن إرفاق ملفات لرد مُرسل');
    }
    return this.store(file, { replyId }, user, reply.correspondence.refNumber);
  }

  private async store(
    file: Express.Multer.File,
    link: { correspondenceId?: string; replyId?: string },
    user: AuthUser,
    refNumber: string,
  ): Promise<AttachmentRow> {
    const attachment = await this.prisma.attachment.create({
      data: {
        fileName: file.originalname,
        storedName: file.filename,
        mimeType: file.mimetype,
        size: file.size,
        correspondenceId: link.correspondenceId,
        replyId: link.replyId,
        uploadedById: user.id,
      },
      include: ATTACHMENT_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPLOAD,
      entityType: 'Attachment',
      entityId: attachment.id,
      summary: `رفع مرفق «${file.originalname}» (${(file.size / 1024).toFixed(1)}KB) على ${refNumber}`,
      metadata: { fileName: file.originalname, size: file.size, mimeType: file.mimetype },
    });
    return attachment;
  }

  /** تنزيل مرفق — مع فرض نطاق رؤية المراسلة/الرد */
  async download(id: string, res: Response, user: AuthUser): Promise<void> {
    const a = await this.prisma.attachment.findUnique({ where: { id } });
    if (!a) throw new NotFoundException('المرفق غير موجود');

    if (a.correspondenceId) {
      await this.correspondences.findOne(a.correspondenceId, user);
    } else if (a.replyId) {
      const reply = await this.prisma.reply.findUnique({ where: { id: a.replyId } });
      if (reply) await this.correspondences.findOne(reply.correspondenceId, user);
    }

    const filePath = path.join(this.uploadDir(), a.storedName);
    if (!fs.existsSync(filePath)) {
      throw new NotFoundException('ملف المرفق غير موجود على الخادم');
    }
    // دعم أسماء الملفات العربية في رأس التنزيل
    res.setHeader(
      'Content-Disposition',
      `attachment; filename*=UTF-8''${encodeURIComponent(a.fileName)}`,
    );
    res.setHeader('Content-Type', a.mimeType);
    res.sendFile(path.resolve(filePath));
  }

  /** حذف مرفق — رافعه أو المسؤول، وقبل انتهاء دورة المراسلة */
  async remove(id: string, user: AuthUser): Promise<{ deleted: true }> {
    const a = await this.prisma.attachment.findUnique({ where: { id } });
    if (!a) throw new NotFoundException('المرفق غير موجود');

    if (a.uploadedById !== user.id && user.role !== Role.ADMIN) {
      throw new BadRequestException('فقط من رفع الملف يمكنه حذفه');
    }
    if (a.correspondenceId) {
      const corr = await this.prisma.correspondence.findUnique({
        where: { id: a.correspondenceId },
      });
      if (corr) {
        const closedStates: CorrespondenceStatus[] = [
          CorrespondenceStatus.SENT,
          CorrespondenceStatus.CLOSED,
          CorrespondenceStatus.ARCHIVED,
        ];
        if (closedStates.includes(corr.status)) {
          throw new BadRequestException('لا يمكن حذف مرفقات مراسلة منتهية');
        }
      }
    }
    if (a.replyId) {
      const reply = await this.prisma.reply.findUnique({ where: { id: a.replyId } });
      if (reply?.sentAt) {
        throw new BadRequestException('لا يمكن حذف مرفقات رد مُرسل');
      }
    }

    await this.prisma.attachment.delete({ where: { id } });
    try {
      await fs.promises.unlink(path.join(this.uploadDir(), a.storedName));
    } catch {
      // الملف قد يكون محذوفًا من القرص مسبقًا — نتجاهل
    }

    await this.audit.log({
      action: AuditAction.DELETE,
      entityType: 'Attachment',
      entityId: id,
      summary: `حذف مرفق «${a.fileName}»`,
    });
    return { deleted: true };
  }
}
