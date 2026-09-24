/**
 * English Content & Translations for Al-Fada Al-Wasaa Corporate Website
 * Derived literally, professionally, and comprehensively from the corporate profile
 * Single Source of Truth for English Content
 */

export const EN_SITE_CONFIG = {
  // Corporate Identity
  company: {
    fullName: "Al-Fada Al-Wasaa Company for Telecom Services & General Contracting",
    shortName: "Al-Fada Al-Wasaa",
    enName: "AL-FADA AL-WASAA",
    tagline: "Integrated Solutions Within One Ecosystem",
    brief:
      "A multi-service professional entity founded on a clear vision: delivering integrated solutions that unite executive experience, institutional discipline, and the capacity to achieve high standards of quality and professionalism.",
    subBrief:
      "Since its inception, the company has been committed to being a reliable partner for organizations seeking solid performance, meticulous execution, and outcomes befitting major enterprise initiatives.",
    rss: "/en/rss.xml",
  },

  // Official Contact Channels & Directory
  contacts: {
    general: {
      label: "General Management",
      sublabel: "Unified & Direct Line",
      display: "+967 776 999 942",
      raw: "+967776999942",
      telHref: "tel:+967776999942",
      waNumber: "967776999942",
      waHref:
        "https://wa.me/967776999942?text=" +
        encodeURIComponent(
          "Hello, I would like to inquire about Al-Fada Al-Wasaa Company services."
        ),
    },

    deputy: {
      label: "Deputy General Manager",
      sublabel: "Projects & Commercial Follow-up",
      display: "+967 777 666 073",
      raw: "+967777666073",
      telHref: "tel:+967777666073",
      waNumber: "967777666073",
      waHref:
        "https://wa.me/967777666073?text=" +
        encodeURIComponent(
          "Hello, I would like to connect regarding Al-Fada Al-Wasaa projects and services."
        ),
    },

    location: {
      city: "Sana'a",
      fullAddress: "Sana'a — Beside Shamlan Factory, Republic of Yemen",
      label: "Corporate Headquarters",
      coverage: "Nationwide operational coverage across all Yemeni governorates and ports",
    },

    email: {
      address: "info@alfadaalwasaa.com",
      mailHref: "mailto:info@alfadaalwasaa.com",
      label: "Official Corporate Email",
    },

    workingHours: "Saturday – Thursday: 8:00 AM – 6:00 PM (24/7 Emergency Field Support)",
  },

  // Main Navigation Links (mirrors the Arabic nav structure: pages + homepage anchors)
  navItems: [
    { label: "Home", href: "/en" },
    { label: "Sectors", href: "/en#sectors" },
    { label: "Services", href: "/en#services" },
    { label: "About Us", href: "/en/about" },
    { label: "Track Record", href: "/en#track" },
    { label: "Blog", href: "/en/blog" },
    { label: "Contact Us", href: "/en/contact" },
  ],

  // Sector Options for Quotation Form
  sectorOptions: [
    "General Contracting & Construction",
    "Roads & Bridges Construction & Maintenance",
    "Excavation & Site Grading Works",
    "Petroleum Services & Fuel Supplies",
    "Telecommunications & Tech Solutions",
    "Logistics, Shipping & Customs Clearance",
    "Digital Marketing & Consulting",
    "General Inquiry or Technical Consultation",
  ],

  // Core Pillars
  pillars: [
    {
      title: "Executive Experience",
      subtitle: "Seasoned Field Practice",
    },
    {
      title: "Institutional Discipline",
      subtitle: "Strict Standards Adherence",
    },
    {
      title: "Quality & Professionalism",
      subtitle: "Enterprise-Grade Deliverables",
    },
  ],

  // Operational Indicators & Field Statistics (Matching Arabic exactly)
  stats: [
    {
      num: "10+",
      label: "Years of Accumulated Experience",
      sub: "Seasoned field practice in the Yemeni market",
    },
    {
      num: "65+",
      label: "Vital Completed Projects",
      sub: "Across contracting, telecom networks, and supplies",
    },
    {
      num: "45+",
      label: "Specialized Engineers & Experts",
      sub: "Dedicated field engineering, technical, and survey teams",
    },
    {
      num: "15+",
      label: "Governorates & Ports Covered",
      sub: "Operational readiness across Yemen's provinces and seaports",
    },
  ],

  // Strategic Sectors
  sectors: [
    {
      num: "01",
      title: "Telecommunications & Internet",
      services: [
        "Infrastructure and field networking solutions tailored to modern enterprise requirements.",
      ],
      photos: [
        { src: "/profile/site_telecom_tower.webp", alt: "Telecom towers and field microwave networks" },
        { src: "/profile/site_solar_array.webp", alt: "Solar energy systems powering telecom stations" },
      ],
    },
    {
      num: "02",
      title: "General Contracting",
      services: [
        "Construction and maintenance of roads and bridges.",
        "Excavation and site grading works.",
        "Construction supplies and provisioning.",
      ],
      photos: [
        { src: "/profile/site_mountain_station.webp", alt: "Construction works in mountain station sites" },
        { src: "/profile/road_roller.webp", alt: "Road paving and grading works" },
      ],
    },
    {
      num: "03",
      title: "Petroleum & Energy Services",
      services: [
        "Certified petroleum product supplies.",
        "Operational support and fueling logistics.",
      ],
      photos: [
        { src: "/profile/oil_tanks_truck.webp", alt: "Fuel supply tankers and transport" },
        { src: "/profile/oil_valve_flare.webp", alt: "Petroleum supply facilities" },
      ],
    },
    {
      num: "04",
      title: "Logistics & Customs Clearance",
      services: [
        "Multimodal shipping and port stevedoring.",
        "Customs clearance and supply chain management.",
      ],
      photos: [
        { src: "/profile/port_ship.webp", alt: "Sea freight operations in ports" },
        { src: "/profile/container_truck.webp", alt: "Land container transport" },
      ],
    },
    {
      num: "05",
      title: "Marketing & Digital Consulting",
      services: [
        "Digital marketing and digital footprint architecture.",
        "Specialized promotional and growth consulting.",
      ],
      photos: [
        { src: "/profile/marketing_laptop.webp", alt: "Marketing campaign analytics" },
        { src: "/profile/social_media.webp", alt: "Digital brand presence platforms" },
      ],
    },
  ],

  // Comprehensive Detailed Services List (7 services)
  servicesList: [
    {
      num: "01",
      slug: "contracting",
      title: "General Contracting",
      desc: "Executing civil, structural, and field engineering works in accordance with rigorous technical standards.",
    },
    {
      num: "02",
      slug: "roads",
      title: "Roads & Bridges",
      desc: "Construction, grading, and maintenance of vital transport infrastructure with heavy machinery fleets.",
    },
    {
      num: "03",
      slug: "excavation",
      title: "Excavation & Site Grading",
      desc: "Precision rock excavation, land leveling, and slope stabilization for large-scale developments.",
    },
    {
      num: "04",
      slug: "supplies",
      title: "Industrial & General Supplies",
      desc: "Securing industrial materials, spare parts, and operational essentials with strict quality control.",
    },
    {
      num: "05",
      slug: "telecom",
      title: "Telecom Networks & Tower Sites",
      desc: "Surveying, erecting, and maintaining cell towers, microwave links, and off-grid hybrid power systems.",
    },
    {
      num: "06",
      slug: "shipping",
      title: "Logistics & Customs Clearance",
      desc: "End-to-end port cargo clearance and overland heavy haulage with real-time tracking.",
    },
    {
      num: "07",
      slug: "marketing",
      title: "Digital Marketing & Branding",
      desc: "Building corporate digital authority, strategic positioning, and focused lead acquisition.",
    },
  ],

  // Track Record Project Case Studies
  trackRecord: [
    {
      id: "roads",
      title: "Road Paving, Grading & Mountain Earthworks",
      tag: "Civil & Infrastructure",
      desc: "Rock blasting, trenching, roadbed compaction, and asphalt surfacing alongside drainage culverts and rock slope stabilization in mountainous terrain.",
      metrics: "Code-compliant technical specifications with specialized heavy equipment fleets.",
      src: "/profile/track_roller.webp",
    },
    {
      id: "customs",
      title: "Port Customs Clearance & Supply Expediting",
      tag: "International Trade",
      desc: "High-efficiency commercial clearance for heavy machinery, cargo, and project imports across seaports and land border crossings.",
      metrics: "Accelerated port turnaround time with full regulatory compliance.",
      src: "/profile/track_ship.webp",
    },
    {
      id: "telecom",
      title: "Cell Tower Construction & Field Maintenance",
      tag: "Network Infrastructure",
      desc: "Civil works, lattice tower erection, antenna alignment, and deployment of hybrid solar-generator power systems with 24/7 emergency response.",
      metrics: "24/7 emergency readiness and maximum broadcast uptime in challenging remote sites.",
      src: "/profile/track_tower.webp",
    },
    {
      id: "supplies",
      title: "Industrial Supply Chains & Fuel Logistics",
      tag: "General Supplies",
      desc: "Procuring vital materials, technical supplies, and certified fuel consignments for key industrial operations under strict QA/QC testing.",
      metrics: "Stringent laboratory verification and on-time delivery schedules.",
      src: "/profile/track_forklift.webp",
    },
    {
      id: "logistics",
      title: "Multimodal Freight & Heavy Equipment Transport",
      tag: "Logistics Solutions",
      desc: "Managing dedicated heavy haulage fleets, oversized cargo routing, and live convoy tracking from entry ports directly to site locations.",
      metrics: "Modern GPS-tracked transport fleet with rigorous transit safety protocols.",
      src: "/profile/track_truck.webp",
    },
  ],

  // Core Working Methodology / Why Us
  values: [
    {
      title: "Results-Driven Mindset",
      desc: "A steadfast focus on hitting milestones and completing deliverables on budget and on schedule.",
    },
    {
      title: "Clear Methodology",
      desc: "Structured management, transparent tracking, and ongoing oversight across every project phase.",
    },
    {
      title: "Unwavering Commitment",
      desc: "Strict professional discipline, compliance with specifications, and building enduring client trust.",
    },
  ],

  // Strategic Position (from Profile)
  position: {
    kicker: "Our Standing",
    title: "Established Market Stature",
    p1: "The company was founded on the firm conviction that major enterprises seek more than a mere vendor—they require a dependable partner. Consequently, we accord utmost attention to engineering precision, procedural integrity, rigorous monitoring, and transparent communication across all operational stages, from initial design to final commissioning.",
    p2: "We are committed to ensuring our deliverables reflect an elevated corporate stature that harmonizes seriousness with agility, high quality with speed, and technical prowess with unwavering client dedication. Today, the company stands as the premier choice for organizations seeking project delivery through seasoned teams that master market dynamics and tackle complex, multi-tiered initiatives.",
  },

  // Vision & Mission (from Profile)
  visionMission: {
    title: "Vision & Mission",
    mission: {
      title: "Our Mission",
      text: "We strive to deliver reliable, integrated services centered on quality, transparency, discipline, and execution excellence, maintaining complete fidelity to client requirements and achieving top tiers of satisfaction and confidence.",
    },
    vision: {
      title: "Our Vision",
      text: "To lead as a regional benchmark in multi-sector contracting, telecommunications, and support logistics by building enduring strategic alliances with our partners and generating tangible value in every endeavor we undertake.",
    },
  },

  // Corporate Epilogue / Conclusion (from Profile)
  conclusion: {
    kicker: "Corporate Epilogue",
    title: "Executive Closing Statement",
    text: "Al-Fada Al-Wasaa Company for Telecom Services & General Contracting is not merely a brand in the marketplace; it is an integrated execution platform uniting operational vigor, refined professional conduct, and uncompromising precision. Today, we place seasoned field proficiency, strategic clarity, and genuine capability at the service of our clients, transforming ambitious requirements into enduring achievements.",
  },

  // Compliance & Institutional Certifications
  compliance: [
    {
      title: "Comprehensive Quality Management ISO 9001",
      subtitle: "Continuous Technical Auditing & Compliance",
      desc: "Applying international quality benchmarks across planning, materials testing, and staged milestone handover across all projects.",
      badge: "ISO 9001:2015",
    },
    {
      title: "Occupational Health & Safety ISO 45001",
      subtitle: "Strict Environmental & Preventive Protocols",
      desc: "Full adherence to HSE field safety procedures and personnel protection in challenging remote, mountainous, and rugged terrains.",
      badge: "HSE / ISO 45001",
    },
    {
      title: "Official Registrations & Sovereign Accreditations",
      subtitle: "Formal Certification Recognized by National Authorities",
      desc: "Holding valid general contracting classifications, commercial registry, customs clearance permits, and energy & telecom supply licenses.",
      badge: "Licensed & Accredited",
    },
    {
      title: "Building Code & Technical Standards Compliance",
      subtitle: "Continuous Laboratory Verification & Engineering Oversight",
      desc: "Executing civil, road, and telecom works in accordance with Yemeni and international engineering codes with documented lab tests.",
      badge: "Code Compliant",
    },
  ],

  // Client Testimonials
  testimonials: [
    {
      quote:
        "Al-Fada Al-Wasaa stood out for its rigorous engineering discipline in grading mountainous routes, strict adherence to highway code specifications, and timely lab compaction testing for subbase layers within the contracted milestone schedule.",
      name: "Eng. Abdulsalam Al-Qadi",
      role: "Infrastructure & Highway Projects Supervision Consultant",
      sector: "Civil & Infrastructure Sector",
    },
    {
      quote:
        "The speed of seaport customs clearance and direct convoy transport from docks to project sites saved our industrial initiatives critical time and substantial demurrage storage fees that previously burdened our supply chains.",
      name: "Adel Al-Hammadi",
      role: "Supply Chain & Logistics Director",
      sector: "Supplies & Port Logistics Sector",
    },
    {
      quote:
        "The 24/7 rapid deployment of field emergency crews and installation of off-grid hybrid solar power systems in remote, rugged topographies proved vital for maintaining broadcast uptime without operational interruption.",
      name: "Eng. Tareq Al-Sa'afani",
      role: "Telecom Operations & Maintenance Director",
      sector: "Telecom & Internet Sector",
    },
  ],

  // Partner Categories
  partnerCategories: [
    "Telecom & Internet Operators",
    "Oil & Energy Supply Sector",
    "Infrastructure & Road Contractors",
    "Port Logistics & Supply Chains",
    "Heavy Multimodal Fleet Transport",
    "Industrial & Equipment Importers",
    "Development & Enterprise Projects",
    "Certified Quality & Safety Systems",
  ],

  // Frequently Asked Questions
  faq: [
    {
      question: "What geographic areas does Al-Fada Al-Wasaa cover for project execution?",
      answer:
        "We operate across all governorates of the Republic of Yemen, with proven capability in demanding mountainous terrains, remote installations, and strategic ports including Sana'a, Hodeidah, Aden, and border trade crossings.",
    },
    {
      question: "How does the procurement and bidding process work?",
      answer:
        "Clients submit project specifications or Bills of Quantities (BOQ) through our online inquiry form or via direct management contact. Our engineering team conducts technical evaluations and site surveys to provide structured, competitive commercial proposals.",
    },
    {
      question: "What quality and safety standards are enforced across project sites?",
      answer:
        "We adhere strictly to recognized civil engineering codes and sector-specific standards, enforcing comprehensive Health, Safety, and Environmental (HSE) protocols alongside continuous laboratory testing of all construction materials.",
    },
    {
      question: "What operational capacity and heavy equipment fleet does the company own?",
      answer:
        "The company maintains a self-owned fleet of earthmovers, hydraulic excavators, compaction rollers, heavy transport trucks, and precision surveying instruments, backed by licensed field engineers.",
    },
    {
      question: "Does the company provide 24/7 technical support and maintenance for telecom networks?",
      answer:
        "Yes, our specialized field maintenance teams operate around the clock (24/7) for preventive and emergency interventions, microwave link alignment, and hybrid power supply maintenance.",
    },
  ],
} as const;

export type EnSiteConfig = typeof EN_SITE_CONFIG;
