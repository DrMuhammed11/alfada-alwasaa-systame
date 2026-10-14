import { ExecutionContext, CallHandler } from '@nestjs/common';
import { of } from 'rxjs';
import { IdempotencyInterceptor } from './idempotency.interceptor';
import { PrismaService } from '../../prisma/prisma.service';

describe('IdempotencyInterceptor', () => {
  let interceptor: IdempotencyInterceptor;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      idempotencyRecord: {
        findUnique: jest.fn(),
        create: jest.fn(),
        deleteMany: jest.fn(),
      },
    };
    interceptor = new IdempotencyInterceptor(prismaMock as unknown as PrismaService);
  });

  function createMockContext(method: string, headers: Record<string, string>, user?: any, url = '/api/v1/correspondences') {
    const req: any = {
      method,
      headers,
      user,
      url,
      originalUrl: url,
    };
    const res: any = {
      statusCode: 200,
      status: jest.fn().mockImplementation((code) => {
        res.statusCode = code;
        return res;
      }),
    };
    const context: any = {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => res,
      }),
    };
    return { context, req, res };
  }

  function createMockCallHandler(returnValue: any = { success: true }) {
    const handle = jest.fn().mockReturnValue(of(returnValue));
    return { handle };
  }

  it('(ج) يمرر الطلب عاديًا عند عدم وجود header Idempotency-Key', async () => {
    const { context } = createMockContext('POST', {});
    const next = createMockCallHandler();

    const result$ = await interceptor.intercept(context, next);
    let output: any;
    result$.subscribe((val) => (output = val));

    expect(next.handle).toHaveBeenCalled();
    expect(prismaMock.idempotencyRecord.findUnique).not.toHaveBeenCalled();
    expect(output).toEqual({ success: true });
  });

  it('يتجاهل طلبات غير POST (مثل GET) حتى مع وجود المفتاح', async () => {
    const { context } = createMockContext('GET', { 'idempotency-key': 'key-123' });
    const next = createMockCallHandler();

    const result$ = await interceptor.intercept(context, next);
    let output: any;
    result$.subscribe((val) => (output = val));

    expect(next.handle).toHaveBeenCalled();
    expect(prismaMock.idempotencyRecord.findUnique).not.toHaveBeenCalled();
    expect(output).toEqual({ success: true });
  });

  it('(أ) ينفذ الطلب الأول ويحفظ الاستجابة عند عدم وجود سجل مسبق', async () => {
    prismaMock.idempotencyRecord.findUnique.mockResolvedValue(null);
    prismaMock.idempotencyRecord.create.mockResolvedValue({});

    const { context, res } = createMockContext('POST', { 'idempotency-key': 'key-unique' }, { id: 'user-1' });
    res.statusCode = 201;
    const next = createMockCallHandler({ id: 'corr-1', title: 'خطاب جديد' });

    const result$ = await interceptor.intercept(context, next);
    let output: any;
    result$.subscribe((val) => (output = val));

    expect(next.handle).toHaveBeenCalledTimes(1);
    expect(prismaMock.idempotencyRecord.findUnique).toHaveBeenCalledWith({
      where: { key: 'key-unique' },
    });
    expect(prismaMock.idempotencyRecord.create).toHaveBeenCalledWith({
      data: {
        key: 'key-unique',
        userId: 'user-1',
        endpoint: '/api/v1/correspondences',
        responseBody: { id: 'corr-1', title: 'خطاب جديد' },
        statusCode: 201,
      },
    });
    expect(output).toEqual({ id: 'corr-1', title: 'خطاب جديد' });
  });

  it('(أ) نفس المفتاح مرتين من نفس المستخدم → يعيد الاستجابة المخزنة ولا ينفذ Handler ثانية', async () => {
    const storedRecord = {
      key: 'key-replay',
      userId: 'user-1',
      endpoint: '/api/v1/correspondences',
      responseBody: { id: 'corr-saved', title: 'معاملة سابقة' },
      statusCode: 201,
    };
    prismaMock.idempotencyRecord.findUnique.mockResolvedValue(storedRecord);

    const { context, res } = createMockContext('POST', { 'idempotency-key': 'key-replay' }, { id: 'user-1' });
    const next = createMockCallHandler();

    const result$ = await interceptor.intercept(context, next);
    let output: any;
    result$.subscribe((val) => (output = val));

    expect(next.handle).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(201);
    expect(output).toEqual(storedRecord.responseBody);
  });

  it('(ب) مفتاح مستخدم من مستخدم آخر يُتجاهل ويُنفّذ الطلب كأنه غير موجود', async () => {
    const existingOtherUserRecord = {
      key: 'shared-key',
      userId: 'user-victim',
      endpoint: '/api/v1/correspondences',
      responseBody: { secret: 'victim-data' },
      statusCode: 200,
    };
    prismaMock.idempotencyRecord.findUnique.mockResolvedValue(existingOtherUserRecord);
    prismaMock.idempotencyRecord.create.mockResolvedValue({});

    const { context } = createMockContext('POST', { 'idempotency-key': 'shared-key' }, { id: 'user-attacker' });
    const next = createMockCallHandler({ success: true, forAttacker: true });

    const result$ = await interceptor.intercept(context, next);
    let output: any;
    result$.subscribe((val) => (output = val));

    expect(next.handle).toHaveBeenCalledTimes(1);
    expect(output).toEqual({ success: true, forAttacker: true });
  });
});
