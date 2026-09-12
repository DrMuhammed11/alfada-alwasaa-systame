import { Prisma } from '@prisma/client';

export const USER_BRIEF = { id: true, name: true, email: true } as const;

/** حقول القائمة المختصرة */
export const LIST_INCLUDE = {
  department: { select: { id: true, name: true } },
  createdBy: { select: { id: true, name: true } },
  children: {
    select: { id: true, refNumber: true, createdAt: true, receivedAt: true, body: true },
    orderBy: { createdAt: 'desc' },
    take: 1,
  },
  _count: {
    select: {
      referrals: true,
      tasks: true,
      replies: true,
      attachments: true,
      children: true,
    },
  },
  referrals: {
    where: { status: 'OPEN', dueDate: { not: null } },
    select: { dueDate: true },
  },
  tasks: {
    where: { status: { in: ['PENDING', 'IN_PROGRESS'] }, dueDate: { not: null } },
    select: { dueDate: true },
  },
} satisfies Prisma.CorrespondenceInclude;

/** حقول التفاصيل الكاملة — تعرض سلسلة المحادثة كاملة بالتسلسل الزمني */
export const DETAIL_INCLUDE = {
  department: { select: { id: true, name: true } },
  createdBy: { select: { id: true, name: true } },
  parent: {
    select: {
      id: true,
      refNumber: true,
      subject: true,
      body: true,
      priority: true,
      status: true,
      type: true,
      senderName: true,
      senderEmail: true,
      senderPhone: true,
      receivedAt: true,
      sentAt: true,
      createdAt: true,
      messageId: true,
      sourceReplyId: true,
      attachments: true,
    },
  },
  children: {
    select: {
      id: true,
      refNumber: true,
      subject: true,
      body: true,
      priority: true,
      status: true,
      type: true,
      senderName: true,
      senderEmail: true,
      senderPhone: true,
      receivedAt: true,
      sentAt: true,
      createdAt: true,
      messageId: true,
      sourceReplyId: true,
      attachments: true,
    },
    orderBy: { createdAt: 'asc' },
  },
  referrals: {
    include: { fromUser: { select: USER_BRIEF }, toUser: { select: USER_BRIEF } },
  },
  tasks: {
    include: {
      assignedTo: { select: USER_BRIEF },
      assignedBy: { select: USER_BRIEF },
    },
  },
  replies: {
    include: {
      author: { select: USER_BRIEF },
      reviewedBy: { select: USER_BRIEF },
      approvedBy: { select: USER_BRIEF },
      attachments: true,
    },
    orderBy: { createdAt: 'asc' },
  },
  attachments: true,
} satisfies Prisma.CorrespondenceInclude;

export type CorrespondenceListRow = Prisma.CorrespondenceGetPayload<{
  include: typeof LIST_INCLUDE;
}>;
export type CorrespondenceDetailRow = Prisma.CorrespondenceGetPayload<{
  include: typeof DETAIL_INCLUDE;
}>;
