# نظام إدارة المراسلات المؤسسي — شركة الفضاء الواسع

**الواجهة الخلفية (Backend) للنظام** — [al-fadaa.com](https://al-fadaa.com)

نظام متكامل لإدارة مراسلات الشركة وفق التسلسل الإداري المعتمد:

> العميل يراسل **info@al-fadaa.com** ← المدير العام يستلم ويدرس ← **إحالة** لنائبه أو مدير قسم ← **تكليف** موظف ← الموظف يعدّ **مسودة رد** ← **اعتماد** المشرف ← **الإرسال الموحّد** من بريد الشركة — وكل خطوة موثقة في **سجل تدقيق غير قابل للتعديل**.

| | |
|---|---|
| الإطار | NestJS 11 (TypeScript صارم) |
| قاعدة البيانات | PostgreSQL 16 + Prisma ORM |
| المصادقة | JWT (Bearer) + حارس أدوار وصلاحيات |
| التوثيق التفاعلي | Swagger بالعربية على `/api/docs` |
| الاختبارات | Jest — 21 اختبار وحدة + 28 اختبار e2e (الرحلة الكاملة) |
| المرفقات | رفع حتى 15MB (PDF/صور/Word/Excel/ZIP) |

المخططات المعتمدة الأربعة مرفقة في [`docs/diagrams/`](docs/diagrams/) (البنية المعمارية — دورة الحياة — قاعدة البيانات — الأدوار والصلاحيات).

---

## المتطلبات

- **Node.js 20 أو أحدث** — [nodejs.org](https://nodejs.org)
- **PostgreSQL 16** — أسهل طريقة: Docker (الملف المرفق `docker-compose.yml`)
- npm (يأتي مع Node)

---

## البدء السريع (5 خطوات)

```bash
# 1) فك ضغط المشروع ثم من داخل المجلد — تثبيت الحزم
#    (يولّد Prisma Client تلقائيًا بعد التثبيت)
npm install

# 2) تشغيل قاعدة البيانات (PostgreSQL على المنفذ 5432)
docker compose up -d
#   لا تملك Docker؟ ثبّت PostgreSQL محليًا وأنشئ قاعدة باسم alfadaa_correspondence
#   ومستخدم alfadaa بكلمة مرور alfadaa — أو عدّل DATABASE_URL في .env

# 3) ملف البيئة
cp .env.example .env
# ثم افتحه وضع قيمة JWT_SECRET قوية (openssl rand -hex 64)

# 4) إنشاء الجداول + البيانات الأولية (الأقسام والحسابات التجريبية)
npx prisma migrate dev
#   يطبّق الترحيلات ويشغّل seed تلقائيًا

# 5) التشغيل
npm run start:dev
```

بعد الإقلاع:

- الواجهة: `http://localhost:3000/api/v1`
- **توثيق Swagger (جرب كل شيء من المتصفح): `http://localhost:3000/api/docs`**

> ⚠️ ملاحظة مهمة: إن كان لديك متغير بيئة `DATABASE_URL` مضبوطًا مسبقًا في نظامك (قيمة قديمة)، فإنه **يتجاوز** ملف `.env` — احذفه أولًا (`unset DATABASE_URL` على لينكس/ماك) وتأكد أنه غير معرف في ويندوز.

---

## الحسابات التجريبية (من seed)

كلمة المرور للجميع: **`Alfadaa@2026`** (للتطوير فقط — غيّرها فورًا في الإنتاج)

| الدور | البريد | الاسم |
|---|---|---|
| مسؤول النظام ADMIN | `admin@al-fadaa.com` | مسؤول النظام |
| المدير العام GM | `gm@al-fadaa.com` | المدير العام |
| نائب المدير DEPUTY_GM | `deputy@al-fadaa.com` | نائب المدير العام |
| مدير قسم DEPT_MANAGER | `eng.manager@al-fadaa.com` | مدير القسم الهندسي |
| مدير قسم DEPT_MANAGER | `fin.manager@al-fadaa.com` | مدير القسم المالي |
| موظف EMPLOYEE | `eng.employee1@al-fadaa.com` | المهندس أحمد |
| موظف EMPLOYEE | `fin.employee1@al-fadaa.com` | المحاسب خالد |

*(وأخرى — القائمة الكاملة في `prisma/seed.ts`، والحسابات تشمل مديري HR وIT وموظفة هندسية ثانية)*

يُنشئ الـ seed أيضًا مراسلتين نموذجيتين: `INC-2026-00001` بانتظار دراسة المدير العام، و`INC-2026-00002` محالة للقسم الهندسي مع تكليف ومسودة رد قيد الإعداد.

---

## متغيرات البيئة (`.env`)

| المتغير | الوصف | الافتراضي |
|---|---|---|
| `DATABASE_URL` | رابط PostgreSQL (**بدون علامات اقتباس** — Prisma لا يقبلها) | — |
| `PORT` | منفذ الخادم | 3000 |
| `CORS_ORIGIN` | النطاقات المسموحة مفصولة بفواصل — **في الإنتاج: فارغ أو `*` يمنع التشغيل** | `localhost:3000,3001,5000` |
| `JWT_SECRET` | سر التوقيع — **إلزامي (يفشل التشغيل عند غيابه)** | — |
| `JWT_EXPIRES_IN` | مدة صلاحية الرمز — **إلزامي** | `12h` |
| `JWT_ISSUER` | جهة إصدار الرمز المعتمدة | `alfadaa-api` |
| `JWT_AUDIENCE` | الجمهور المستهدف للرمز | `alfadaa-app` |
| `MAIL_DRIVER` | `console` (تطوير) أو `smtp` (إرسال حقيقي) | `console` |
| `MAIL_FROM` | البريد الرسمي الموحد | `info@al-fadaa.com` |
| `SMTP_HOST/PORT/USER/PASS` | بيانات خادم بريد الشركة (مع `MAIL_DRIVER=smtp`) | فارغة |
| `UPLOAD_DIR` | مجلد حفظ المرفقات | `./uploads` |

---

## بنية المشروع

```
al-fadaa-backend/
├── prisma/
│   ├── schema.prisma          # المخطط الكامل: 8 جداول + التعدادات
│   ├── migrations/            # ترحيلات SQL (تشمل Trigger سجل التدقيق)
│   └── seed.ts                # البيانات الأولية (أقسام + حسابات + مراسلات نموذجية)
├── src/
│   ├── main.ts                # نقطة الإقلاع + Swagger
│   ├── app.setup.ts           # إعدادات مشتركة (تُستخدم أيضًا في e2e)
│   ├── app.module.ts          # الوحدات + الحارسان العامان
│   ├── common/                # المشترك: decorators/guards/filters/context
│   │   ├── context/           # سياق الطلب (AsyncLocalStorage) للـ IP والتدقيق
│   │   └── guards/            # JwtAuthGuard + PermissionsGuard
│   ├── security/permissions.ts# مصفوفة الصلاحيات (الدور ← الصلاحيات)
│   ├── prisma/                # خدمة Prisma (Global)
│   ├── auth/                  # تسجيل الدخول + JWT + /auth/me
│   ├── users/                 # إدارة المستخدمين (إنشاء/تعطيل/تعديل)
│   ├── departments/           # إدارة الأقسام
│   ├── correspondences/       # المراسلات + مولّد الأرقام المرجعية
│   │   ├── ref-number.service.ts  # INC-2026-00001 (ذرّي/آمن تزامنيًا)
│   │   └── correspondences.service.ts  # نطاق الرؤية حسب الدور
│   ├── referrals/             # الإحالات (GM → نائب/مدير قسم)
│   ├── tasks/                 # التكليفات
│   ├── replies/               # دورة الرد: مسودة → رفع → اعتماد/رفض → إرسال
│   ├── attachments/           # المرفقات (رفع/تنزيل/حذف)
│   ├── audit/                 # سجل التدقيق (قراءة فقط)
│   └── mail/                  # البريد الموحد (console/SMTP)
├── test/
│   ├── e2e-db.ts              # اشتقاق قاعدة اختبار alfadaa_test تلقائيًا
│   ├── global-setup.e2e.ts    # بناء قاعدة الاختبار قبل e2e
│   ├── auth.e2e-spec.ts       # 8 اختبارات مصادقة/صلاحيات
│   └── correspondences.e2e-spec.ts  # 20 اختبارًا: الرحلة الكاملة
├── docs/diagrams/             # المخططات المعتمدة الأربعة
├── docker-compose.yml         # PostgreSQL جاهز
└── .github/workflows/ci.yml   # تكامل مستمر (اختبارات تلقائية)
```

**نمط كل وحدة** (موحّد وسهل التوسيع):

```
module.ts        → الوحدة (تُسجَّل في app.module.ts)
controller.ts    → المسارات + الصلاحيات المطلوبة + توثيق Swagger
service.ts       → منطق العمل + قواعد الحالات + سجل التدقيق
dto.ts           # كائنات نقل البيانات مع تحقق عربي
```

---

## نموذج البيانات (مطابق للمخطط المعتمد)

| الجدول | الوصف | أهم الحقول |
|---|---|---|
| `User` | المستخدمون | الدور، القسم، حالة التفعيل |
| `Department` | الأقسام | الرمز، المدير |
| `Correspondence` | المراسلات (وارد/صادر/داخلي) | الرقم المرجعي، الحالة، الأولوية، القسم، سلسلة الوالدين |
| `Referral` | الإحالات | من ← إلى، الحالة، الموعد النهائي |
| `Task` | التكليفات | المكلَّف، المنشئ، الحالة، الموعد |
| `Reply` | الردود | الحالة، الإصدار، المعتمد، سبب الرفض |
| `Attachment` | المرفقات | الاسم الأصلي والمخزن، النوع، الحجم |
| `AuditLog` | سجل التدقيق | الحدث، الوصف العربي، IP، تفاصيل JSON |
| `Counter` | عدّادات الأرقام المرجعية | مفتاح السنة/النوع |

---

## دورة حياة المراسلة (9 حالات)

```
RECEIVED → UNDER_REVIEW → REFERRED → IN_PROGRESS → PENDING_APPROVAL → APPROVED → SENT → CLOSED → ARCHIVED
```

| العملية | من ← إلى | من ينفذها |
|---|---|---|
| تسجيل وارد | (—) ← RECEIVED | GM / ADMIN |
| وسم «قيد الدراسة» | RECEIVED ← UNDER_REVIEW | GM / ADMIN |
| إحالة | RECEIVED/UNDER_REVIEW/REFERRED ← REFERRED | GM (لنائبه أو مدير قسم) / النائب (لمديري الأقسام) |
| إنشاء تكليف | REFERRED ← (تبقى) | مدير القسم / الإدارة العليا |
| أول مسودة رد | REFERRED ← IN_PROGRESS | الموظف المكلَّف |
| رفع للاعتماد | IN_PROGRESS ← PENDING_APPROVAL | صاحب المسودة |
| اعتماد | PENDING_APPROVAL ← APPROVED | المشرف (ليس الكاتب) |
| رفض مع سبب | PENDING_APPROVAL ← IN_PROGRESS | المشرف — تعود المسودة قابلة للتعديل |
| **إرسال موحّد** | APPROVED ← SENT | **المدير العام فقط** — يتولد رقم صادر OUT ويُرسل من info@al-fadaa.com |
| إغلاق | SENT/RECEIVED ← CLOSED | GM / ADMIN |
| أرشفة | SENT/CLOSED ← ARCHIVED | GM / ADMIN |

**نطاق الرؤية**: الإدارة العليا والمسؤول يرون كل شيء؛ مدير القسم يرى مراسلات قسمه وما أُحيل إليه؛ الموظف يرى فقط ما كُلِّف به أو أُحيل إليه أو صاغ ردوده.

---

## نظام الصلاحيات

مصفوفة كاملة في ملف واحد: **`src/security/permissions.ts`** — عدّلها بسهولة دون لمس أي كود آخر.

| الصلاحية | ADMIN | GM | DEPUTY_GM | DEPT_MANAGER | EMPLOYEE |
|---|:---:|:---:|:---:|:---:|:---:|
| إدارة المستخدمين | ✅ | — | — | — | — |
| إدارة الأقسام | ✅ | — | — | — | — |
| الاطلاع على كل المراسلات | ✅ | ✅ | ✅ | (قسمه) | (مهامه) |
| تسجيل الوارد | ✅ | ✅ | — | — | — |
| الإحالة | — | ✅ | ✅ | — | — |
| الإغلاق والأرشفة | ✅ | ✅ | — | — | — |
| التكليف | — | ✅ | ✅ | ✅ (قسمه) | — |
| إعداد المسودات | — | ✅ | ✅ | ✅ | ✅ |
| رفع للاعتماد | — | ✅ | ✅ | ✅ | ✅ |
| الاعتماد والرفض | — | ✅ | ✅ | ✅ (قسمه) | — |
| **الإرسال للعملاء** | — | **✅ فقط** | — | — | — |
| سجل التدقيق | ✅ | ✅ | — | — | — |

قواعد إضافية مفروضة في الخدمات: لا اعتماد لرد صاغه المعتمد بنفسه، مدير القسم يعتمد ردود قسمه فقط، والموظف يعدّ ردود تكليفاته فقط.

---

## نقاط النهاية (API v1)

القاعدة: `http://localhost:3000/api/v1` — التوثيق التفاعلي الكامل: `/api/docs`

### المصادقة `/auth`
| الطريقة | المسار | الوصف | الصلاحية |
|---|---|---|---|
| POST | `/auth/login` | تسجيل الدخول | عامة |
| GET | `/auth/me` | بياناتي | موثّق |

### المستخدمون `/users` — والأقسام `/departments`
CRUD كامل (الإنشاء/التعديل/التعطيل للمسؤول فقط؛ القراءة للجميع). التعطيل بدل الحذف حفاظًا على السجلات.

### المراسلات `/correspondences`
| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/incoming` | تسجيل وارد (يولّد INC-2026-XXXXX) |
| POST | `/internal` | تعميم داخلي (يولّد INT-…) |
| GET | `/` | قائمة بنطاق الدور + تصفية (`?status=&type=&priority=&q=&page=&limit=`) |
| GET | `/:id` | التفاصيل الكاملة (إحالات/تكليفات/ردود/مرفقات) |
| PATCH | `/:id` | تعديل البيانات (قبل الإحالة فقط) |
| POST | `/:id/close` · `/:id/archive` | الإغلاق والأرشفة |

### الإحالات — التكليفات — الردود
```
POST /correspondences/:id/referrals          # إحالة (GM/النائب)
GET  /referrals/my                           # صندوق إحالاتي
PATCH /referrals/:id/close                   # إغلاق إحالة

POST /correspondences/:id/tasks              # تكليف
GET  /tasks/my  ·  GET  /tasks               # مهامي / الكل (مشرفون)
PATCH /tasks/:id  ·  /tasks/:id/status       # تعديل / بدء تنفيذ / إلغاء

POST /replies                                # إنشاء مسودة
PATCH /replies/:id                           # تعديل مسودة (حتى بعد الرفض)
POST /replies/:id/submit                     # رفع للاعتماد
POST /replies/:id/approve  ·  /reject        # اعتماد / رفض مع سبب
POST /replies/:id/send                       # الإرسال الموحد (GM فقط)
```

### المرفقات — سجل التدقيق
```
POST   /correspondences/:id/attachments      # رفع (multipart، حقل file)
POST   /replies/:id/attachments
GET    /attachments/:id/download
DELETE /attachments/:id                      # قبل الإرسال فقط
GET    /audit                                # قراءة فقط + تصفية (ADMIN/GM)
```

### مثال سريع (curl)

```bash
# دخول
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"gm@al-fadaa.com","password":"Alfadaa@2026"}' | node -pe "JSON.parse(require('fs').readFileSync(0)).accessToken")

# تسجيل مراسلة واردة
curl -s -X POST http://localhost:3000/api/v1/correspondences/incoming \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"subject":"طلب عرض سعر","senderName":"شركة الأفق","senderEmail":"info@ofoq.com","priority":"HIGH"}'
```

---

## سجل التدقيق — غير قابل للعبث

مبدأ النظام الرقابي: **كل حدث مهم يُسجَّل ولا يمكن تعديله أو حذفه أبدًا**، على ثلاث طبقات:

1. **التطبيق**: خدمة `AuditService` تُنشئ سجلًا لكل حدث (دخول/إحالة/تكليف/رفع/اعتماد/رفض/إرسال/أرشفة…) مع وصف عربي، هوية المستخدم، **IP والمتصفح تلقائيًا** عبر `AsyncLocalStorage` — دون تمرير كائن الطلب في الكود.
2. **API**: نقطة قراءة فقط `/audit` — لا يوجد أي مسار تعديل أو حذف.
3. **قاعدة البيانات**: `TRIGGER` على مستوى PostgreSQL داخل الترحيل الأول **يرفض أي UPDATE أو DELETE** حتى لو حاول مبرمج تجاوز التطبيق:

```sql
-- موجود فعليًا داخل prisma/migrations/..._init/migration.sql
CREATE TRIGGER "audit_log_immutable_trigger"
  BEFORE UPDATE OR DELETE ON "AuditLog"
  FOR EACH ROW EXECUTE FUNCTION "prevent_audit_mutation"();
```

جرّب بنفسك بعد تشغيل `npx prisma studio` — أي محاولة تعديل صف في AuditLog سترفض.

---

## البريد الإلكتروني (الإرسال الموحد)

كل الردود تُرسل من **`info@al-fadaa.com`** حصرًا:

- **أثناء التطوير**: `MAIL_DRIVER=console` — تُطبع الرسالة في الطرفية فقط (لا إرسال حقيقي).
- **الإنتاج**: ضع `MAIL_DRIVER=smtp` وبيانات خادم بريد الشركة في `.env` — وستُرسل الردود فعليًا عبر nodemailer. الإرسال لا يُفشل العملية إن تعطل البريد (يُسجَّل التحذير).

---

## كيف تضيف ميزة جديدة؟ — مثال عملي: «الملاحظات الداخلية»

مثال كامل لميزة جديدة: ملاحظات داخلية على المراسلة (يتحقق من صلاحية الرؤية + يسجل في التدقيق).

### 1) أضف الجدول في `prisma/schema.prisma`

```prisma
model Note {
  id              String    @id @default(uuid())
  correspondenceId String
  correspondence  Correspondence @relation(fields: [correspondenceId], references: [id], onDelete: Cascade)
  authorId        String
  author          User      @relation("NoteAuthor", fields: [authorId], references: [id], onDelete: Restrict)
  body            String    @db.Text
  createdAt       DateTime  @default(now())

  @@index([correspondenceId])
}
```

أضف العلاقة المعاكسة داخل `model Correspondence`:

```prisma
  notes Note[]
```

وداخل `model User`:

```prisma
  notesAuthored Note[] @relation("NoteAuthor")
```

ثم أنشئ الترحيل وطبّقه:

```bash
npx prisma migrate dev --name add-notes
```

### 2) أنشئ الوحدة `src/notes/` بأربعة ملفات

`src/notes/dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CreateNoteDto {
  @ApiProperty({ description: 'نص الملاحظة' })
  @IsString()
  @MinLength(2, { message: 'الملاحظة قصيرة جدًا' })
  @IsNotEmpty({ message: 'نص الملاحظة مطلوب' })
  body!: string;
}
```

`src/notes/notes.service.ts` — لاحظ إعادة استخدام `CorrespondencesService` لفرض نطاق الرؤية، و`AuditService` للتدقيق:

```typescript
import { Injectable } from '@nestjs/common';
import { AuditAction } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import type { AuthUser } from '../common/types';
import { CreateNoteDto } from './dto';

@Injectable()
export class NotesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly correspondences: CorrespondencesService,
    private readonly audit: AuditService,
  ) {}

  async create(correspondenceId: string, dto: CreateNoteDto, user: AuthUser) {
    // هذه السطر يرمي 404/403 تلقائيًا إن لم تكن المراسلة ضمن نطاق المستخدم
    const corr = await this.correspondences.findOne(correspondenceId, user);

    const note = await this.prisma.note.create({
      data: { correspondenceId: corr.id, authorId: user.id, body: dto.body },
      include: { author: { select: { id: true, name: true } } },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Note',
      entityId: note.id,
      summary: `إضافة ملاحظة داخلية على ${corr.refNumber}`,
      metadata: { correspondenceId: corr.id },
    });
    return note;
  }

  findForCorrespondence(correspondenceId: string) {
    return this.prisma.note.findMany({
      where: { correspondenceId },
      orderBy: { createdAt: 'asc' },
      include: { author: { select: { id: true, name: true } } },
    });
  }
}
```

`src/notes/notes.controller.ts`:

```typescript
import { Body, Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { NotesService } from './notes.service';
import { CreateNoteDto } from './dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';

@ApiTags('الملاحظات الداخلية')
@ApiBearerAuth()
@Controller()
export class NotesController {
  constructor(private readonly notesService: NotesService) {}

  @Post('correspondences/:correspondenceId/notes')
  @ApiOperation({ summary: 'إضافة ملاحظة داخلية (من يملك رؤية المراسلة)' })
  create(
    @Param('correspondenceId', ParseUUIDPipe) correspondenceId: string,
    @Body() dto: CreateNoteDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.notesService.create(correspondenceId, dto, user);
  }

  @Get('correspondences/:correspondenceId/notes')
  @ApiOperation({ summary: 'ملاحظات المراسلة' })
  list(@Param('correspondenceId', ParseUUIDPipe) correspondenceId: string) {
    return this.notesService.findForCorrespondence(correspondenceId);
  }
}
```

`src/notes/notes.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { NotesController } from './notes.controller';
import { NotesService } from './notes.service';

@Module({
  imports: [CorrespondencesModule],
  controllers: [NotesController],
  providers: [NotesService],
})
export class NotesModule {}
```

### 3) سجّل الوحدة في `src/app.module.ts`

```typescript
import { NotesModule } from './notes/notes.module';
// ثم أضفها إلى imports: [..., NotesModule]
```

### 4) (اختياري) صلاحية جديدة

لو أردت تقييد الميزة بدور معين، أضف مفتاحًا في `Permission` بمصفوفة `src/security/permissions.ts`، ثم على المسار:

```typescript
@RequirePermission(Permission.NOTES_ADD)
```

### 5) أعد التشغيل واختبر

```bash
npm run start:dev   # ستظهر الملاحظات تلقائيًا في Swagger
```

**القاعدة الذهبية**: أي عملية كتابة ← `audit.log(...)` بعد نجاحها. أي قراءة حساسة ← `correspondences.findOne()` أولًا لفرض النطاق.

---

## كيف تختبر؟

النظام يستخدم **ثلاث مستويات اختبار** — جميعها تعمل الآن (49 اختبارًا أخضر):

### 1) اختبارات الوحدة (Unit) — سريعة، بلا قاعدة بيانات

تُزيّف التبعيات (Prisma/JWT) وتركز على منطق العمل:

```bash
npm test          # تشغيل كل اختبارات الوحدة
npm run test:watch   # وضع المراقبة أثناء التطوير
npm run test:cov     # تقرير تغطية الكود
```

الموجود حاليًا (في `src/**/**.spec.ts`):
- `auth.service.spec.ts` — الدخول الصحيح/الخاطئ/الحساب المعطل + عدم تسريب كلمة المرور
- `permissions.spec.ts` — مطابقة مصفوفة الصلاحيات كاملة (الموظف لا يرسل، GM وحده يرسل…)
- `permissions.guard.spec.ts` — سلوك الحارس (سماح/رفض 403 برسالة عربية)
- `audit.service.spec.ts` — التقاط IP من السياق + عدم إفشال العملية عند فشل التسجيل
- `ref-number.service.spec.ts` — توليد الأرقام المرجعية بصيغة صحيحة

**لكتابة اختبار وحدة جديد** — أنشئ `src/<وحدتك>/<service>.spec.ts`:

```typescript
const prismaMock = { task: { findMany: jest.fn() } };

// داخل beforeAll:
const moduleRef = await Test.createTestingModule({
  providers: [
    TasksService,
    { provide: PrismaService, useValue: prismaMock },
    { provide: AuditService, useValue: { log: jest.fn() } },
  ],
}).compile();
```

### 2) اختبارات e2e — الرحلة الكاملة ضد قاعدة حقيقية

تعمل على قاعدة **مستقلة اسمها `alfadaa_test`** تُبنى وتُعاد تهيئتها **تلقائيًا** قبل كل تشغيل (لا تلمس بيانات التطوير إطلاقًا):

```bash
docker compose up -d        # PostgreSQL شغال أولًا
npm run test:e2e
```

ما الذي يغطيه `test/correspondences.e2e-spec.ts` (20 اختبارًا متسلسلًا يمثل دورة الحياة الفعلية):

1. الموظف ممنوع من تسجيل الوارد (403) ← GM يسجّل (رقم تسلسلي صحيح)
2. الموظف لا يرى المراسلة (403) ← GM يراها
3. رفع مرفق (multipart) يعمل
4. GM يحيل لمدير القسم ← المراسلة تربط بقسمه تلقائيًا
5. مدير القسم يكلّف موظفه — ويُمنع من تكليف موظف قسم آخر
6. الموظف يرى المراسلة ضمن مهامه، يبدأ التنفيذ، يعدّ المسودة
7. الموظف ممنوع من الاعتماد/الإرسال (403)
8. رفع المسودة ← اعتماد مدير القسم ← مدير القسم ممنوع من الإرسال (403)
9. **GM يرسل**: يتولد رقم صادر `OUT-2026-00001`، ترتبط سلسلة الوارد/الصادر، يُقفل التكليف
10. منع الإرسال المكرر + **تحقق سجل التدقيق يحتوي السلسلة كاملة**
11. تنزيل المرفق ينجح وحذفه يُمنع بعد الإرسال ← الأرشفة

ولإضافة اختبار e2e جديد: أنشئ `test/<اسم>.e2e-spec.ts` على نفس النمط (بناء التطبيق عبر `Test.createTestingModule + configureApp` لضمان نفس سلوك الإنتاج).

### 3) الاختبار اليدوي عبر Swagger — أسهل طريقة

1. افتح `http://localhost:3000/api/docs`
2. `POST /auth/login` → جرّب `gm@al-fadaa.com` / `Alfadaa@2026` → انسخ `accessToken`
3. اضغط زر **Authorize** أعلى الصفحة وألصق الرمز — الآن كل النقاط جاهزة للتجربة
4. اتبع نفس ترتيب الرحلة أعلاه: سجّل واردًا ← أحِله ← كلّف ← اكتب مسودة ← ارفعها ← اعتمدها ← أرسلها
5. راقب الأحداث في `GET /audit` — والرسالة ستُطبع في طرفية الخادم (وضع console)

### 4) أدوات مساعدة

```bash
npx prisma studio        # استعراض الجداول وتعديلها بصريًا (http://localhost:5555)
npm run db:reset         # إعادة بناء قاعدة التطوير من الصفر + seed (يمسح كل البيانات!)
npm run test:e2e -- --verbose   # تفاصيل كل اختبار
```

### 5) التكامل المستمر

الملف `.github/workflows/ci.yml` جاهز: عند كل push على GitHub يشغّل تلقائيًا (PostgreSQL كخدمة): تثبيت ← بناء ← اختبارات الوحدة ← e2e — فور رفع المشروع إلى مستودع GitHub سيعمل كل شيء دون أي إعداد إضافي.

---

## تشغيل الإنتاج (مبدئيًا)

```bash
npm run build
npx prisma migrate deploy     # تطبيق الترحيلات فقط (بدون dev)
NODE_ENV=production node dist/main.js
```

نصائح أساسية قبل الإنتاج: غيّر `JWT_SECRET` (عشوائي طويل)، كلمات مرور الحسابات التجريبية، `MAIL_DRIVER=smtp` ببيانات الشركة، و `CORS_ORIGIN` بنطاقات الواجهة الأمامية المحددة (⚠️ القائمة الفارغة أو `*` تمنع بدء التشغيل تلقائيًا). يُفضل خلف Nginx مع HTTPS، وpm2 أو Docker لإدارة العمليات.

---

## خارطة الطريق المقترحة (الخطوات القادمة)

| الأولوية | الميزة | ملاحظات |
|---|---|---|
| 1 | **سحب البريد الوارد تلقائيًا (IMAP)** | خدمة مجدولة تقرأ صندوق info@al-fadaa.com وتسجل الوارد عبر نفس `createIncoming` — البنية جاهزة لذلك |
| 2 | **الواجهة الأمامية (Next.js)** | لوحة GM + صندوق إحالات المدير + مهام الموظف — الـ API كامل وموثق |
| 3 | Refresh Tokens | إصدار رمز طويل الأمد + تدوير عند انتهاء القصير |
| 4 | حد معدل الطلبات | `@nestjs/throttler` على مسار الدخول |
| 5 | إشعارات (FCM/بريد داخلي) | عند الإحالة والتكليف وطلب التعديل |
| 6 | تخزين S3 للمرفقات | استبدال القرص المحلي عند التوسع |

---

## استكشاف الأخطاء الشائعة

| المشكلة | السبب والحل |
|---|---|
| `the URL must start with the protocol postgresql://` | متغير `DATABASE_URL` قديم مضبوط في نظامك يتجاوز `.env` — احذفه: `unset DATABASE_URL` (لينكس/ماك) أو احذفه من متغيرات بيئة ويندوز، وتأكد من عدم وجود علامات اقتباس حول الرابط في `.env` |
| `P1001: Can't reach database` | PostgreSQL غير شغال — `docker compose up -d` وتأكد من المنفذ 5432 |
| `401` عند كل الطلبات | انسخت الرمز بدون `Bearer ` أو انتهت صلاحيته (12h) — أعد الدخول |
| `403 ليست لديك صلاحية` | سلوك مقصود — راجع مصفوفة الصلاحيات أعلاه |
| رقم مرجعي غير متوقع | الأرقام تسلسلية سنويًا (تزيد مع seed والاختبارات) — هذا طبيعي |
| تعذر تعديل/حذف من AuditLog | **مقصود تمامًا** — Trigger القاعدة يمنعه حتى على SQL مباشر |

