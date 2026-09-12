import { Injectable } from '@nestjs/common';
import { CorrespondenceStatus, CorrespondenceType, Priority } from '@prisma/client';
import { ParsedMail } from 'mailparser';
import { PrismaService } from '../prisma/prisma.service';
import { parseHeaderIds } from './incoming-mail.utils';

export interface ThreadRootRecord {
  id: string;
  refNumber: string;
  subject: string;
  priority: Priority;
  status: CorrespondenceStatus;
}

@Injectable()
export class IncomingMailMatcherService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * محرك مطابقة الخيط:
   * (أ) طابق رأس In-Reply-To/References مع messageId المحفوظ
   * (ب) إن لم يوجد، فطابق آخر صادر أُرسل لنفس بريد المُرسل خلال آخر 30 يومًا
   * (ج) البحث عن رقم مرجعي صريح في الموضوع أو النص
   */
  async findThreadRoot(
    parsed: ParsedMail,
    senderEmail: string,
    subject: string,
    body: string,
  ): Promise<ThreadRootRecord | null> {
    let threadRoot: ThreadRootRecord | null = null;

    // (أ) طابق رأس In-Reply-To/References مع messageId المحفوظ
    const candidateIds: string[] = [];
    const rawInReplyTo = parsed.inReplyTo || (parsed.headers && parsed.headers.get('in-reply-to'));
    const rawReferences = parsed.references || (parsed.headers && parsed.headers.get('references'));
    parseHeaderIds(rawInReplyTo, candidateIds);
    parseHeaderIds(rawReferences, candidateIds);

    if (candidateIds.length > 0) {
      const matchedCorr = await this.prisma.correspondence.findFirst({
        where: { messageId: { in: [...new Set(candidateIds)] } },
        select: { id: true, parentId: true },
      });
      if (matchedCorr) {
        const rootId = matchedCorr.parentId ?? matchedCorr.id;
        threadRoot = await this.prisma.correspondence.findUnique({
          where: { id: rootId },
          select: { id: true, refNumber: true, subject: true, priority: true, status: true },
        });
      }
    }

    // (ب) إن لم يوجد، فطابق آخر صادر أُرسل لنفس بريد المُرسل خلال آخر 30 يومًا
    if (!threadRoot) {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const lastOutgoing = await this.prisma.correspondence.findFirst({
        where: {
          type: CorrespondenceType.OUTGOING,
          sentAt: { gte: thirtyDaysAgo },
          OR: [
            { parent: { senderEmail } },
            { senderEmail },
          ],
        },
        orderBy: { sentAt: 'desc' },
        select: { id: true, parentId: true },
      });
      if (lastOutgoing) {
        const rootId = lastOutgoing.parentId ?? lastOutgoing.id;
        threadRoot = await this.prisma.correspondence.findUnique({
          where: { id: rootId },
          select: { id: true, refNumber: true, subject: true, priority: true, status: true },
        });
      }
    }

    // إجراء وقائي: البحث عن رقم مرجعي صريح في الموضوع إن وُجد
    if (!threadRoot) {
      const refMatch =
        subject.match(/(?:INC|OUT|INT)-\d{4}-\d{5,6}/i) ||
        body.match(/(?:INC|OUT|INT)-\d{4}-\d{5,6}/i);
      if (refMatch) {
        const referenced = await this.prisma.correspondence.findUnique({
          where: { refNumber: refMatch[0].toUpperCase() },
          select: { id: true, parentId: true },
        });
        if (referenced) {
          const rootId = referenced.parentId ?? referenced.id;
          threadRoot = await this.prisma.correspondence.findUnique({
            where: { id: rootId },
            select: { id: true, refNumber: true, subject: true, priority: true, status: true },
          });
        }
      }
    }

    // (د) توحيد رسائل نفس الشخص في محادثة واحدة (WhatsApp-style Threading):
    // إذا لم يتطابق ما سبق وتوفر بريد المرسل، نربط الرسالة بآخر محادثة قائمة لنفس المرسل
    if (!threadRoot && senderEmail && senderEmail.trim().length > 0) {
      const normalizedEmail = senderEmail.trim().toLowerCase();
      // البحث أولاً عن أحدث معاملة غير مغلقة/غير مؤرشفة لهذا الشخص
      let matchedPersonCorr = await this.prisma.correspondence.findFirst({
        where: {
          senderEmail: { equals: normalizedEmail, mode: 'insensitive' },
          status: { notIn: [CorrespondenceStatus.CLOSED, CorrespondenceStatus.ARCHIVED] },
        },
        orderBy: { updatedAt: 'desc' },
        select: { id: true, parentId: true },
      });

      // إذا لم توجد معاملة نشطة، نطابق أحدث معاملة سابقة للمرسل لإعادة فتحها كمحادثة موحدة ومستمرة
      if (!matchedPersonCorr) {
        matchedPersonCorr = await this.prisma.correspondence.findFirst({
          where: {
            senderEmail: { equals: normalizedEmail, mode: 'insensitive' },
          },
          orderBy: { updatedAt: 'desc' },
          select: { id: true, parentId: true },
        });
      }

      if (matchedPersonCorr) {
        const rootId = matchedPersonCorr.parentId ?? matchedPersonCorr.id;
        threadRoot = await this.prisma.correspondence.findUnique({
          where: { id: rootId },
          select: { id: true, refNumber: true, subject: true, priority: true, status: true },
        });
      }
    }

    return threadRoot;
  }
}
