# الدليل القياسي لإدارة التزامن ومنع تعارضات العمليات (Concurrency Guidelines)

> **القاعدة الذهبية المعتمدة في نظام الفضاء الواسع:**
> **«كل تغيير حالة يجري عبر updateMany الشرطي + version»**

---

## 1. المبدأ الهندسي: التزامن المتفائل الذري (Atomic Optimistic Concurrency)
في بيئات العمل التفاعلية والشبكية، لا نستخدم الأقفال التشاؤمية الطويلة (`Pessimistic Locks`) التي تجمد الجداول وتبطئ تجربة المستخدم، بل نعتمد على عمود الإصدار `version Int @default(1)` في جداول الكيانات المحورية (`Correspondence`, `Reply`).

---

## 2. النمط البرمجي الإلزامي لكل عملية تغيير حالة

عند كتابة أي دالة لتحديث حالة مراسلة أو رد أو إحالة، اتبع النمط التالي بدقة:

```typescript
const updated = await this.prisma.$transaction(async (tx) => {
  // 1. التحديث الذري المشروط بالإصدار والحالات المسموحة
  const res = await tx.correspondence.updateMany({
    where: {
      id: correspondenceId,
      version: currentEntity.version, // التحقق من عدم تعديل الكائن في الخلفية
      status: { in: allowedStatuses },  // التحقق من صلاحية الحالة الحالية
    },
    data: {
      status: nextStatus,
      version: { increment: 1 },       // زيادة الإصدار ذرياً
      // الحقول الأخرى المرتبطة بالتعديل
    },
  });

  // 2. التحقق من نتيجة العملية
  if (res.count === 0) {
    const current = await tx.correspondence.findUnique({
      where: { id: correspondenceId },
      select: { status: true, version: true },
    });
    if (!current) throw new NotFoundException('المراسلة غير موجودة');
    
    // رمي الخطأ العربي الموحد والمطابق لمعايير النظام
    throw new BadRequestException(
      'عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة',
    );
  }

  // 3. كتابة حدث الـ Outbox داخل نفس المعاملة (إن وجد)
  if (this.outbox) {
    await this.outbox.emit(tx, {
      type: OutboxEventType.XXX,
      payload: { ... },
    });
  }

  // 4. إعادة الكائن المحدث
  return tx.correspondence.findUniqueOrThrow({
    where: { id: correspondenceId },
    include: DETAIL_INCLUDE,
  });
});

// 5. تفعيل المعالجة الفورية للإشعارات والتدقيق بعد نجاح المعاملة
if (this.outboxProcessor) {
  this.outboxProcessor.trigger();
}
```

---

## 3. الفوائد التقنية لهذا الأسلوب
1. **أمان تام ضد التسابق (Race-Condition Free):** محرك PostgreSQL يضمن أن عملية واحدة فقط ستطابق شرط `version` وتنفذ التعديل، بينما ترفض أي عملية أخرى متزامنة.
2. **عدم ترك حالات وسيطة فاسدة (Zero Corrupted States):** المعاملة تفشل بالكامل وتتراجع في حال تعارض الإصدار.
3. **أقصى سرعة واستجابة (High Throughput):** لا يتم حجز أقفال انتظار طويلة بين العمليات غير المتنافسة.
4. **رسالة خطأ موحدة للمستخدم:** «عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة».
