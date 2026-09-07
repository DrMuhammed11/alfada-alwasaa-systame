import { ForbiddenException } from '@nestjs/common';
import { ExecutionContext } from '@nestjs/common';
import { PermissionsGuard } from './permissions.guard';
import { Permission, ROLE_PERMISSIONS } from '../../security/permissions';

/** اختبارات وحدة لحارس الصلاحيات */
describe('PermissionsGuard', () => {
  let guard: PermissionsGuard;
  const reflectorMock = { getAllAndOverride: jest.fn() };

  const makeContext = (user: unknown): ExecutionContext =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ user }) }),
      getHandler: () => undefined,
      getClass: () => undefined,
    }) as unknown as ExecutionContext;

  beforeAll(() => {
    guard = new PermissionsGuard(reflectorMock as never);
  });

  beforeEach(() => reflectorMock.getAllAndOverride.mockReset());

  it('يسمح بالمرور للمسارات غير المشروطة (لا RequirePermission)', () => {
    reflectorMock.getAllAndOverride.mockReturnValue(undefined);
    expect(guard.canActivate(makeContext({ role: 'EMPLOYEE' }))).toBe(true);
  });

  it('يرفض الموظف عند طلب صلاحية الإرسال (403 برسالة عربية)', () => {
    reflectorMock.getAllAndOverride.mockReturnValue([Permission.CORR_SEND]);
    expect(() =>
      guard.canActivate(makeContext({ id: 'u1', role: 'EMPLOYEE' })),
    ).toThrow(ForbiddenException);
    expect(() =>
      guard.canActivate(makeContext({ id: 'u1', role: 'EMPLOYEE' })),
    ).toThrow(/ليست لديك صلاحية/);
  });

  it('يسمح للمدير العام بصلاحية الإرسال', () => {
    reflectorMock.getAllAndOverride.mockReturnValue([Permission.CORR_SEND]);
    expect(guard.canActivate(makeContext({ id: 'gm', role: 'GM' }))).toBe(true);
  });

  it('يرفض الطلبات غير الموثقة التي تطلب صلاحية (لا مستخدم)', () => {
    reflectorMock.getAllAndOverride.mockReturnValue([Permission.CORR_VIEW_ALL]);
    expect(guard.canActivate(makeContext(undefined))).toBe(false);
  });

  it('يقبل الدور إذا امتلك إحدى الصلاحيات المطلوبة المتعددة', () => {
    reflectorMock.getAllAndOverride.mockReturnValue([
      Permission.CORR_SEND,
      Permission.REPLY_APPROVE,
    ]);
    // DEPUTY_GM يملك REPLY_APPROVE فقط — يكفي إحداها
    expect(ROLE_PERMISSIONS.DEPUTY_GM).toContain(Permission.REPLY_APPROVE);
    expect(guard.canActivate(makeContext({ id: 'dep', role: 'DEPUTY_GM' }))).toBe(true);
  });
});
