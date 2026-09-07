import { SlaReminderType } from '@prisma/client';

export interface SlaItemSummary {
  entityType: 'Referral' | 'Task';
  entityId: string;
  correspondenceId: string;
  correspondenceRef: string;
  title: string;
  assignedUserId: string;
  assignedUserName: string;
  departmentId?: string | null;
  departmentName?: string | null;
  dueDate: Date;
  daysOverdue: number;
}

export interface DepartmentOverdueEscalation {
  departmentId: string;
  departmentName: string;
  count: number;
  maxDaysOverdue: number;
  items: SlaItemSummary[];
}
