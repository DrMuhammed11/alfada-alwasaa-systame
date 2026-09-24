import fs from "fs";
import path from "path";
import { SITE_CONFIG } from "../src/config/site.ts";
import { EN_SITE_CONFIG } from "../src/config/en-site.ts";
import { SERVICES_DATA } from "../src/config/services-data.ts";
import { EN_SERVICES_DATA } from "../src/config/en-services-data.ts";
import { BLOG_POSTS } from "../src/config/blog-data.ts";
import { EN_BLOG_POSTS } from "../src/config/en-blog-data.ts";

let md = `# ملف المراجعة اللغوية الشامل (عربي / English)
## شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة
## Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting

---

> **ملاحظة للمراجع اللغوي:**
> هذا الملف يجمع كافة النصوص المكتوبة في الموقع الرسمي (باللغتين العربية والإنجليزية)، مرتبة حسب الأقسام والصفحات لمطابقة الترجمة، التدقيق الإملائي، التحقق من المصطلحات الهندسية والتجارية، وتوحيد الأسلوب التحريري.

---

## 1. الهوية المؤسسية وبيانات التواصل (Corporate Identity & Contacts)

| العنصر | النسخة العربية | English Version |
|---|---|---|
| **الاسم الكامل** | ${SITE_CONFIG.company.fullName} | ${EN_SITE_CONFIG.company.fullName} |
| **الاسم المختصر** | ${SITE_CONFIG.company.shortName} | ${EN_SITE_CONFIG.company.shortName} |
| **الشعار اللفظي (Slogan)** | ${SITE_CONFIG.company.tagline} | ${EN_SITE_CONFIG.company.tagline} |
| **النبذة التعريفية الرئيسية** | ${SITE_CONFIG.company.brief} | ${EN_SITE_CONFIG.company.brief} |
| **النبذة التكميلية** | ${SITE_CONFIG.company.subBrief} | ${EN_SITE_CONFIG.company.subBrief} |
| **المقر والعنوان** | ${SITE_CONFIG.contacts.location.fullAddress} | ${EN_SITE_CONFIG.contacts.location.fullAddress} |
| **ساعات العمل** | ${SITE_CONFIG.contacts.workingHours} | ${EN_SITE_CONFIG.contacts.workingHours} |
| **تسمية الإدارة العامة** | ${SITE_CONFIG.contacts.general.label} | ${EN_SITE_CONFIG.contacts.general.label} |
| **تسمية نائب المدير** | ${SITE_CONFIG.contacts.deputy.label} | ${EN_SITE_CONFIG.contacts.deputy.label} |

---

## 2. روابط التنقل الرئيسية (Navigation Items)

| الرابط | النسخة العربية | English Version |
|---|---|---|
`;

for (let i = 0; i < SITE_CONFIG.navItems.length; i++) {
  const ar = SITE_CONFIG.navItems[i];
  const en = EN_SITE_CONFIG.navItems[i] || { label: "" };
  md += `| ${ar.href} | ${ar.label} | ${en.label} |\n`;
}

md += `
---

## 3. ركائز العمل الأساسية (Core Pillars)

| الركيزة | النسخة العربية | English Version |
|---|---|---|
`;

for (let i = 0; i < SITE_CONFIG.pillars.length; i++) {
  const ar = SITE_CONFIG.pillars[i];
  const en = EN_SITE_CONFIG.pillars[i] || { title: "", subtitle: "" };
  md += `| **${i + 1}** | **${ar.title}**: ${ar.subtitle} | **${en.title}**: ${en.subtitle} |\n`;
}

md += `
---

## 4. الرؤية، الرسالة، والتموضع في السوق (Vision, Mission & Market Position)

### أ. الرؤية والرسالة (Vision & Mission)
- **عنوان القسم بالعربية:** الرؤية والرسالة
- **عنوان القسم بالإنجليزية:** ${EN_SITE_CONFIG.visionMission.title}

#### الرسالة (Mission):
- **بالعربية:** نسعى لتقديم خدمات موثوقة ومتكاملة ترتكز على الجودة، الشفافية، الانضباط، والسرعة في التنفيذ، مع الالتزام التام بمتطلبات عملائنا وتحقيق أعلى درجات الرضا والثقة.
- **بالإنجليزية:** ${EN_SITE_CONFIG.visionMission.mission.text}

#### الرؤية (Vision):
- **بالعربية:** أن نكون الخيار الأول والنموذج الرائد محلياً وإقليمياً في مجالات المقاولات العامة، الاتصالات، والخدمات المساندة، من خلال بناء شراكات استراتيجية مستدامة مع عملائنا والمساهمة الفاعلة في تنمية المجتمع.
- **بالإنجليزية:** ${EN_SITE_CONFIG.visionMission.vision.text}

### ب. التموضع الاستراتيجي في السوق (Market Position)
- **العنوان بالعربية:** مكانة رصينة.. وحضور واثق في السوق
- **العنوان بالإنجليزية:** ${EN_SITE_CONFIG.position.title} (${EN_SITE_CONFIG.position.kicker})

#### الفقرة الأولى:
- **العربية:** انطلقت الشركة من إدراك عميق بأن المشاريع الكبرى لا تبحث عن مجرد مُنفّذ، بل عن شريك يمكن الاعتماد عليه. لهذا، نولي اهتمامًا فائقًا بالتفاصيل، ونحرص على التخطيط الدقيق، المتابعة الميدانية الصارمة، والتواصل الشفاف مع شركائنا في كل مرحلة من مراحل العمل.
- **الإنجليزية:** ${EN_SITE_CONFIG.position.p1}

#### الفقرة الثانية:
- **العربية:** نحن حريصون على أن تكون مخرجاتنا دائمًا انعكاسًا لصورة مؤسسية تجمع بين الجدية والمرونة، وبين الجودة العالية والسرعة المدروسة. اليوم، تقف الشركة كخيار موثوق للجهات التي تبحث عن تنفيذ مشاريعها بأيدي كوادر تفهم طبيعة السوق وتتعامل مع التحديات بمهنية عالية.
- **الإنجليزية:** ${EN_SITE_CONFIG.position.p2}

### ج. الخاتمة والتطلعات (Corporate Epilogue)
- **العنوان بالعربية:** خاتمة وتطلعات
- **العنوان بالإنجليزية:** ${EN_SITE_CONFIG.conclusion.title} (${EN_SITE_CONFIG.conclusion.kicker})
- **النص بالعربية:** إن شركة الفضاء الواسع ليست مجرد اسم في سوق المقاولات والاتصالات، بل هي منصة متكاملة للعمل الجاد، والسلوك المهني الرفيع، والإنجاز الموثوق. اليوم، نضع خبراتنا وإمكاناتنا في خدمة عملائنا، مستعدين للمضي معهم نحو آفاق أوسع وأهداف أكبر.
- **النص بالإنجليزية:** ${EN_SITE_CONFIG.conclusion.text}

---

## 5. منهجية العمل والقيم (Core Values / Why Us)

| القيمة | الشرح بالعربية | English Title | English Description |
|---|---|---|---|
`;

for (let i = 0; i < SITE_CONFIG.values.length; i++) {
  const ar = SITE_CONFIG.values[i];
  const en = EN_SITE_CONFIG.values[i] || { title: "", desc: "" };
  md += `| **${ar.title}** | ${ar.desc} | **${en.title}** | ${en.desc} |\n`;
}

md += `
---

## 6. القطاعات الاستراتيجية الخمسة (Strategic Sectors)
`;

for (const sec of EN_SITE_CONFIG.sectors) {
  md += `
### قطاع ${sec.num}: ${sec.title}
- **الخدمات المندرجة (Services):**
`;
  for (const s of sec.services) {
    md += `  - ${s}\n`;
  }
}

md += `
---

## 7. سابقة الأعمال ودراسات الحالة (Track Record Case Studies)

| المعرّف | التصنيف | العنوان بالعربية / الإنجليزية | نطاق التنفيذ والشواهد (العربية / English) |
|---|---|---|---|
`;

for (const tr of EN_SITE_CONFIG.trackRecord) {
  md += `| **${tr.id}** | ${tr.tag} | **${tr.title}** | ${tr.desc}<br/>*مؤشرات الجودة:* ${tr.metrics} |\n`;
}

md += `
---

## 8. الأسئلة الشائعة (Frequently Asked Questions - FAQ)
`;

for (let i = 0; i < EN_SITE_CONFIG.faq.length; i++) {
  const enItem = EN_SITE_CONFIG.faq[i];
  md += `
### س ${i + 1}: ${enItem.question}
**الإجابة:** ${enItem.answer}
`;
}

md += `
---

## 9. ملف الخدمات التخصصية السبع (Detailed Services Data)
`;

for (const [slug, service] of Object.entries(SERVICES_DATA)) {
  const enService = EN_SERVICES_DATA[slug] || {};
  md += `
### الخدمة: ${service.title} / ${enService.title || service.slug}
- **العنوان المختصر:** ${service.shortTitle} / ${enService.shortTitle || ""}
- **الوصف التمهيدي (العربية):** ${service.subtitle}
- **الوصف التمهيدي (English):** ${enService.subtitle || ""}
- **عنوان الـ SEO (عربي):** ${service.seoTitle}
- **عنوان الـ SEO (English):** ${enService.seoTitle || ""}
- **وصف الـ SEO (عربي):** ${service.seoDescription}
- **وصف الـ SEO (English):** ${enService.seoDescription || ""}

#### نبذة عامة (Overview):
**العربية:**
${service.overview.map((p) => `- ${p}`).join("\n")}

**English:**
${(enService.overview || []).map((p) => `- ${p}`).join("\n")}

#### ركائز ومواصفات التنفيذ (Features):
| الركيزة (عربي) | التفاصيل (عربي) | Feature (English) | Description (English) |
|---|---|---|---|
`;

  for (let fi = 0; fi < service.features.length; fi++) {
    const fAr = service.features[fi];
    const fEn = enService.features?.[fi] || { title: "", desc: "" };
    md += `| **${fAr.title}** | ${fAr.desc} | **${fEn.title}** | ${fEn.desc} |\n`;
  }

  md += `
#### المزايا التنافسية (Advantages):
- **العربية:**
${service.advantages.map((a) => `  - ${a}`).join("\n")}
- **English:**
${(enService.advantages || []).map((a) => `  - ${a}`).join("\n")}

#### الأسئلة الشائعة للخدمة (Service FAQs):
`;
  for (let qi = 0; qi < service.faqs.length; qi++) {
    const qAr = service.faqs[qi];
    const qEn = enService.faqs?.[qi] || { q: "", a: "" };
    md += `
**س ${qi + 1} (عربي):** ${qAr.q}  
**ج (عربي):** ${qAr.a}  
**Q ${qi + 1} (English):** ${qEn.q}  
**A (English):** ${qEn.a}  
`;
  }
}

md += `
---

## 10. مقالات المدونة الهندسية (Blog Articles)
`;

for (const [slug, post] of Object.entries(BLOG_POSTS)) {
  const enPost = EN_BLOG_POSTS[slug] || {};
  md += `
### مقال: ${post.title}
### Article: ${enPost.title || slug}

- **التصنيف:** ${post.category} | **Category:** ${enPost.category || ""}
- **تاريخ النشر:** ${post.date} | **وقت القراءة:** ${post.readTime} / ${enPost.readTime || ""}
- **الكاتب:** ${post.author} / ${enPost.author || ""}
- **الوصف المختصر (عربي):** ${post.description}
- **Short Description (English):** ${enPost.description || ""}

#### المقدمة (Intro):
- **العربية:** ${post.content.intro}
- **English:** ${enPost.content?.intro || ""}

#### محاور ومحتوى المقال (Sections):
`;

  for (let si = 0; si < post.content.sections.length; si++) {
    const sAr = post.content.sections[si];
    const sEn = enPost.content?.sections?.[si] || { heading: "", paragraphs: [] };
    md += `
##### المحور ${si + 1}: ${sAr.heading}
##### Section ${si + 1}: ${sEn.heading}

**فقرات المحور (عربي):**
${sAr.paragraphs.map((p) => `${p}\n`).join("\n")}

**Paragraphs (English):**
${sEn.paragraphs.map((p) => `${p}\n`).join("\n")}
`;
  }

  md += `
#### الخاتمة (Conclusion):
- **العربية:** ${post.content.conclusion}
- **English:** ${enPost.content?.conclusion || ""}
`;
}

const outputPath = path.resolve("..", "CONTENT_REVIEW_AR_EN.md");
fs.writeFileSync(outputPath, md, "utf-8");
const mirrorPath = path.resolve("CONTENT_REVIEW_AR_EN.md");
fs.writeFileSync(mirrorPath, md, "utf-8");

console.log("Successfully generated:", outputPath);
console.log("Size:", (md.length / 1024).toFixed(2), "KB");
