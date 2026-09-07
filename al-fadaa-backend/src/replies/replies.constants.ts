import { Prisma } from '@prisma/client';

export const USER_BRIEF = { id: true, name: true, email: true } as const;

export const REPLY_INCLUDE = {
  author: { select: USER_BRIEF },
  reviewedBy: { select: USER_BRIEF },
  approvedBy: { select: USER_BRIEF },
  task: { select: { id: true, title: true, status: true } },
  correspondence: { select: { id: true, refNumber: true, subject: true, status: true, priority: true } },
  attachments: true,
  approvalSteps: {
    orderBy: { level: 'asc' },
    include: { approver: { select: USER_BRIEF } },
  },
} satisfies Prisma.ReplyInclude;

export type ReplyRow = Prisma.ReplyGetPayload<{ include: typeof REPLY_INCLUDE }>;
