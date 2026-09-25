/**
 * بذرة محتويات الموقع الإلكتروني — تهيئة أولية بالبيانات الفعلية للشركة
 * (الخدمات، القطاعات، سابقة الأعمال، الأسئلة الشائعة، الإعدادات العامة).
 *
 * السكربت آمن للتكرار (idempotent):
 *  - الخدمات تُحدَّث بالمعرف slug والإعدادات بالمفتاح key
 *  - القطاعات/المشاريع/الأسئلة تُنشأ فقط إذا كان الجدول فارغًا
 *
 * تشغيل:
 *   npm run seed:content
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const SERVICES = [
  {
    slug: 'contracting',
    titleAr: 'المقاولات العامة والإنشاءات',
    titleEn: 'General Contracting & Construction',
    shortAr: 'تنفيذ المباني والمنشآت المدنية بمواصفات هندسية معتمدة من الأساسات حتى التسليم.',
    shortEn: 'Executing buildings and civil facilities to approved engineering specifications, from foundations to handover.',
    icon: 'Building2',
    image: '/profile/construction_building.webp',
    order: 1,
  },
  {
    slug: 'roads',
    titleAr: 'شق وتعبيد الطرق',
    titleEn: 'Roads Construction & Paving',
    shortAr: 'أعمال الطرق الداخلية والرابطة: شق، تسوية، أسفلت وأعمال الصرف المرافق.',
    shortEn: 'Internal and linking road works: cutting, grading, asphalt and allied drainage works.',
    icon: 'Route',
    image: '/profile/roads_work.webp',
    order: 2,
  },
  {
    slug: 'excavation',
    titleAr: 'الحفريات والردميات الهندسية',
    titleEn: 'Excavation & Engineering Backfilling',
    shortAr: 'حفريات بمقاسات دقيقة وردميات طبقية مضغوطة بأسطول ثقيل متكامل.',
    shortEn: 'Precision excavation and compacted layered backfilling with a full heavy fleet.',
    icon: 'Truck',
    image: '/profile/excavation_work.webp',
    order: 3,
  },
  {
    slug: 'telecom',
    titleAr: 'أبراج وشبكات الاتصالات',
    titleEn: 'Telecom Towers & Networks',
    shortAr: 'تشييد أبراج الاتصالات، تمديد شبكات الألياف الضوئية، والصيانة الوقائية والطارئة.',
    shortEn: 'Building telecom towers, fiber network rollout, and preventive & emergency maintenance.',
    icon: 'Antenna',
    image: '/profile/telecom_tower.webp',
    order: 4,
  },
  {
    slug: 'shipping',
    titleAr: 'الشحن والتخليص الجمركي',
    titleEn: 'Shipping & Customs Clearance',
    shortAr: 'شحن متعدد الوسائط وتخليص جمركي احترافي لسلاسل التوريد دون تأخير.',
    shortEn: 'Multimodal shipping and professional customs clearance for uninterrupted supply chains.',
    icon: 'Ship',
    image: '/profile/shipping_logistics.webp',
    order: 5,
  },
  {
    slug: 'supplies',
    titleAr: 'التوريدات العامة والتجهيزات',
    titleEn: 'General Supplies & Equipment',
    shortAr: 'توريد مواد البناء والتجهيزات الفنية والمكتبية بجودة موثوقة والتزام بالمواعيد.',
    shortEn: 'Supplying construction materials, technical and office equipment with reliable quality.',
    icon: 'Blocks',
    image: '/profile/supplies_store.webp',
    order: 6,
  },
  {
    slug: 'marketing',
    titleAr: 'التسويق العقاري والفرص الاستثمارية',
    titleEn: 'Real Estate Marketing & Investment Opportunities',
    shortAr: 'تسويق المشاريع العقارية ودراسة الفرص الاستثمارية للشركاء والعملاء.',
    shortEn: 'Marketing real estate projects and studying investment opportunities for partners and clients.',
    icon: 'TrendingUp',
    image: '/profile/marketing_estate.webp',
    order: 7,
  },
];

const SECTORS = [
  {
    titleAr: 'الاتصالات وتقنية المعلومات',
    titleEn: 'Telecom & IT',
    descAr: 'تشييد الأبراج وشبكات النقل والصيانة على مدار الساعة.',
    descEn: 'Tower construction, transport networks and around-the-clock maintenance.',
    icon: 'Antenna',
    order: 1,
  },
  {
    titleAr: 'المقاولات العامة',
    titleEn: 'General Contracting',
    descAr: 'منشآت مدنية وإنشائية متكاملة بجودة معتمدة.',
    descEn: 'Integrated civil and structural facilities with certified quality.',
    icon: 'Building2',
    order: 2,
  },
  {
    titleAr: 'التوريدات العامة والتجهيزات',
    titleEn: 'General Supplies & Equipment',
    descAr: 'توريد شامل للمواد والتجهيزات بضمان المصدر.',
    descEn: 'Comprehensive sourcing of materials and equipment with source warranty.',
    icon: 'Blocks',
    order: 3,
  },
  {
    titleAr: 'الخدمات اللوجستية',
    titleEn: 'Logistics Services',
    descAr: 'شحن وتخليص جمركي وسلاسل توريد متكاملة.',
    descEn: 'Shipping, customs clearance and integrated supply chains.',
    icon: 'Ship',
    order: 4,
  },
  {
    titleAr: 'التسويق العقاري والفرص الاستثمارية',
    titleEn: 'Real Estate Marketing & Investments',
    descAr: 'دراسة الفرص وتسويق المشاريع العقارية للشركاء.',
    descEn: 'Studying opportunities and marketing real estate projects for partners.',
    icon: 'TrendingUp',
    order: 5,
  },
];

const PROJECTS = [
  {
    titleAr: 'مشروعات الطرق والبنية التحتية',
    titleEn: 'Roads & Infrastructure Projects',
    tagAr: 'أعمال طرق وبنية تحتية',
    tagEn: 'Roads & Infrastructure',
    scopeAr: 'شق وتعبيد طرق داخلية ورابطة مع أعمال الصرف المرافق ضمن مشاريع تنموية متعددة المحافظات.',
    metrics: ['تنفيذ كميات كبيرة من طبقات الأساس والأسفلت', 'تسليم على مراحل وفق الجداول الزمنية'],
    order: 1,
  },
  {
    titleAr: 'أعمال التخليص الجمركي والتوريد',
    titleEn: 'Customs Clearance & Supply Operations',
    tagAr: 'مقاولات وأعمال مدنية ولوجستيات',
    tagEn: 'Contracting & Logistics',
    scopeAr: 'إدارة عمليات التخليص والنقل للمعدات والتجهيزات الثقيلة لمواقع المشاريع في مختلف المحافظات.',
    metrics: ['إنهاء معاملات نظامية دون تأخير', 'نقل آمن للمعدات الثقيلة إلى مواقع العمل'],
    order: 2,
  },
  {
    titleAr: 'أبراج وشبكات الاتصالات',
    titleEn: 'Telecom Towers & Networks Rollout',
    tagAr: 'اتصالات وتقنية معلومات',
    tagEn: 'Telecom & IT',
    scopeAr: 'تشييد أبراج اتصالات وتمديد شبكات نقل، مع عقود صيانة وقائية وطارئة على مدار الساعة.',
    metrics: ['مواقع أبراج مبنية ومسلّمة تشغيلياً', 'استجابة صيانة طارئة 24/7'],
    order: 3,
  },
  {
    titleAr: 'توريدات المشاريع والتجهيزات الفنية',
    titleEn: 'Project Supplies & Technical Equipment',
    tagAr: 'توريدات عامة',
    tagEn: 'General Supplies',
    scopeAr: 'توريد مواد البناء والتجهيزات الفنية لمشاريع حكومية وخاصة بجودة موثوقة.',
    metrics: ['مطابقة المواصفات المعتمدة', 'التزام جداول التوريد'],
    order: 4,
  },
  {
    titleAr: 'سلاسل الإمداد اللوجستية المتكاملة',
    titleEn: 'Integrated Logistics Supply Chains',
    tagAr: 'خدمات لوجستية',
    tagEn: 'Logistics Services',
    scopeAr: 'تشغيل سلاسل إمداد متعددة الوسائط من الميناء حتى موقع المشروع بإدارة مركزية.',
    metrics: ['تتبع كامل للشحنات', 'تكامل النقل والتخزين والتخليص'],
    order: 5,
  },
];

const FAQS = [
  {
    questionAr: 'ما هي النطاقات الجغرافية ومناطق تغطية الشركة لتنفيذ المشاريع؟',
    questionEn: 'What geographic areas does the company cover for project execution?',
    answerAr:
      'تغطي شركة الفضاء الواسع كافة محافظات ومناطق الجمهورية اليمنية، مع جاهزية متخصصة لتنفيذ المشاريع المدنية وشبكات الاتصالات في الميدان.',
    answerEn:
      'Al-Fadaa Al-Wasaa covers all governorates and regions of Yemen, with specialized readiness to execute civil projects and telecom networks in the field.',
    order: 1,
  },
  {
    questionAr: 'كيف تبدأ آلية التعاقد وطلب عروض الأسعار والدراسات الهندسية؟',
    questionEn: 'How does contracting and requesting quotations or engineering studies start?',
    answerAr:
      'تبدأ الإجراءات بتقديم العميل لمتطلبات المشروع أو جدول الكميات عبر نموذج الموقع أو التواصل المباشر مع الإدارة العامة، ويقوم فريقنا الهندسي بالدراسة وتقديم العرض.',
    answerEn:
      'The process starts when the client submits project requirements or a bill of quantities via the website form or direct contact; our engineering team studies and provides the offer.',
    order: 2,
  },
  {
    questionAr: 'ما هي معايير الجودة والسلامة المتبعة أثناء تنفيذ الأعمال والمشاريع؟',
    questionEn: 'What quality and safety standards are followed during execution?',
    answerAr:
      'نطبق معايير الجودة الهندسية والمواصفات القياسية المعتمدة لكل قطاع، مع الالتزام الصارم بضوابط السلامة والصحة المهنية والبيئية (HSE).',
    answerEn:
      'We apply approved engineering quality standards per sector, with strict commitment to health, safety and environmental (HSE) controls.',
    order: 3,
  },
  {
    questionAr: 'ما هي الجاهزية التشغيلية والأسطول المتوفر لدى الشركة في أعمال الطرق والإنشاءات؟',
    questionEn: 'What operational readiness and fleet does the company have for roads and construction?',
    answerAr:
      'تمتلك الشركة أسطولاً متكاملاً من المعدات والآليات الثقيلة (آليات التسوية، الحفارات، المداحل، والشاحنات)، مدعوماً بكوادر مساحية واستشارية متخصصة.',
    answerEn:
      'The company owns an integrated fleet of heavy equipment (graders, excavators, rollers and trucks), supported by specialized surveying and consulting staff.',
    order: 4,
  },
  {
    questionAr: 'كيف تُدار عمليات الشحن والتخليص الجمركي وسلاسل التوريد؟',
    questionEn: 'How are shipping, customs clearance and supply chains managed?',
    answerAr:
      'ندير سلاسل التخليص الجمركي والشحن متعدد الوسائط عبر فريق متخصص في الموانئ والمنافذ لإنهاء المعاملات النظامية والتحقق من الوثائق دون تأخير.',
    answerEn:
      'We run customs clearance and multimodal shipping through a specialized ports team that completes regulatory procedures and document checks without delay.',
    order: 5,
  },
  {
    questionAr: 'هل تقدم الشركة خدمات الصيانة والدعم الفني الطارئ لأبراج الاتصالات؟',
    questionEn: 'Does the company provide maintenance and emergency support for telecom towers?',
    answerAr:
      'نعم، تخصص الشركة فرق عمل هندسية وميدانية بنظام الطوارئ على مدار الساعة (24/7) لأعمال الصيانة الوقائية والطارئة وتركيب وتوجيه المايكروويف.',
    answerEn:
      'Yes, the company deploys engineering and field teams on a 24/7 emergency basis for preventive and urgent maintenance, plus microwave installation and alignment.',
    order: 6,
  },
];

const SETTINGS = [
  {
    key: 'contacts',
    description: 'بيانات التواصل الرسمية: الهاتف العام، هاتف النائب، العنوان، البريد، وساعات العمل',
    value: {
      general: { display: '+967 776 999 942', raw: '+967776999942' },
      deputy: { display: '+967 777 666 073', raw: '+967777666073' },
      location: { city: 'صنعاء', fullAddress: 'صنعاء — جوار مصنع شملان' },
      email: 'info@alfadaalwasaa.com',
      workingHours: 'السبت – الخميس: 8:00 صباحاً – 6:00 مساءً',
    },
  },
  {
    key: 'stats',
    description: 'أرقام الشركة المعروضة في الصفحة الرئيسية',
    value: [
      { num: '10+', label: 'سنوات من الخبرة المتراكمة' },
      { num: '65+', label: 'مشروعاً حيوياً منجزاً' },
      { num: '45+', label: 'مهندساً وكادراً تخصصياً' },
      { num: '15+', label: 'محافظة تشملها التغطية' },
    ],
  },
  {
    key: 'pillars',
    description: 'ركائز العرض الثلاث في قسم «لماذا نحن»',
    value: [
      { title: 'خبرة تنفيذية', subtitle: 'ممارسة ميدانية متمرسة' },
      { title: 'انضباط مؤسسي', subtitle: 'التزام دقيق بالمعايير' },
      { title: 'جودة واحتراف', subtitle: 'مخرجات رصينة تواكب الكبار' },
    ],
  },
  {
    key: 'values',
    description: 'قيم الشركة الثلاث في قسم لماذا نحن',
    value: [
      { title: 'عقلية النتائج', desc: 'تركيز كامل على تحقيق المستهدفات وإنجاز المهام وفق الخطة بأعلى كفاءة.' },
      { title: 'منهجية واضحة', desc: 'إدارة منظمة ودقة ومتابعة مستمرة لجميع مراحل العمل من البداية للتسليم.' },
      { title: 'التزام كامل', desc: 'انضباط مهني صارم بالمواعيد والمواصفات وبناء علاقات استراتيجية دائمة.' },
    ],
  },
];

async function main() {
  console.log('🌱 بدء تهيئة محتويات الموقع الإلكتروني...');

  // 1. الخدمات — upsert بالمعرف
  for (const s of SERVICES) {
    await prisma.siteService.upsert({
      where: { slug: s.slug },
      create: s,
      update: {
        titleAr: s.titleAr,
        titleEn: s.titleEn,
        shortAr: s.shortAr,
        shortEn: s.shortEn,
        icon: s.icon,
        image: s.image,
        order: s.order,
      },
    });
  }
  console.log(`  ✓ الخدمات: ${SERVICES.length} (upsert)`);

  // 2. القطاعات — إنشاء فقط إذا كان الجدول فارغًا
  const sectorsCount = await prisma.siteSector.count();
  if (sectorsCount === 0) {
    await prisma.siteSector.createMany({ data: SECTORS });
    console.log(`  ✓ القطاعات: ${SECTORS.length} (أُنشئت)`);
  } else {
    console.log(`  ⊘ القطاعات موجودة مسبقًا (${sectorsCount}) — تم التجاوز`);
  }

  // 3. سابقة الأعمال — نفس المنطق
  const projectsCount = await prisma.siteProject.count();
  if (projectsCount === 0) {
    await prisma.siteProject.createMany({ data: PROJECTS });
    console.log(`  ✓ سابقة الأعمال: ${PROJECTS.length} (أُنشئت)`);
  } else {
    console.log(`  ⊘ سابقة الأعمال موجودة مسبقًا (${projectsCount}) — تم التجاوز`);
  }

  // 4. الأسئلة الشائعة — نفس المنطق
  const faqsCount = await prisma.siteFaq.count();
  if (faqsCount === 0) {
    await prisma.siteFaq.createMany({ data: FAQS });
    console.log(`  ✓ الأسئلة الشائعة: ${FAQS.length} (أُنشئت)`);
  } else {
    console.log(`  ⊘ الأسئلة الشائعة موجودة مسبقًا (${faqsCount}) — تم التجاوز`);
  }

  // 5. الإعدادات العامة — upsert بالمفتاح
  for (const st of SETTINGS) {
    await prisma.siteSetting.upsert({
      where: { key: st.key },
      create: st,
      update: { value: st.value, description: st.description },
    });
  }
  console.log(`  ✓ الإعدادات: ${SETTINGS.length} (upsert)`);

  console.log('🎉 اكتملت تهيئة محتويات الموقع بنجاح.');
}

main()
  .catch((e) => {
    console.error('❌ فشل تنفيذ البذرة:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
