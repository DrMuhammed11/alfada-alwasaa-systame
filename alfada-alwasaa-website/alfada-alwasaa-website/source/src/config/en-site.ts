/**
 * English Content & Translations for Al-Fada Al-Wasaa Corporate Website
 * Derived literally, professionally, and comprehensively from the corporate profile
 * Single Source of Truth for English Content
 */

export const EN_SITE_CONFIG = {
  // Corporate Identity
  company: {
    fullName: "Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting",
    shortName: "Al-Fada Al-Wasaa",
    enName: "Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting",
    tagline: "Integrated Solutions Under One Roof",
    brief:
      "A multi-service professional company founded on a clear vision: to deliver integrated solutions that combine operational experience, organizational discipline, and a strong commitment to quality and professionalism.",
    subBrief:
      "Since its inception, the company has been committed to serving as a trusted partner for organizations seeking dependable performance, precise execution, and results that meet the demands of major projects.",
    rss: "/en/rss.xml",
  },

  // Official Contact Channels & Directory
  contacts: {
    general: {
      label: "General Administration",
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
      fullAddress: "Near Shamlan Factory, Sana'a, Yemen",
      label: "Corporate Headquarters",
      coverage: "Nationwide operational coverage across all Yemeni governorates and ports",
    },

    email: {
      address: "info@alfadaalwasaa.com",
      mailHref: "mailto:info@alfadaalwasaa.com",
      label: "Official Corporate Email",
    },

    workingHours: "Saturday – Thursday: 8:00 AM – 6:00 PM",
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
    "Road Cutting & Paving",
    "Excavation & Engineering Backfill",
    "Telecom Towers & Networks",
    "Shipping & Customs Clearance",
    "General Supplies & Equipment",
    "Real Estate Marketing & Investment",
    "General Inquiry or Technical Consultation",
  ],

  // Core Pillars
  pillars: [
    {
      title: "Operational Experience",
      subtitle: "Proven Field Expertise",
    },
    {
      title: "Institutional Discipline",
      subtitle: "Strict Adherence to Standards",
    },
    {
      title: "Quality & Professionalism",
      subtitle: "High-Quality Professional Deliverables",
    },
  ],

  // Operational Indicators & Field Statistics (Matching Arabic exactly)
  stats: [
    {
      num: "10+",
      label: "Years of Experience",
      sub: "Extensive field experience in the Yemeni market",
    },
    {
      num: "65+",
      label: "Major Completed Projects",
      sub: "Across contracting, telecommunications, and supply services",
    },
    {
      num: "45+",
      label: "Specialized Engineers & Technical Personnel",
      sub: "Dedicated engineering, technical, and surveying teams",
    },
    {
      num: "15+",
      label: "Governorates Covered",
      sub: "Operational readiness across Yemen's governorates and seaports",
    },
  ],

  // Strategic Sectors
  sectors: [
    {
      num: "01",
      title: "Telecommunications & Internet",
      services: [
        "Infrastructure and field networking solutions tailored to the needs of modern businesses and organizations.",
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
        "Excavation and site grading.",
        "Construction materials and project supplies.",
      ],
      photos: [
        { src: "/profile/site_mountain_station.webp", alt: "Construction works in mountain station sites" },
        { src: "/profile/road_roller.webp", alt: "Road paving and grading works" },
      ],
    },
    {
      num: "03",
      title: "General Supplies & Equipment",
      services: [
        "Import and supply of construction materials.",
        "Cables, heavy equipment, and genuine spare parts.",
      ],
      photos: [
        { src: "/profile/track_forklift.webp", alt: "Forklift handling supplies at a field warehouse" },
        { src: "/profile/track_truck.webp", alt: "Heavy equipment and supply transport trucks" },
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
      title: "Real Estate Marketing & Investment",
      services: [
        "Real Estate Feasibility Studies & Asset Marketing",
        "Development Supervision & Asset Management",
      ],
      photos: [
        { src: "/profile/site_hadramout_building.webp", alt: "Developed residential building projects" },
        { src: "/profile/construction_building.webp", alt: "Real estate development sites" },
      ],
    },
  ],

  // Comprehensive Detailed Services List (7 services)
  servicesList: [
    {
      num: "01",
      slug: "contracting",
      title: "General Contracting & Construction",
      desc: "Residential and commercial buildings, concrete structures, finishing works, and government facilities.",
    },
    {
      num: "02",
      slug: "roads",
      title: "Road Cutting & Paving",
      desc: "Mountain and urban road corridors, asphalt paving, concrete culverts, and floodwater drainage.",
    },
    {
      num: "03",
      slug: "excavation",
      title: "Excavation & Engineering Backfill",
      desc: "Topographic leveling, rock excavation, plot preparation, compaction, and geotechnical testing.",
    },
    {
      num: "04",
      slug: "supplies",
      title: "General Supplies & Equipment",
      desc: "Import and supply of construction materials, cables, heavy equipment, and genuine spare parts.",
    },
    {
      num: "05",
      slug: "telecom",
      title: "Telecom Towers & Networks",
      desc: "Telecom tower construction, fiber optic networks, transmission stations, and solar power solutions for sites.",
    },
    {
      num: "06",
      slug: "shipping",
      title: "Shipping & Customs Clearance",
      desc: "Land and sea freight, customs release at ports and crossings, and supply chain management.",
    },
    {
      num: "07",
      slug: "marketing",
      title: "Real Estate Marketing & Investment",
      desc: "Feasibility studies, land and compound marketing, development, and real estate asset management.",
    },
  ],

  // Track Record Project Case Studies
  trackRecord: [
    {
      id: "roads",
      title: "Road Paving, Grading & Mountain Earthworks",
      tag: "Civil & Infrastructure",
      desc: "Rock blasting, trenching, roadbed compaction, and asphalt surfacing, together with drainage culverts and rock slope stabilization in mountainous terrain.",
      metrics: "Compliance with applicable technical specifications, supported by specialized heavy-equipment fleets and strong field capabilities.",
      src: "/profile/track_roller.webp",
    },
    {
      id: "customs",
      title: "Port Customs Clearance & Supply Coordination",
      tag: "International Trade",
      desc: "Efficient customs clearance for heavy machinery, cargo, and project-related imports through seaports and land border crossings.",
      metrics: "Efficient port turnaround with full compliance with applicable regulations.",
      src: "/profile/track_ship.webp",
    },
    {
      id: "telecom",
      title: "Telecommunications Tower Construction & Field Maintenance",
      tag: "Network Infrastructure",
      desc: "Civil works, lattice tower erection, antenna alignment, and deployment of hybrid solar-generator power systems, supported by 24/7 emergency response.",
      metrics: "24/7 emergency readiness and reliable network uptime at challenging remote sites.",
      src: "/profile/track_tower.webp",
    },
    {
      id: "supplies",
      title: "Industrial Supply Chains & Fuel Logistics",
      tag: "General Supplies",
      desc: "Procuring essential materials, technical supplies, and certified fuel supplies for key industrial operations under strict QA/QC controls.",
      metrics: "Strict laboratory verification and on-time delivery.",
      src: "/profile/track_forklift.webp",
    },
    {
      id: "logistics",
      title: "Multimodal Freight & Heavy Equipment Transport",
      tag: "Logistics Solutions",
      desc: "Managing dedicated heavy-haulage fleets, oversized-cargo routing, and live convoy tracking from ports of entry directly to project sites.",
      metrics: "A modern GPS-tracked transport fleet supported by rigorous transit-safety protocols.",
      src: "/profile/track_truck.webp",
    },
  ],

  // Core Working Methodology / Why Us
  values: [
    {
      title: "Results-Driven Mindset",
      desc: "A strong focus on achieving targets and completing tasks efficiently, consistently, and according to plan.",
    },
    {
      title: "Clear Methodology",
      desc: "Structured management, careful planning, and continuous oversight throughout every project phase, from initiation through final handover.",
    },
    {
      title: "Unwavering Commitment",
      desc: "Strict professional discipline, adherence to schedules and specifications, and a commitment to building long-term client relationships.",
    },
  ],

  // Strategic Position (from Profile)
  position: {
    kicker: "Our Standing",
    title: "Established Market Position & Confident Presence",
    p1: "The company was founded on the belief that major projects require more than a contractor; they require a dependable partner. For this reason, we place strong emphasis on careful planning, close field supervision, meticulous execution, and transparent communication with our partners throughout every stage of the project.",
    p2: "We are committed to ensuring that our deliverables consistently reflect a corporate approach that combines professionalism with flexibility, and high quality with well-managed execution. Today, the company stands as a trusted choice for organizations seeking reliable project delivery by teams that understand the local market and address challenges with a high level of professionalism.",
  },

  // Vision & Mission (from Profile)
  visionMission: {
    title: "Vision & Mission",
    mission: {
      title: "Our Mission",
      text: "We strive to deliver reliable, integrated services grounded in quality, transparency, discipline, and timely execution, while fully meeting our clients' requirements and earning their satisfaction and trust.",
    },
    vision: {
      title: "Our Vision",
      text: "To be the first choice and a recognized benchmark, locally and regionally, in general contracting, telecommunications, and support services, while building lasting strategic partnerships with our clients and making a meaningful contribution to community development.",
    },
  },

  // Corporate Epilogue / Conclusion (from Profile)
  conclusion: {
    kicker: "Corporate Epilogue",
    title: "Closing Remarks & Outlook",
    text: "Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting is more than a name in the contracting and telecommunications market; it is an integrated platform built on dedicated effort, high professional standards, and dependable execution. Today, we place our experience and capabilities at the service of our clients, ready to move forward with them toward broader opportunities and greater goals.",
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
        "We operate across all governorates of the Republic of Yemen, with established capabilities in challenging mountainous terrain, remote sites, and strategic ports, including Sana'a and major land-border crossings.",
    },
    {
      question: "How does the procurement and bidding process work?",
      answer:
        "Clients submit project specifications or a Bill of Quantities (BOQ) through our online inquiry form or by contacting management directly. Our engineering team then conducts technical evaluations and site inspections to prepare detailed and competitive commercial proposals.",
    },
    {
      question: "What quality and safety standards are enforced across project sites?",
      answer:
        "We strictly adhere to recognized civil engineering codes and sector-specific standards, applying comprehensive Health, Safety, and Environmental (HSE) procedures alongside continuous laboratory testing of construction materials.",
    },
    {
      question: "What operational capacity and heavy equipment fleet does the company own?",
      answer:
        "The company maintains its own fleet of earthmoving equipment, hydraulic excavators, compaction rollers, heavy-duty transport vehicles, and precision testing and inspection equipment, supported by qualified field engineers.",
    },
    {
      question: "Does the company provide 24/7 technical support and maintenance for telecom networks?",
      answer:
        "Yes. Our specialized field maintenance teams operate around the clock (24/7), providing preventive and emergency interventions, microwave-link alignment, and hybrid power-system maintenance.",
    },
  ],
} as const;

export type EnSiteConfig = typeof EN_SITE_CONFIG;
