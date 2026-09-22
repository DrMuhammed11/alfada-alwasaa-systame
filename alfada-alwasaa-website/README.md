# موقع شركة الفضاء الواسع — AL-FADA AL-WASAA
> الموقع التعريفي والتسويقي الرسمي لشركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة والتوريدات (صنعاء، اليمن).

---

## 1. البنية التقنية (Architecture)

- **Framework**: Next.js 16.3+ (App Router)
- **UI Engine**: React 19
- **Styling**: Tailwind CSS v4 + `@theme inline`
- **Animation & Motion**: Framer Motion 12 + Lenis Smooth Scroll
- **Export Strategy**: Static HTML Export (`output: "export"`) — يولد حزمة استاتيكية كاملة في مجلد `out/` جاهزة للنشر السحابي على Cloudflare Pages أو Netlify أو Vercel أو Nginx أو أي CDN ثابت.

---

## 2. متطلبات التشغيل

- **Node.js**: الإصدار 20.x أو 22.x أو أحدث.
- **مدير الحزم**: `npm` (أو `pnpm` / `bun`).

---

## 3. أوامر التشغيل والبناء (Scripts)

| الأمر | الوصف |
|---|---|
| `npm run dev` | تشغيل خادم التطوير المحلي على المنفذ `3001` (`http://localhost:3001`) |
| `npm run build` | بناء وتصدير الموقع بالكامل كثابت إلى مجلد `out/` |
| `npm run typecheck` | التحقق من صحة أنواع TypeScript بالكامل دون توليد ملفات (`tsc --noEmit`) |
| `npm run lint` | فحص الكود بمعايير ESLint القياسية |
| `npm run clean` | تنظيف ملفات ومجلدات البناء المؤقتة (`.next` و `out`) |
| `npm start` | تقديم النسخة المبنية الثابتة محلياً عبر `npx serve out -l 3001` |
| `npm run analyze` | تحليل حجم حزم JavaScript بيانياً عبر `@next/bundle-analyzer` |

---

## 4. إعداد متغيرات البيئة (Environment Variables)

انسخ ملف `.env.example` إلى `.env.local` قبل تشغيل البناء:
```bash
cp .env.example .env.local
```

### المتغيرات المتاحة:
- `NEXT_PUBLIC_API_URL`: رابط الواجهة الخلفية لنظام إدارة المراسلات.
  - **تنبيه جوهري (Build-time Inlining):** في وضع التصدير الثابت (`output: "export"`)، يتم دمج هذا المتغير أثناء وقت البناء (`npm run build`) داخل ملفات الـ JavaScript المولدة. أي تعديل عليه يتطلب إعادة البناء.
  - القيمة الافتراضية `http://localhost:3000/api/v1` مخصصة للتطوير المحلي فقط.
- `NEXT_PUBLIC_GA_ID`: معرّف تتبع تحليلات Google (اختياري).

---

## 5. تكامل الواجهة الخلفية وضبط CORS (Backend Integration)

يتصل الموقع بواجهة NestJS الخلفية لنظام المراسلات (`al-fadaa-backend`) عبر نقطتي نهاية عموميتين:
1. `POST /correspondences/public/inquiry` — لتقديم طلبات الاستشارة وعروض الأسعار وتوليد الرقم المرجعي ورمز التتبع.
2. `GET /correspondences/public/track/:ref?token=` — لمتابعة حالة المعاملة.

> ⚠️ **تنبيه إلزامي لمدير النظام (CORS):**
> يجب إضافة نطاق الموقع الرسمي في قائمة `CORS_ORIGIN` في إعدادات الواجهة الخلفية (`al-fadaa-backend` - ملف `src/common/cors/build-cors-origin.ts`):
> ```env
> CORS_ORIGIN="https://www.alfadaalwasaa.com,https://alfadaalwasaa.com"
> ```
> بدون هذا الضبط، سيرفض المتصفح اتصالات نموذج التواصل والاستعلام في بيئة الإنتاج.

---

## 6. قواعد التخزين المؤقت وإعادة التوجيه (CDN Caching & Redirects)

- **`public/_headers`**: يُطبق تلقائياً على Cloudflare Pages و Netlify لضبط تخزين مؤقت طويل المدى للصور (`Cache-Control: public, max-age=31536000, immutable`).
- **`public/_redirects`**: يتضمن قاعدة إعادة التوجيه الدائمة 301 من النطاق الجذري (Apex) `alfadaalwasaa.com` إلى النطاق الرسمي `www.alfadaalwasaa.com`.

---

## 7. ⚠️ تحذير أمني وتاريخ Git (Git History Rewrite)

> [!WARNING]
> تم تنظيف مستودع Git بالكامل وإزالة كائنات الصور القديمة غير المستخدمة (`attachments/`) عبر `git filter-repo` لتخفيض حجم المستودع من ~37MB إلى أقل من 6MB.
> **الآثار المترتبة:**
> - دفع هذه التغييرات إلى المستودع البعيد يتطلب أمر القوة: `git push --force origin main`.
> - يتوجب على جميع المطورين والمساهمين الذين لديهم نسخ محلية سابقة إعادة استنساخ المستودع (`git clone`) أو تنفيذ `git reset --hard origin/main` لتفادي تعارض التاريخ.
