import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesQueryService } from '../correspondences/correspondences-query.service';
import type { AuthUser } from '../common/types';

export interface DiffLine {
  type: 'added' | 'removed' | 'unchanged';
  line: string;
}

export function computeLineDiff(textA: string, textB: string): DiffLine[] {
  const linesA = textA ? textA.split(/\r?\n/) : [];
  const linesB = textB ? textB.split(/\r?\n/) : [];
  const m = linesA.length;
  const n = linesB.length;

  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i < m; i++) {
    for (let j = 0; j < n; j++) {
      if (linesA[i] === linesB[j]) {
        dp[i + 1][j + 1] = dp[i][j] + 1;
      } else {
        dp[i + 1][j + 1] = Math.max(dp[i + 1][j], dp[i][j + 1]);
      }
    }
  }

  const result: DiffLine[] = [];
  let i = m;
  let j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && linesA[i - 1] === linesB[j - 1]) {
      result.unshift({ type: 'unchanged', line: linesA[i - 1] });
      i--;
      j--;
    } else if (j > 0 && (i === 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      result.unshift({ type: 'added', line: linesB[j - 1] });
      j--;
    } else if (i > 0 && (j === 0 || dp[i][j - 1] < dp[i - 1][j])) {
      result.unshift({ type: 'removed', line: linesA[i - 1] });
      i--;
    }
  }
  return result;
}

@Injectable()
export class RepliesVersioningService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly correspondencesQuery: CorrespondencesQueryService,
  ) {}

  /** إنشاء أو حفظ نسخة جديدة غير قابلة للتعديل */
  async saveSnapshot(
    replyId: string,
    version: number,
    body: string,
    authorId: string,
    attachmentsSnapshot?: any,
  ) {
    const existing = await this.prisma.replyVersion.findUnique({
      where: { replyId_version: { replyId, version } },
    });
    if (existing) return existing;

    return this.prisma.replyVersion.create({
      data: {
        replyId,
        version,
        body,
        authorId,
        attachmentsSnapshot: attachmentsSnapshot ?? [],
      },
      include: {
        author: { select: { id: true, name: true, role: true, email: true } },
      },
    });
  }

  /**
   * فحص صلاحية الاطلاع على نسخ الرد — عبر نطاق الرؤية للمراسلة الأم.
   * حماية من IDOR: بدون هذا الفحص يستطيع أي موظف قراءة نص أي رد رسمي بسرد المعرفات.
   */
  private async assertCanViewReply(replyId: string, user: AuthUser): Promise<void> {
    const reply = await this.prisma.reply.findUnique({
      where: { id: replyId },
      select: { id: true, correspondenceId: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: reply.correspondenceId },
      select: { id: true, departmentId: true },
    });
    if (!corr || !(await this.correspondencesQuery.canView(corr, user))) {
      throw new ForbiddenException('ليست لديك صلاحية الاطلاع على نسخ هذا الرد');
    }
  }

  /** استعراض كافة الإصدارات التاريخية للرد مرتبة تصاعديًا — خاضع لنطاق الرؤية */
  async getVersions(replyId: string, user: AuthUser) {
    await this.assertCanViewReply(replyId, user);

    return this.prisma.replyVersion.findMany({
      where: { replyId },
      include: {
        author: { select: { id: true, name: true, role: true, email: true } },
      },
      orderBy: { version: 'asc' },
    });
  }

  /**
   * حساب الفرق السطري بين آخر نسخة مرفوضة والنسخة الحالية (أو نسختين محددتين)
   * — خاضع لنطاق الرؤية
   */
  async getDiff(replyId: string, user: AuthUser, fromVersion?: number, toVersion?: number) {
    await this.assertCanViewReply(replyId, user);

    const versions = await this.prisma.replyVersion.findMany({
      where: { replyId },
      orderBy: { version: 'asc' },
    });

    if (versions.length === 0) {
      return { diff: [], fromVersion: null, toVersion: null };
    }

    let baseVer = versions[0];
    let targetVer = versions[versions.length - 1];

    if (fromVersion !== undefined) {
      baseVer = versions.find((v) => v.version === fromVersion) ?? baseVer;
    } else if (versions.length > 1) {
      // افتراضيًا: النسخة قبل الأخيرة (المرفوضة أو السابقة)
      baseVer = versions[versions.length - 2];
    }

    if (toVersion !== undefined) {
      targetVer = versions.find((v) => v.version === toVersion) ?? targetVer;
    }

    const diff = computeLineDiff(baseVer.body, targetVer.body);
    return {
      diff,
      fromVersion: baseVer.version,
      toVersion: targetVer.version,
      baseCreatedAt: baseVer.createdAt,
      targetCreatedAt: targetVer.createdAt,
    };
  }
}
