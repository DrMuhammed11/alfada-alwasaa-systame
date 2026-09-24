/**
 * مولّد ملف مراجعة الترجمة لصفحات الخدمات السبع (عربي / English)
 * يقرأ ملفي البيانات المرجعيين ويولّد ملف Markdown بجداول متقابلة
 * تسهّل المراجعة اللغوية والمطابقة بين النسختين سطراً بسطر.
 *
 * التشغيل:  node --experimental-strip-types scripts/generate-services-translation-review.mjs
 * (يعاد تشغيله بعد أي تعديل على ملفات البيانات لإعادة توليد الملف)
 */
import fs from "fs";
import path from "path";
import { SERVICES_DATA } from "../src/config/services-data.ts";
import { EN_SERVICES_DATA } from "../src/config/en-services-data.ts";

const esc = (s) => String(s ?? "").replace(/\|/g, "\\|").replace(/\n/g, " ");
const num2 = (n) => String(n).padStart(2, "0");

let md = `# مراجعة الترجمة — صفحات الخدمات السبع (عربي ⇄ English)
# Services Translation Review — The Seven Service Pages

**شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة**
**Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting**

> **طريقة الاستخدام:** كل جدول يعرض النص العربي والإنجليزي متقابلين صفّاً بصف.
> راجع المطابقة، الدقة المصطلحية (الهندسية والتجارية)، والأسلوب التحريري،
> وعلّم الملاحظات بجانب الصف المطلوب تعديله ثم أرسلها لتطبيق التعديلات
> في ملفي المصدر: \`src/config/services-data.ts\` و \`src/config/en-services-data.ts\`.
>
> **Note:** Every table places the Arabic and English texts side by side,
> row by row, for translation accuracy, terminology, and tone review.
>
> هذا الملف مُولَّد آلياً من ملفي البيانات — لا تُحرَّر يدوياً.
> This file is auto-generated from the data sources — do not edit manually.

---

`;

const slugs = Object.keys(SERVICES_DATA);
slugs.forEach((slug, sIdx) => {
  const ar = SERVICES_DATA[slug];
  const en = EN_SERVICES_DATA[slug] || {};
  const n = sIdx + 1;

  md += `## ${num2(n)}) ${ar.title} ⇄ ${en.title}\n\n`;
  md += `**المسار / URL:** \`/services/${slug}\` ⇄ \`/en/services/${slug}\`\n\n`;

  /* 1. العناوين والوصف */
  md += `### ${num2(n)}.1 العناوين والوصف التعريفي — Titles & Subtitle\n\n`;
  md += `| الحقل | العربية | English |\n|---|---|---|\n`;
  md += `| العنوان الرئيسي | ${esc(ar.title)} | ${esc(en.title)} |\n`;
  md += `| العنوان المختصر | ${esc(ar.shortTitle)} | ${esc(en.shortTitle)} |\n`;
  md += `| الوصف التعريفي | ${esc(ar.subtitle)} | ${esc(en.subtitle)} |\n\n`;

  /* 2. النظرة العامة */
  md += `### ${num2(n)}.2 النظرة العامة — Overview\n\n`;
  md += `| # | العربية | English |\n|---|---|---|\n`;
  ar.overview.forEach((p, i) => {
    md += `| ${i + 1} | ${esc(p)} | ${esc(en.overview?.[i] ?? "—")} |\n`;
  });
  md += `\n`;

  /* 3. نطاق الأعمال */
  md += `### ${num2(n)}.3 نطاق الأعمال والقدرات — Scope of Work & Capabilities\n\n`;
  md += `| # | العربية (العنوان / الوصف) | English (Title / Desc) |\n|---|---|---|\n`;
  ar.features.forEach((f, i) => {
    const e = en.features?.[i];
    md += `| ${i + 1} | **${esc(f.title)}** — ${esc(f.desc)} | **${esc(e?.title ?? "—")}** — ${esc(e?.desc ?? "—")} |\n`;
  });
  md += `\n`;

  /* 4. مزايا الشراكة */
  md += `### ${num2(n)}.4 مزايا الشراكة — Partnership Advantages\n\n`;
  md += `| # | العربية | English |\n|---|---|---|\n`;
  ar.advantages.forEach((a, i) => {
    md += `| ${i + 1} | ${esc(a)} | ${esc(en.advantages?.[i] ?? "—")} |\n`;
  });
  md += `\n`;

  /* 5. منهجية العمل */
  md += `### ${num2(n)}.5 منهجية العمل — How We Work (Process)\n\n`;
  md += `| المرحلة | العربية (العنوان / الوصف) | English (Title / Desc) |\n|---|---|---|\n`;
  ar.process.forEach((st, i) => {
    const e = en.process?.[i];
    md += `| ${i + 1} | **${esc(st.title)}** — ${esc(st.desc)} | **${esc(e?.title ?? "—")}** — ${esc(e?.desc ?? "—")} |\n`;
  });
  md += `\n`;

  /* 6. المؤشرات وبطاقة الحقائق */
  md += `### ${num2(n)}.6 المؤشرات السريعة وبطاقة الحقائق — Highlights & Quick Facts\n\n`;
  md += `| العنصر | العربية | English |\n|---|---|---|\n`;
  ar.highlights.forEach((h, i) => {
    const e = en.highlights?.[i];
    md += `| مؤشر ${i + 1} | **${esc(h.value)}** ${esc(h.label)} | **${esc(e?.value ?? "—")}** ${esc(e?.label ?? "—")} |\n`;
  });
  ar.facts.forEach((f, i) => {
    const e = en.facts?.[i];
    md += `| حقيقة ${i + 1} | **${esc(f.label)}:** ${esc(f.value)} | **${esc(e?.label ?? "—")}:** ${esc(e?.value ?? "—")} |\n`;
  });
  md += `\n`;

  /* 7. الأسئلة الشائعة */
  md += `### ${num2(n)}.7 الأسئلة الشائعة — FAQ\n\n`;
  md += `| # | السؤال (عربي ⇄ EN) | الجواب (عربي ⇄ EN) |\n|---|---|---|\n`;
  ar.faqs.forEach((fq, i) => {
    const e = en.faqs?.[i];
    md += `| ${i + 1} | **${esc(fq.q)}**<br>—<br>**${esc(e?.q ?? "—")}** | ${esc(fq.a)}<br>—<br>${esc(e?.a ?? "—")} |\n`;
  });
  md += `\n`;

  /* 8. نصوص SEO */
  md += `### ${num2(n)}.8 نصوص محركات البحث — SEO Texts\n\n`;
  md += `| الحقل | العربية | English |\n|---|---|---|\n`;
  md += `| عنوان SEO | ${esc(ar.seoTitle)} | ${esc(en.seoTitle ?? "—")} |\n`;
  md += `| وصف SEO | ${esc(ar.seoDescription)} | ${esc(en.seoDescription ?? "—")} |\n`;
  md += `| الكلمات المفتاحية | ${ar.keywords.map(esc).join("، ")} | ${(en.keywords ?? []).map(esc).join(", ")} |\n\n`;

  md += `---\n\n`;
});

md += `## ملاحظات المراجع اللغوي — Reviewer Notes\n\n`;
md += `| الصفحة | الموضع (رقم الجدول/الصف) | الملاحظة | التصحيح المقترح |\n|---|---|---|---|\n`;
md += `|  |  |  |  |\n`;

const outputPath = path.resolve("SERVICES_TRANSLATION_REVIEW_AR_EN.md");
fs.writeFileSync(outputPath, md, "utf-8");
const sizeKB = (Buffer.byteLength(md, "utf-8") / 1024).toFixed(1);
console.log(`Successfully generated: ${outputPath}`);
console.log(`Size: ${sizeKB} KB | Services: ${slugs.length} (AR+EN)`);
