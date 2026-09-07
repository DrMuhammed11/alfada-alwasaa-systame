import { BadRequestException } from '@nestjs/common';
import { CorrespondenceStatus } from '@prisma/client';
import {
  CorrespondenceAction,
  canTransition,
  getNextStatus,
  assertTransition,
  getAllowedStatusesForAction,
  getAllowedActions,
  CORRESPONDENCE_TRANSITIONS,
} from './correspondence-state-machine';

describe('CorrespondenceStateMachine', () => {
  describe('دورة الحياة الطبيعية المعتمدة (Happy Path)', () => {
    it('1. الاستلام ➔ الدراسة: من RECEIVED إلى UNDER_REVIEW عبر REVIEW', () => {
      expect(canTransition(CorrespondenceStatus.RECEIVED, CorrespondenceAction.REVIEW)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.RECEIVED, CorrespondenceAction.REVIEW)).toBe(
        CorrespondenceStatus.UNDER_REVIEW,
      );
      expect(assertTransition(CorrespondenceStatus.RECEIVED, CorrespondenceAction.REVIEW)).toBe(
        CorrespondenceStatus.UNDER_REVIEW,
      );
    });

    it('2. الدراسة ➔ الإحالة: من UNDER_REVIEW إلى REFERRED عبر REFER', () => {
      expect(canTransition(CorrespondenceStatus.UNDER_REVIEW, CorrespondenceAction.REFER)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.UNDER_REVIEW, CorrespondenceAction.REFER)).toBe(
        CorrespondenceStatus.REFERRED,
      );
      expect(assertTransition(CorrespondenceStatus.UNDER_REVIEW, CorrespondenceAction.REFER)).toBe(
        CorrespondenceStatus.REFERRED,
      );
    });

    it('3. الإحالة ➔ بدء الإعداد: من REFERRED إلى IN_PROGRESS عبر START_DRAFT', () => {
      expect(canTransition(CorrespondenceStatus.REFERRED, CorrespondenceAction.START_DRAFT)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.REFERRED, CorrespondenceAction.START_DRAFT)).toBe(
        CorrespondenceStatus.IN_PROGRESS,
      );
      expect(assertTransition(CorrespondenceStatus.REFERRED, CorrespondenceAction.START_DRAFT)).toBe(
        CorrespondenceStatus.IN_PROGRESS,
      );
    });

    it('4. الإعداد ➔ بانتظار الاعتماد: من IN_PROGRESS إلى PENDING_APPROVAL عبر SUBMIT_REPLY', () => {
      expect(canTransition(CorrespondenceStatus.IN_PROGRESS, CorrespondenceAction.SUBMIT_REPLY)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.IN_PROGRESS, CorrespondenceAction.SUBMIT_REPLY)).toBe(
        CorrespondenceStatus.PENDING_APPROVAL,
      );
      expect(assertTransition(CorrespondenceStatus.IN_PROGRESS, CorrespondenceAction.SUBMIT_REPLY)).toBe(
        CorrespondenceStatus.PENDING_APPROVAL,
      );
    });

    it('5. بانتظار الاعتماد ➔ معتمدة: من PENDING_APPROVAL إلى APPROVED عبر APPROVE_REPLY', () => {
      expect(canTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.APPROVE_REPLY)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.APPROVE_REPLY)).toBe(
        CorrespondenceStatus.APPROVED,
      );
      expect(assertTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.APPROVE_REPLY)).toBe(
        CorrespondenceStatus.APPROVED,
      );
    });

    it('6. معتمدة ➔ مُرسلة: من APPROVED إلى SENT عبر SEND_REPLY', () => {
      expect(canTransition(CorrespondenceStatus.APPROVED, CorrespondenceAction.SEND_REPLY)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.APPROVED, CorrespondenceAction.SEND_REPLY)).toBe(
        CorrespondenceStatus.SENT,
      );
      expect(assertTransition(CorrespondenceStatus.APPROVED, CorrespondenceAction.SEND_REPLY)).toBe(
        CorrespondenceStatus.SENT,
      );
    });

    it('7. مُرسلة ➔ مغلقة: من SENT إلى CLOSED عبر CLOSE', () => {
      expect(canTransition(CorrespondenceStatus.SENT, CorrespondenceAction.CLOSE)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.SENT, CorrespondenceAction.CLOSE)).toBe(
        CorrespondenceStatus.CLOSED,
      );
      expect(assertTransition(CorrespondenceStatus.SENT, CorrespondenceAction.CLOSE)).toBe(
        CorrespondenceStatus.CLOSED,
      );
    });

    it('8. مغلقة ➔ مؤرشفة: من CLOSED إلى ARCHIVED عبر ARCHIVE', () => {
      expect(canTransition(CorrespondenceStatus.CLOSED, CorrespondenceAction.ARCHIVE)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.CLOSED, CorrespondenceAction.ARCHIVE)).toBe(
        CorrespondenceStatus.ARCHIVED,
      );
      expect(assertTransition(CorrespondenceStatus.CLOSED, CorrespondenceAction.ARCHIVE)).toBe(
        CorrespondenceStatus.ARCHIVED,
      );
    });
  });

  describe('مسار الرفض وإعادة الرفع (Rejection & Resubmission Loop)', () => {
    it('مسار الرفض: يعيد الرد من PENDING_APPROVAL إلى IN_PROGRESS عبر REJECT_REPLY', () => {
      expect(canTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.REJECT_REPLY)).toBe(true);
      expect(getNextStatus(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.REJECT_REPLY)).toBe(
        CorrespondenceStatus.IN_PROGRESS,
      );
      expect(assertTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.REJECT_REPLY)).toBe(
        CorrespondenceStatus.IN_PROGRESS,
      );
    });

    it('إعادة الرفع بعد التعديل: ينقل من IN_PROGRESS إلى PENDING_APPROVAL مجدداً', () => {
      expect(canTransition(CorrespondenceStatus.IN_PROGRESS, CorrespondenceAction.SUBMIT_REPLY)).toBe(true);
      expect(assertTransition(CorrespondenceStatus.IN_PROGRESS, CorrespondenceAction.SUBMIT_REPLY)).toBe(
        CorrespondenceStatus.PENDING_APPROVAL,
      );
    });
  });

  describe('مسار إعادة الفتح عند تعقيب العميل (Thread Reopen)', () => {
    it('يسمح بإعادة فتح المراسلة المُرسلة والمغلقة والمؤرشفة عبر REOPEN', () => {
      for (const status of [
        CorrespondenceStatus.SENT,
        CorrespondenceStatus.CLOSED,
        CorrespondenceStatus.ARCHIVED,
      ]) {
        expect(canTransition(status, CorrespondenceAction.REOPEN)).toBe(true);
        expect(getNextStatus(status, CorrespondenceAction.REOPEN)).toBe(
          CorrespondenceStatus.IN_PROGRESS,
        );
      }
    });
  });

  describe('الانتقالات الممنوعة ورمي BadRequestException مع الرسالة العربية', () => {
    it('يمنع إحالة مراسلة مؤرشفة ويرمي استثناء بالرسالة العربية الصحيحة', () => {
      expect(canTransition(CorrespondenceStatus.ARCHIVED, CorrespondenceAction.REFER)).toBe(false);
      expect(() =>
        assertTransition(CorrespondenceStatus.ARCHIVED, CorrespondenceAction.REFER),
      ).toThrow(BadRequestException);

      expect(() =>
        assertTransition(CorrespondenceStatus.ARCHIVED, CorrespondenceAction.REFER),
      ).toThrow('لا يمكن إحالة مراسلة في حالة «ARCHIVED»');
    });

    it('يمنع إرسال رد على مراسلة لا تزال قيد الدراسة', () => {
      expect(canTransition(CorrespondenceStatus.UNDER_REVIEW, CorrespondenceAction.SEND_REPLY)).toBe(false);
      expect(() =>
        assertTransition(CorrespondenceStatus.UNDER_REVIEW, CorrespondenceAction.SEND_REPLY),
      ).toThrow('لا يمكن إرسال الرد على مراسلة في حالة «UNDER_REVIEW»');
    });

    it('يمنع اعتماد رد على مراسلة مغلقة', () => {
      expect(canTransition(CorrespondenceStatus.CLOSED, CorrespondenceAction.APPROVE_REPLY)).toBe(false);
      expect(() =>
        assertTransition(CorrespondenceStatus.CLOSED, CorrespondenceAction.APPROVE_REPLY),
      ).toThrow('لا يمكن اعتماد الرد على مراسلة في حالة «CLOSED»');
    });

    it('يمنع إغلاق مراسلة في حالة PENDING_APPROVAL مباشرة', () => {
      expect(canTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.CLOSE)).toBe(false);
      expect(() =>
        assertTransition(CorrespondenceStatus.PENDING_APPROVAL, CorrespondenceAction.CLOSE),
      ).toThrow('لا يمكن إغلاق المراسلة على مراسلة في حالة «PENDING_APPROVAL»');
    });
  });

  describe('دوال الاستعلام عن الحالات والإجراءات', () => {
    it('getAllowedStatusesForAction(CLOSE) تطابق الحالات القابلة للإغلاق', () => {
      const closable = getAllowedStatusesForAction(CorrespondenceAction.CLOSE);
      expect(closable).toContain(CorrespondenceStatus.RECEIVED);
      expect(closable).toContain(CorrespondenceStatus.UNDER_REVIEW);
      expect(closable).toContain(CorrespondenceStatus.SENT);
      expect(closable).not.toContain(CorrespondenceStatus.CLOSED);
      expect(closable).not.toContain(CorrespondenceStatus.ARCHIVED);
    });

    it('getAllowedStatusesForAction(ARCHIVE) تطابق الحالات القابلة للأرشفة', () => {
      const archivable = getAllowedStatusesForAction(CorrespondenceAction.ARCHIVE);
      expect(archivable).toContain(CorrespondenceStatus.RECEIVED);
      expect(archivable).toContain(CorrespondenceStatus.UNDER_REVIEW);
      expect(archivable).toContain(CorrespondenceStatus.SENT);
      expect(archivable).toContain(CorrespondenceStatus.CLOSED);
      expect(archivable).not.toContain(CorrespondenceStatus.ARCHIVED);
    });

    it('getAllowedStatusesForAction(REFER) تطابق الحالات القابلة للإحالة', () => {
      const referable = getAllowedStatusesForAction(CorrespondenceAction.REFER);
      expect(referable).toContain(CorrespondenceStatus.RECEIVED);
      expect(referable).toContain(CorrespondenceStatus.UNDER_REVIEW);
      expect(referable).toContain(CorrespondenceStatus.REFERRED);
      expect(referable).not.toContain(CorrespondenceStatus.ARCHIVED);
    });

    it('getAllowedActions تُرجع كافة الإجراءات المتاحة للحالة', () => {
      const actionsForReceived = getAllowedActions(CorrespondenceStatus.RECEIVED);
      expect(actionsForReceived).toContain(CorrespondenceAction.REVIEW);
      expect(actionsForReceived).toContain(CorrespondenceAction.REFER);
      expect(actionsForReceived).toContain(CorrespondenceAction.CLOSE);
      expect(actionsForReceived).toContain(CorrespondenceAction.ARCHIVE);
    });
  });
});
