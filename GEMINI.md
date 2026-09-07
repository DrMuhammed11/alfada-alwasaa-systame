# قواعد العمل على مشروع الفضاء الواسع (نظام إدارة المراسلات)

## القواعد الصارمة (لا تخالفها أبدًا)
- الهدف: التنظيم والترتيب وسلاسة القراءة فقط. ممنوع تغيير أي سلوك وظيفي أو منطق أعمال.
- ممنوع معالجة أي موضوع أمان أو ثغرات أو صلاحيات — مؤجل بناءً على طلب المالك. اذكر ذلك فقط إن سأل.
- نفّذ المرحلة المطلوبة في الطلب فقط، ولا تكمل إلى مراحل أخرى من عندك.
- تعديلات صغيرة قابلة للرجوع: commit بعد كل خطوة ناجحة، ورسالة commit عربية واضحة.
- أسماء الـ endpoints والـ routes والـ DTOs تبقى كما هي حرفيًا.
- لا تحذف أو تعدّل أي ملف اختبار موجود (*.spec.ts).
- كل تعديل يُتبع بـ: نجاح البناء + نجاح الاختبارات قبل اعتباره منتهيًا.
- اللغة: تعليقات ورسائل عربية، أسماء الكود والمسارات بالإنجليزية.
- في نهاية كل مرحلة: جدول بالملفات (أُنشئ/عُدّل/حُذف + سطر واحد يشرح السبب).

## البنية
- backend/ (`al-fadaa-backend/`): NestJS 11 + Prisma 6 + PostgreSQL
  - الوحدات: auth, correspondences, referrals, replies, tasks, attachments, mail, notifications, audit, users, departments, security, prisma, common
  - المنفذ: 3000 (`http://localhost:3000/api/v1`) | التوثيق: `http://localhost:3000/api/docs`
- frontend/ (`al_fadaa_frontend/`): Flutter 3 (Dart 3)
  - الهيكل: lib/core (network, constants, theme, utils) + lib/models + lib/views (auth, dashboard, admin, tasks, referrals, correspondences, notifications)
  - المنفذ: 5000 (`http://localhost:5000`)

## أوامر التحقق الإلزامية
- backend: `cd al-fadaa-backend && npm run build` ثم `npm test`
- frontend: `cd al_fadaa_frontend && flutter analyze` (صفر أخطاء) ثم `flutter build web --release` عند التعديلات الجوهرية
- git: `git add -A && git commit -m "<رسالة>"` بعد نجاح كل خطوة فقط
