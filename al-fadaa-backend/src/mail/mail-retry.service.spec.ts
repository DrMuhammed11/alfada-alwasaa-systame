import { MailRetryService } from './mail-retry.service';
import type { SendReplyOptions } from './mail.service';

describe('MailRetryService', () => {
  let service: MailRetryService;

  const sampleMail: SendReplyOptions = {
    to: 'customer@example.com',
    subject: 'إشعار استلام المعاملة',
    body: 'تم استلام معاملتكم بنجاح.',
    refNumber: 'REF-2026-0001',
  };

  beforeEach(() => {
    service = new MailRetryService();
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('يجب أن يدرج الرسالة الفاشلة في قائمة الاسترداد', () => {
    service.enqueue(sampleMail, 'Connection timeout');
    expect(service.pendingCount).toBe(1);

    const status = service.getQueueStatus();
    expect(status.pendingCount).toBe(1);
    expect(status.items[0].refNumber).toBe('REF-2026-0001');
    expect(status.items[0].attempts).toBe(1);
    expect(status.items[0].lastError).toBe('Connection timeout');
  });

  it('يجب أن يزيد عدد المحاولات عند تكرار الفشل لنفس الرسالة', () => {
    service.enqueue(sampleMail, 'Connection timeout');
    service.enqueue(sampleMail, 'Connection refused');

    expect(service.pendingCount).toBe(1);
    const status = service.getQueueStatus();
    expect(status.items[0].attempts).toBe(2);
    expect(status.items[0].lastError).toBe('Connection refused');
  });

  it('يجب أن يحذف الرسالة عند الوصول للحد الأقصى للمحاولات', () => {
    service.enqueue(sampleMail, 'Err 1', 3);
    expect(service.pendingCount).toBe(1);

    service.enqueue(sampleMail, 'Err 2', 3);
    expect(service.pendingCount).toBe(1);

    service.enqueue(sampleMail, 'Err 3', 3); // وصلت الحد الأقصى 3
    expect(service.pendingCount).toBe(0);
  });

  it('يجب أن يفرغ القائمة عند استدعاء clearQueue', () => {
    service.enqueue(sampleMail, 'Err 1');
    expect(service.pendingCount).toBe(1);
    service.clearQueue();
    expect(service.pendingCount).toBe(0);
  });

  it('يجب أن يعالج الرسائل المستحقة ويحذفها من القائمة عند نجاح الإرسال', async () => {
    const senderMock = jest.fn().mockResolvedValue(true);
    service.registerSender(senderMock);

    service.enqueue(sampleMail, 'Temporary failure');
    expect(service.pendingCount).toBe(1);

    // تزييف وقت الاستحقاق ليكون مستحقاً الآن
    const item = service.getQueueStatus().items[0];
    item.nextRetryAt = new Date(Date.now() - 1000);
    // نعدل الوقت في القائمة الداخلية
    (service as any).queue.get(item.id).nextRetryAt = new Date(Date.now() - 1000);

    await service.processQueue();

    expect(senderMock).toHaveBeenCalledWith(sampleMail);
    expect(service.pendingCount).toBe(0);
  });

  it('يجب ألا يحذف الرسالة ويعيد جدولتها عند استمرار فشل الإرسال', async () => {
    const senderMock = jest.fn().mockResolvedValue(false);
    service.registerSender(senderMock);

    service.enqueue(sampleMail, 'Temporary failure', 3);
    (service as any).queue.get('REF-2026-0001').nextRetryAt = new Date(Date.now() - 1000);

    await service.processQueue();

    expect(senderMock).toHaveBeenCalledWith(sampleMail);
    expect(service.pendingCount).toBe(1);
    const status = service.getQueueStatus();
    expect(status.items[0].attempts).toBe(2);
  });
});
