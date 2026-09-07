import { Test, TestingModule } from '@nestjs/testing';
import { RefNumberService } from './ref-number.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * اختبار تكامل: 50 توليدًا متوازيًا بلا تكرار.
 * يتطلب قاعدة بيانات PostgreSQL فعلية (ليس mock).
 */
describe('RefNumberService — اختبار الذرية', () => {
  let service: RefNumberService;
  let prisma: PrismaService;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RefNumberService, PrismaService],
    }).compile();

    service = module.get(RefNumberService);
    prisma = module.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('50 توليدًا متوازيًا بدون أي رقم مكرر', async () => {
    const promises = Array.from({ length: 50 }, () => service.generate('INC'));
    const results = await Promise.all(promises);

    // لا تكرار
    const unique = new Set(results);
    expect(unique.size).toBe(50);

    // كلها تطابق الصيغة المتوقعة
    for (const ref of results) {
      expect(ref).toMatch(/^INC-\d{4}-\d{6}$/);
    }
  });
});
