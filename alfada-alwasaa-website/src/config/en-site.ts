/**
 * English Content & Translations for Al-Fada Al-Wasaa Corporate Website
 * Derived literally and professionally from the corporate profile
 */

export const EN_SITE_CONFIG = {
  company: {
    fullName: "Al-Fada Al-Wasaa Company for Telecom Services & General Contracting",
    shortName: "Al-Fada Al-Wasaa",
    enName: "AL-FADA AL-WASAA",
    tagline: "Integrated Solutions Within One Ecosystem",
    brief:
      "A multi-service professional entity founded on a clear vision: delivering integrated solutions that unite executive experience, institutional discipline, and the capacity to achieve high standards of quality and professionalism.",
    subBrief:
      "A trusted partner for organizations seeking solid performance, meticulous execution, and outcomes befitting major enterprise initiatives.",
  },

  navItems: [
    { label: "Home", href: "/en#home" },
    { label: "Sectors", href: "/en#sectors" },
    { label: "Services", href: "/en#services" },
    { label: "Track Record", href: "/en#track" },
    { label: "Why Us", href: "/en#why" },
    { label: "FAQ", href: "/en#faq" },
    { label: "Contact Us", href: "/en#contact" },
  ],

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

  stats: [
    {
      num: "5+",
      label: "Strategic Sectors",
      sub: "Comprehensive & interconnected coverage",
    },
    {
      num: "7+",
      label: "Integrated Service Systems",
      sub: "From planning through handover",
    },
    {
      num: "100%",
      label: "Standards & Specs Commitment",
      sub: "Rigorous execution discipline",
    },
    {
      num: "24/7",
      label: "Readiness & Response",
      sub: "Continuous on-site supervision",
    },
  ],

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
};
