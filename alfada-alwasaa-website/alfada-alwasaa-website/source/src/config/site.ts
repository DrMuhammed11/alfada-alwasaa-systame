/**
 * المركز الرئيسي لكافة بيانات ومعلومات وهوية شركة الفضاء الواسع
 * Single Source of Truth for Site Data & Configurations
 */

export const SITE_CONFIG = {
  // الهوية المؤسسية الرسمية
  company: {
    fullName: "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات",
    shortName: "شركة الفضاء الواسع",
    enName: "AL-FADA AL-WASAA",
    tagline: "حلول متكاملة ضمن منظومة واحدة",
    brief:
      "كيان مهني متعدد الخدمات، تأسس على رؤية واضحة تقوم على تقديم حلول متكاملة تجمع بين الخبرة التنفيذية، والانضباط المؤسسي، والقدرة على الإنجاز بمعايير عالية من الجودة والاحتراف.",
    subBrief:
      "ومنذ انطلاقتها، حرصت الشركة على أن تكون شريكًا موثوقًا للجهات التي تبحث عن أداء رصين، وتنفيذ دقيق، ونتائج تليق بتطلعات المشاريع الكبرى.",
  },

  // أرقام وقنوات التواصل الرسمية
  contacts: {
    // الإدارة العامة
    general: {
      label: "الإدارة العامة",
      sublabel: "الهاتف الموحد والمباشر",
      display: "+967 776 999 942",
      raw: "+967776999942",
      telHref: "tel:+967776999942",
      waNumber: "967776999942",
      waHref:
        "https://wa.me/967776999942?text=" +
        encodeURIComponent(
          "السلام عليكم ورحمة الله، أود الاستفسار عن خدمات شركة الفضاء الواسع"
        ),
    },

    // نائب المدير العام
    deputy: {
      label: "نائب المدير العام",
      sublabel: "متابعة المشاريع والتعاقدات",
      display: "+967 777 666 073",
      raw: "+967777666073",
      telHref: "tel:+967777666073",
      waNumber: "967777666073",
      waHref:
        "https://wa.me/967777666073?text=" +
        encodeURIComponent(
          "السلام عليكم ورحمة الله، أود التواصل بخصوص مشاريع وخدمات شركة الفضاء الواسع"
        ),
    },

    // المقر والعنوان
    location: {
      city: "صنعاء",
      fullAddress: "صنعاء — جوار مصنع شملان",
      label: "المقر الرئيسي",
    },

    // البريد الإلكتروني الرسمي
    email: {
      address: "info@alfadaalwasaa.com",
      mailHref: "mailto:info@alfadaalwasaa.com",
      label: "البريد الإلكتروني الرسمي",
    },

    // أوقات وساعات العمل
    workingHours: "السبت – الخميس: 8:00 صباحاً – 6:00 مساءً",
  },

  // شريط الروابط والتنقل الموحد
  navItems: [
    { label: "الرئيسية ومن نحن", href: "#home" },
    { label: "قطاعاتنا", href: "#sectors" },
    { label: "خدماتنا", href: "#services" },
    { label: "مكانتنا", href: "#position" },
    { label: "رؤيتنا ورسالتنا", href: "#vision" },
    { label: "سابقة الأعمال", href: "#track" },
    { label: "لماذا نحن", href: "#why" },
    { label: "تواصل معنا", href: "#contact" },
  ],

  // خيارات قطاعات ونماذج طلب التسعير
  sectorOptions: [
    "المقاولات العامة والإنشاءات",
    "إنشاء وصيانة الطرق والجسور",
    "أعمال الحفريات وتسوية المواقع",
    "خدمات النفط والتوريدات البترولية",
    "خدمات الاتصالات والحلول التقنية",
    "الخدمات اللوجستية والشحن والتخليص",
    "التسويق الإلكتروني والاستشارات",
    "طلب استشارة أو خدمات عامة",
  ],

  // ركائز العمل الأساسية الثلاث
  pillars: [
    {
      title: "خبرة تنفيذية",
      subtitle: "ممارسة ميدانية متمرسة",
    },
    {
      title: "انضباط مؤسسي",
      subtitle: "التزام دقيق بالمعايير",
    },
    {
      title: "جودة واحتراف",
      subtitle: "مخرجات رصينة تواكب الكبار",
    },
  ],

  // الأصول الرسمية المعتمدة
  assets: {
    logoTransparent: "/profile/logo_transparent.png",
    logoMark: "/profile/logo_mark.png",
    sectorIconsStrip: "/profile/sector_icons_strip.png",
    heroBg: "/profile/hero_bg.jpeg",
  },
} as const;

export type SiteConfig = typeof SITE_CONFIG;
