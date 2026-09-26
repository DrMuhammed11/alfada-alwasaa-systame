/**
 * زرع محتوى الموقع على الإنتاج عبر واجهة الإدارة (بلا وصول مباشر لقاعدة البيانات)
 * الاستخدام: node scripts/seed-site-content-api.mjs
 */
import { readFileSync } from 'fs';

const API = 'https://alfada-alwasaa-systame.onrender.com/api/v1';
const token = readFileSync(new URL('../.deploy-token', import.meta.url), 'utf8').trim();

const H = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` };

async function post(path, body) {
  const res = await fetch(`${API}${path}`, { method: 'POST', headers: H, body: JSON.stringify(body) });
  const text = await res.text();
  if (!res.ok && res.status !== 409) throw new Error(`${path} → ${res.status}: ${text.slice(0, 160)}`);
  return res.status;
}

async function put(path, body) {
  const res = await fetch(`${API}${path}`, { method: 'PUT', headers: H, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${(await res.text()).slice(0, 160)}`);
}

const SERVICES = [
  { slug: 'contracting', titleAr: 'المقاولات العامة والإنشاءات', titleEn: 'General Contracting & Construction', shortAr: 'تنفيذ المباني والمنشآت المدنية بمواصفات هندسية معتمدة من الأساسات حتى التسليم.', shortEn: 'Executing buildings and civil facilities to approved engineering specifications.', icon: 'Building2', image: '/profile/construction_building.webp', order: 1 },
  { slug: 'roads', titleAr: 'شق وتعبيد الطرق', titleEn: 'Roads Construction & Paving', shortAr: 'أعمال الطرق الداخلية والرابطة: شق، تسوية، أسفلت وأعمال الصرف المرافق.', shortEn: 'Internal and linking road works: cutting, grading, asphalt and drainage.', icon: 'Route', image: '/profile/roads_work.webp', order: 2 },
  { slug: 'excavation', titleAr: 'الحفريات والردميات الهندسية', titleEn: 'Excavation & Engineering Backfilling', shortAr: 'حفريات بمقاسات دقيقة وردميات طبقية مضغوطة بأسطول ثقيل متكامل.', shortEn: 'Precision excavation and compacted backfilling with a heavy fleet.', icon: 'Truck', image: '/profile/excavation_work.webp', order: 3 },
  { slug: 'telecom', titleAr: 'أبراج وشبكات الاتصالات', titleEn: 'Telecom Towers & Networks', shortAr: 'تشييد أبراج الاتصالات، تمديد شبكات الألياف، والصيانة الوقائية والطارئة.', shortEn: 'Telecom towers, fiber rollout, and preventive & emergency maintenance.', icon: 'Antenna', image: '/profile/telecom_tower.webp', order: 4 },
  { slug: 'shipping', titleAr: 'الشحن والتخليص الجمركي', titleEn: 'Shipping & Customs Clearance', shortAr: 'شحن متعدد الوسائط وتخليص جمركي احترافي لسلاسل التوريد دون تأخير.', shortEn: 'Multimodal shipping and professional customs clearance.', icon: 'Ship', image: '/profile/shipping_logistics.webp', order: 5 },
  { slug: 'supplies', titleAr: 'التوريدات العامة والتجهيزات', titleEn: 'General Supplies & Equipment', shortAr: 'توريد مواد البناء والتجهيزات الفنية والمكتبية بجودة موثوقة.', shortEn: 'Construction materials and technical equipment with reliable quality.', icon: 'Blocks', image: '/profile/supplies_store.webp', order: 6 },
  { slug: 'marketing', titleAr: 'التسويق العقاري والفرص الاستثمارية', titleEn: 'Real Estate Marketing & Investments', shortAr: 'تسويق المشاريع العقارية ودراسة الفرص الاستثمارية للشركاء والعملاء.', shortEn: 'Marketing real estate projects and studying investment opportunities.', icon: 'TrendingUp', image: '/profile/marketing_estate.webp', order: 7 },
];

const SECTORS = [
  { titleAr: 'الاتصالات وتقنية المعلومات', titleEn: 'Telecom & IT', descAr: 'تشييد الأبراج وشبكات النقل والصيانة على مدار الساعة.', descEn: 'Tower construction, transport networks and 24/7 maintenance.', icon: 'Antenna', order: 1 },
  { titleAr: 'المقاولات العامة', titleEn: 'General Contracting', descAr: 'منشآت مدنية وإنشائية متكاملة بجودة معتمدة.', descEn: 'Integrated civil and structural facilities with certified quality.', icon: 'Building2', order: 2 },
  { titleAr: 'التوريدات العامة والتجهيزات', titleEn: 'General Supplies & Equipment', descAr: 'توريد شامل للمواد والتجهيزات بضمان المصدر.', descEn: 'Comprehensive sourcing of materials and equipment.', icon: 'Blocks', order: 3 },
  { titleAr: 'الخدمات اللوجستية', titleEn: 'Logistics Services', descAr: 'شحن وتخليص جمركي وسلاسل توريد متكاملة.', descEn: 'Shipping, customs clearance and integrated supply chains.', icon: 'Ship', order: 4 },
  { titleAr: 'التسويق العقاري والفرص الاستثمارية', titleEn: 'Real Estate Marketing & Investments', descAr: 'دراسة الفرص وتسويق المشاريع العقارية للشركاء.', descEn: 'Studying opportunities and marketing real estate projects.', icon: 'TrendingUp', order: 5 },
];

const PROJECTS = [
  { titleAr: 'مشروعات الطرق والبنية التحتية', titleEn: 'Roads & Infrastructure Projects', tagAr: 'أعمال طرق وبنية تحتية', tagEn: 'Roads & Infrastructure', scopeAr: 'شق وتعبيد طرق داخلية ورابطة مع أعمال الصرف المرافق ضمن مشاريع تنموية متعددة المحافظات.', metrics: ['تنفيذ كميات كبيرة من طبقات الأساس والأسفلت', 'تسليم على مراحل وفق الجداول الزمنية'], order: 1 },
  { titleAr: 'أعمال التخليص الجمركي والتوريد', titleEn: 'Customs Clearance & Supply Operations', tagAr: 'مقاولات ولوجستيات', tagEn: 'Contracting & Logistics', scopeAr: 'إدارة عمليات التخليص والنقل للمعدات والتجهيزات الثقيلة لمواقع المشاريع في مختلف المحافظات.', metrics: ['إنهاء معاملات نظامية دون تأخير', 'نقل آمن للمعدات الثقيلة'], order: 2 },
  { titleAr: 'أبراج وشبكات الاتصالات', titleEn: 'Telecom Towers & Networks Rollout', tagAr: 'اتصالات وتقنية معلومات', tagEn: 'Telecom & IT', scopeAr: 'تشييد أبراج اتصالات وتمديد شبكات نقل، مع عقود صيانة وقائية وطارئة على مدار الساعة.', metrics: ['مواقع أبراج مبنية ومسلّمة تشغيلياً', 'استجابة صيانة طارئة 24/7'], order: 3 },
  { titleAr: 'توريدات المشاريع والتجهيزات الفنية', titleEn: 'Project Supplies & Technical Equipment', tagAr: 'توريدات عامة', tagEn: 'General Supplies', scopeAr: 'توريد مواد البناء والتجهيزات الفنية لمشاريع حكومية وخاصة بجودة موثوقة.', metrics: ['مطابقة المواصفات المعتمدة', 'التزام جداول التوريد'], order: 4 },
  { titleAr: 'سلاسل الإمداد اللوجستية المتكاملة', titleEn: 'Integrated Logistics Supply Chains', tagAr: 'خدمات لوجستية', tagEn: 'Logistics Services', scopeAr: 'تشغيل سلاسل إمداد متعددة الوسائط من الميناء حتى موقع المشروع بإدارة مركزية.', metrics: ['تتبع كامل للشحنات', 'تكامل النقل والتخزين والتخليص'], order: 5 },
];

const FAQS = [
  { questionAr: 'ما هي النطاقات الجغرافية ومناطق تغطية الشركة لتنفيذ المشاريع؟', questionEn: 'What geographic areas does the company cover?', answerAr: 'تغطي شركة الفضاء الواسع كافة محافظات ومناطق الجمهورية اليمنية، مع جاهزية متخصصة لتنفيذ المشاريع المدنية وشبكات الاتصالات في الميدان.', answerEn: 'Al-Fadaa Al-Wasaa covers all governorates of Yemen with specialized field readiness.', order: 1 },
  { questionAr: 'كيف تبدأ آلية التعاقد وطلب عروض الأسعار والدراسات الهندسية؟', questionEn: 'How does contracting and requesting quotations start?', answerAr: 'تبدأ الإجراءات بتقديم العميل لمتطلبات المشروع أو جدول الكميات عبر نموذج الموقع أو التواصل المباشر مع الإدارة العامة، ويقوم فريقنا الهندسي بالدراسة وتقديم العرض.', answerEn: 'Submit project requirements or a bill of quantities via the website form or direct contact; our engineering team provides the offer.', order: 2 },
  { questionAr: 'ما هي معايير الجودة والسلامة المتبعة أثناء تنفيذ الأعمال والمشاريع؟', questionEn: 'What quality and safety standards are followed?', answerAr: 'نطبق معايير الجودة الهندسية والمواصفات القياسية المعتمدة لكل قطاع، مع الالتزام الصارم بضوابط السلامة والصحة المهنية والبيئية (HSE).', answerEn: 'Approved engineering quality standards per sector with strict HSE commitment.', order: 3 },
  { questionAr: 'ما هي الجاهزية التشغيلية والأسطول المتوفر لدى الشركة؟', questionEn: 'What operational readiness and fleet does the company have?', answerAr: 'تمتلك الشركة أسطولاً متكاملاً من المعدات والآليات الثقيلة (آليات التسوية، الحفارات، المداحل، والشاحنات)، مدعوماً بكوادر مساحية واستشارية متخصصة.', answerEn: 'An integrated heavy-equipment fleet supported by specialized surveying and consulting staff.', order: 4 },
  { questionAr: 'كيف تُدار عمليات الشحن والتخليص الجمركي وسلاسل التوريد؟', questionEn: 'How are shipping and customs clearance managed?', answerAr: 'ندير سلاسل التخليص الجمركي والشحن متعدد الوسائط عبر فريق متخصص في الموانئ والمنافذ لإنهاء المعاملات النظامية دون تأخير.', answerEn: 'A specialized ports team completes regulatory procedures without delay.', order: 5 },
  { questionAr: 'هل تقدم الشركة خدمات الصيانة والدعم الفني الطارئ لأبراج الاتصالات؟', questionEn: 'Is emergency maintenance available for telecom towers?', answerAr: 'نعم، تخصص الشركة فرق عمل هندسية وميدانية بنظام الطوارئ على مدار الساعة (24/7) لأعمال الصيانة الوقائية والطارئة.', answerEn: 'Yes — engineering and field teams on a 24/7 emergency basis.', order: 6 },
];

const SETTINGS = [
  { key: 'contacts', description: 'بيانات التواصل الرسمية', value: { general: { display: '+967 776 999 942', raw: '+967776999942' }, deputy: { display: '+967 777 666 073', raw: '+967777666073' }, location: { city: 'صنعاء', fullAddress: 'صنعاء — جوار مصنع شملان' }, email: 'info@alfadaalwasaa.com', workingHours: 'السبت – الخميس: 8:00 صباحاً – 6:00 مساءً' } },
  { key: 'stats', description: 'أرقام الشركة المعروضة في الرئيسية', value: [ { num: '10+', label: 'سنوات من الخبرة المتراكمة' }, { num: '65+', label: 'مشروعاً حيوياً منجزاً' }, { num: '45+', label: 'مهندساً وكادراً تخصصياً' }, { num: '15+', label: 'محافظة تشملها التغطية' } ] },
  { key: 'pillars', description: 'ركائز العرض الثلاث', value: [ { title: 'خبرة تنفيذية', subtitle: 'ممارسة ميدانية متمرسة' }, { title: 'انضباط مؤسسي', subtitle: 'التزام دقيق بالمعايير' }, { title: 'جودة واحتراف', subtitle: 'مخرجات رصينة تواكب الكبار' } ] },
  { key: 'values', description: 'قيم الشركة الثلاث', value: [ { title: 'عقلية النتائج', desc: 'تركيز كامل على تحقيق المستهدفات وإنجاز المهام وفق الخطة بأعلى كفاءة.' }, { title: 'منهجية واضحة', desc: 'إدارة منظمة ودقة ومتابعة مستمرة لجميع مراحل العمل من البداية للتسليم.' }, { title: 'التزام كامل', desc: 'انضباط مهني صارم بالمواعيد والمواصفات وبناء علاقات استراتيجية دائمة.' } ] },
];

let ok = 0, skip = 0;
for (const s of SERVICES) {
  const st = await post('/site-content/manage/services', s);
  st === 201 ? ok++ : skip++;
}
console.log(`الخدمات: ${ok} أُنشئت`);
for (const s of SECTORS) { await post('/site-content/manage/sectors', s); }
console.log(`القطاعات: ${SECTORS.length}`);
for (const p of PROJECTS) { await post('/site-content/manage/projects', p); }
console.log(`المشاريع: ${PROJECTS.length}`);
for (const f of FAQS) { await post('/site-content/manage/faqs', f); }
console.log(`الأسئلة: ${FAQS.length}`);
for (const st of SETTINGS) { await put(`/site-content/manage/settings/${st.key}`, { value: st.value, description: st.description }); }
console.log(`الإعدادات: ${SETTINGS.length}`);
console.log('🎉 اكتمل زرع محتوى الإنتاج عبر API');
