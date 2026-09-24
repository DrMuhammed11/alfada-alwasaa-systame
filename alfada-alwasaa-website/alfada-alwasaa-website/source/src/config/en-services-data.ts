/**
 * English counterpart of `services-data.ts` — the canonical list of the seven
 * detailed service pages for Al-Fada Al-Wasaa (Sana'a, Yemen):
 * General Contracting & Construction, Road Cutting & Paving, Excavation &
 * Engineering Backfill, Telecom Towers & Networks, Shipping & Customs
 * Clearance, General Supplies & Equipment, Real Estate Marketing & Investment.
 *
 * - `slug`, `image`, and `galleryImages` are kept EXACTLY identical to the
 *   Arabic file so both locales resolve the same assets and routes.
 * - The `ServiceDetail` type is imported from the Arabic source to guarantee
 *   structural parity between both locales at compile time.
 * - All textual content is professionally translated corporate English.
 */

import type { ServiceDetail } from "./services-data";

export type { ServiceIconName } from "./services-data";

export const EN_SERVICES_DATA: Record<string, ServiceDetail> = {
  contracting: {
    slug: "contracting",
    title: "General Contracting & Construction",
    shortTitle: "General Contracting",
    subtitle:
      "Residential and commercial buildings, concrete structures, finishing works, and government facilities.",
    seoTitle: "General Contracting & Construction Company in Sana'a | Al-Fada Al-Wasaa",
    seoDescription:
      "Al-Fada Al-Wasaa for general contracting and construction in Sana'a, Yemen. Residential and commercial buildings, concrete structures, finishing works, and government facilities. Call: +967776999942",
    keywords: [
      "contracting company Sana'a",
      "general contracting Yemen",
      "building contractor Sana'a",
      "residential and commercial construction",
      "concrete structures Yemen",
      "architectural finishing Sana'a",
      "government facilities contractor Yemen",
      "Al-Fada Al-Wasaa contracting",
    ],
    image: "/profile/construction_building.webp",
    galleryImages: [
      "/profile/construction_building.webp",
      "/profile/site_hadramout_building.webp",
      "/profile/track_forklift.webp",
    ],
    overview: [
      "Al-Fada Al-Wasaa stands among the leading firms in the general contracting and construction sector in the Republic of Yemen, combining seasoned hands-on field experience with the latest engineering methodologies in the delivery of major residential, commercial, and government projects.",
      "Across every scope of our work — from concrete structures to final finishing — we adhere strictly to international specifications and standards and to agreed delivery schedules, providing turnkey solutions that run from drawing studies all the way to final handover.",
    ],
    features: [
      {
        title: "Residential & Commercial Buildings",
        desc: "Delivering residential blocks, towers, and commercial centers with precise structural planning and disciplined site management.",
        icon: "Building2",
      },
      {
        title: "Concrete & Steel Structures",
        desc: "Pouring foundations, columns, and slabs, and erecting steel structures for warehouses and hangars with state-of-the-art equipment.",
        icon: "Blocks",
      },
      {
        title: "Finishing, Insulation & Facades",
        desc: "Plastering and painting works, thermal and waterproof insulation, and installation of glass facades and cladding.",
        icon: "PaintRoller",
      },
      {
        title: "Government & Public Facilities",
        desc: "Delivering government buildings and public service facilities in full compliance with official authorities' requirements.",
        icon: "Landmark",
      },
      {
        title: "Restoration & Structural Rehabilitation",
        desc: "Structural safety assessment, reinforcement of columns and slabs, and upgrading of older buildings to modern safety codes.",
        icon: "Hammer",
      },
      {
        title: "Engineering Supervision & QC",
        desc: "Independent supervision, laboratory soil and concrete testing, and documented conformity certificates for every execution stage.",
        icon: "ClipboardCheck",
      },
    ],
    advantages: [
      "A qualified engineering and supervision team with long field experience in the Yemeni market.",
      "A complete fleet of equipment and heavy machinery to guarantee speed of delivery.",
      "Strict commitment to approved budgets with no hidden costs or delays.",
      "A documented track record of successful works with major institutions and government bodies in Yemen.",
      "Clear contracts with structured payment milestones and detailed bills of quantities.",
      "Institutional coordination with the company's other sectors: roads, excavation, and supplies.",
    ],
    process: [
      {
        title: "Consultation & Site Visit",
        desc: "Site reconnaissance, understanding project requirements, and defining the initial scope of work.",
      },
      {
        title: "Technical Study & Pricing",
        desc: "Analysis of drawings and bills of quantities, culminating in a detailed and transparent quotation.",
      },
      {
        title: "Contracting & Execution Planning",
        desc: "Signing the contract, preparing the schedule, and mobilizing materials, machinery, and the site.",
      },
      {
        title: "Execution & Field Supervision",
        desc: "Stage-by-stage execution under continuous engineering supervision with periodic quality testing.",
      },
      {
        title: "Handover & Follow-up",
        desc: "Turnkey handover with official acceptance minutes and post-delivery follow-up.",
      },
    ],
    highlights: [
      { value: "10+", label: "Years of execution experience" },
      { value: "65+", label: "Delivered projects" },
      { value: "45+", label: "Engineers & specialists" },
      { value: "15+", label: "Governorates covered" },
    ],
    facts: [
      { label: "Coverage", value: "Sana'a and all Yemeni governorates" },
      { label: "Contract models", value: "Turnkey or partial scopes" },
      { label: "Quality control", value: "Laboratory testing & independent supervision" },
      { label: "Documentation", value: "Official contracts, BOQs, and minutes" },
    ],
    faqs: [
      {
        q: "Which geographic areas do your contracting services cover?",
        a: "We deliver our services in the capital Sana'a and across all governorates of the Republic of Yemen, with resident crews capable of managing remote field sites.",
      },
      {
        q: "How are construction projects priced?",
        a: "Pricing is based on a detailed study of the bills of quantities and engineering drawings, supported by a competitive and transparent cost analysis tailored to the client's requirements.",
      },
      {
        q: "Do you execute government facilities under official specifications?",
        a: "Yes, we hold a documented record of delivering government and service facilities in full compliance with official conditions and technical requirements.",
      },
      {
        q: "Do you provide independent engineering supervision?",
        a: "Yes, we offer engineering supervision, quality control, and soil and concrete testing services carried out by certified engineers.",
      },
    ],
  },

  roads: {
    slug: "roads",
    title: "Road Cutting & Paving",
    shortTitle: "Road Cutting & Paving",
    subtitle:
      "Mountain and urban road corridors, asphalt paving, concrete culverts, and floodwater drainage.",
    seoTitle: "Road Cutting, Paving & Asphalting in Yemen | Al-Fada Al-Wasaa",
    seoDescription:
      "Road cutting and paving works in Sana'a and Yemen: mountain and urban corridors, asphalt paving, stone paving, concrete culverts, and floodwater drainage. Call: +967776999942",
    keywords: [
      "road cutting Yemen",
      "road paving Sana'a",
      "asphalting Yemen",
      "stone paving and interlock Sana'a",
      "concrete culverts Yemen",
      "floodwater drainage roads",
      "road maintenance Sana'a",
    ],
    image: "/profile/road_roller.webp",
    galleryImages: [
      "/profile/road_roller.webp",
      "/profile/track_roller.webp",
      "/profile/track_truck.webp",
    ],
    overview: [
      "Road networks are the economic lifeline of Yemen; Al-Fada Al-Wasaa therefore places its expertise and mechanical capabilities at the service of cutting and paving mountain and urban corridors to the highest load-bearing and traffic-safety specifications.",
      "We operate asphalt plants, modern rollers, milling machines, and pavers that ensure precise gradients, an even riding surface, and tolerance of heavy axle loads — alongside concrete culverts and floodwater drainage systems that protect roads from seasonal washouts.",
    ],
    features: [
      {
        title: "Road Cutting & Corridor Opening",
        desc: "Cutting mountain and urban roads, grading sections, and stabilizing slopes with retaining walls.",
        icon: "Route",
      },
      {
        title: "Hot-Mix Asphalting & Paving",
        desc: "Laying asphalt courses to approved standard mixes engineered for Yemen's climate and temperatures.",
        icon: "Truck",
      },
      {
        title: "Stone Paving & Interlock",
        desc: "Paving streets with natural stone and interlocking tiles, building sidewalks, and finishing gradients.",
        icon: "LayoutGrid",
      },
      {
        title: "Concrete Culverts & Bridges",
        desc: "Constructing box and pipe culverts and surface bridges to approved concrete specifications.",
        icon: "Milestone",
      },
      {
        title: "Floodwater Drainage",
        desc: "Excavating channels, installing ducts, and building waterways that protect roads from seasonal erosion.",
        icon: "Waves",
      },
      {
        title: "Maintenance & Rehabilitation",
        desc: "Treating cracks and potholes, milling deteriorated asphalt, and re-asphalting to restore aging roads.",
        icon: "Wrench",
      },
    ],
    advantages: [
      "High readiness to operate in mountainous and rugged terrain with complete efficiency.",
      "Regular laboratory testing of asphalt and bitumen samples as well as compaction density.",
      "Application of traffic-safety specifications, directional signage, and lane markings.",
      "Rapid response for repairing damaged roads and reopening vital corridors.",
      "Direct integration with the company's excavation and backfill sector.",
      "A fleet of rollers, milling machines, and pavers fully owned by the company.",
    ],
    process: [
      {
        title: "Topographic Corridor Survey",
        desc: "Surveying the alignment, studying levels and gradients, and locating drainage points.",
      },
      {
        title: "Technical Study & Pricing",
        desc: "Analyzing quantities and mix ratios and preparing a detailed technical and financial offer.",
      },
      {
        title: "Cutting & Subgrade Preparation",
        desc: "Cut and fill works, compaction of base layers, and preparation of the road cross-section.",
      },
      {
        title: "Paving & Asphalting",
        desc: "Executing asphalt or stone-paving courses together with culverts and drainage.",
      },
      {
        title: "Testing & Handover",
        desc: "Density and load testing, safety signage, then official handover.",
      },
    ],
    highlights: [
      { value: "Mountain", label: "& urban corridors — mixed terrain" },
      { value: "100%", label: "Documented compaction & density tests" },
      { value: "65+", label: "Projects in the execution record" },
      { value: "24/7", label: "Readiness for vital-corridor maintenance" },
    ],
    facts: [
      { label: "Corridor types", value: "Mountain, urban, and inter-city links" },
      { label: "Companion works", value: "Culverts, drainage, retaining walls" },
      { label: "Quality control", value: "Standard Proctor & Marshall lab tests" },
      { label: "Safety", value: "Standard signage and lane markings" },
    ],
    faqs: [
      {
        q: "Do you execute road projects in rugged or mountainous areas?",
        a: "Yes, we have extensive experience overcoming Yemen's challenging terrain — cutting alignments across slopes and stabilizing embankments with retaining walls.",
      },
      {
        q: "What standards do you follow for soil compaction and asphalt testing?",
        a: "We rely on standard Proctor testing for soil density and Marshall testing for asphalt mixes, ensuring the road remains serviceable for many years.",
      },
      {
        q: "Do your works include culverts and floodwater drainage?",
        a: "Yes, we build box and pipe culverts and floodwater drainage systems as an integral part of road projects or as standalone works.",
      },
      {
        q: "Do you offer periodic road maintenance contracts?",
        a: "Yes, we conclude annual maintenance contracts covering scheduled treatment of cracks and potholes and re-asphalting according to an agreed plan.",
      },
    ],
  },

  excavation: {
    slug: "excavation",
    title: "Excavation & Engineering Backfill",
    shortTitle: "Excavation & Backfill",
    subtitle:
      "Topographic leveling, rock excavation, plot preparation, compaction, and geotechnical testing.",
    seoTitle: "Excavation & Engineering Backfill Works in Sana'a | Al-Fada Al-Wasaa",
    seoDescription:
      "Excavation and engineering backfill services in Sana'a and Yemen: topographic leveling, rock excavation, plot preparation, compaction, and certified geotechnical testing. Contact: +967776999942",
    keywords: [
      "excavation works Sana'a",
      "engineering backfill Yemen",
      "topographic leveling Yemen",
      "rock excavation Sana'a",
      "compaction and geotechnical testing",
      "land plot preparation Yemen",
      "excavator rental Sana'a",
    ],
    image: "/profile/site_mountain_station.webp",
    galleryImages: [
      "/profile/site_mountain_station.webp",
      "/profile/track_truck.webp",
      "/profile/road_roller.webp",
    ],
    overview: [
      "The founding phase is the bedrock of any construction project's success; Al-Fada Al-Wasaa therefore provides an integrated system of excavation and engineering backfill works: precise topographic leveling, rock excavation, plot preparation, and certified compaction and geotechnical testing.",
      "With hydraulic-breaker excavators and high-capacity dump trucks, we prepare sites efficiently and in the shortest possible timeframe — prioritizing the safety of neighboring structures and documenting the density of every layer.",
    ],
    features: [
      {
        title: "Topographic Site Leveling",
        desc: "Surveying and leveling land to approved levels while controlling gradients and elevations.",
        icon: "Mountain",
      },
      {
        title: "Foundation & Basement Excavation",
        desc: "Executing excavations for residential and commercial buildings with shoring and protection of adjacent properties.",
        icon: "Shovel",
      },
      {
        title: "Rock Excavation & Hydraulic Breaking",
        desc: "Fragmenting hard rock and basalt layers with hydraulic breakers — without cracking neighboring buildings.",
        icon: "Hammer",
      },
      {
        title: "Engineering Backfill & Compaction",
        desc: "Supplying selected backfill material (sub-base) and compacting in uniform layers while measuring moisture and density.",
        icon: "Layers",
      },
      {
        title: "Development Plot Preparation",
        desc: "Leveling land for residential compounds, factories, and farms, including opening internal roadways.",
        icon: "LandPlot",
      },
      {
        title: "Geotechnical Testing",
        desc: "Proctor and field-density testing with documented results against approved laboratory correlations.",
        icon: "FlaskConical",
      },
    ],
    advantages: [
      "A fleet of excavators in a range of sizes for work in both open and confined spaces.",
      "A professional operating crew and certified operators with full compliance with occupational safety standards.",
      "Rapid hauling of debris and soil to officially approved disposal sites.",
      "Complete geotechnical documentation that protects the client through subsequent construction stages.",
      "Competitive pricing based on the volume of works and contracting speed.",
      "Direct integration with the company's contracting and road-cutting sectors.",
    ],
    process: [
      {
        title: "Survey & Study",
        desc: "Measuring levels, fixing the grading elevation, and computing cut-and-fill quantities.",
      },
      {
        title: "Pricing & Contracting",
        desc: "A clear offer per cubic meter or lump sum, with a binding execution schedule.",
      },
      {
        title: "Excavation & Breaking",
        desc: "Excavating to approved dimensions and elevations, with rock breaking where required.",
      },
      {
        title: "Layered Backfill & Compaction",
        desc: "Placing and compacting selected layers, testing the density of each layer and documenting it.",
      },
      {
        title: "Handover with Conformity Report",
        desc: "Handing over the site at final levels with the complete geotechnical testing report.",
      },
    ],
    highlights: [
      { value: "Level-true", label: "Grading to approved elevations" },
      { value: "Rock-ready", label: "Excavation with hydraulic breakers" },
      { value: "Per-layer", label: "Compaction with density testing" },
      { value: "48h", label: "Equipment mobilization after contract" },
    ],
    facts: [
      { label: "Coverage", value: "Sana'a and all Yemeni governorates" },
      { label: "Ground types", value: "Soil, sandy, and basaltic rock" },
      { label: "Quality control", value: "Documented geotechnical tests per layer" },
      { label: "Safety", value: "Shored excavation sides & neighbor protection" },
    ],
    faqs: [
      {
        q: "Do you provide excavation-side shoring for neighboring buildings?",
        a: "Yes, we apply appropriate shoring and support techniques to guarantee the safety of neighboring properties and prevent any ground subsidence during deep excavation.",
      },
      {
        q: "How do you handle extremely hard rocky ground?",
        a: "We deploy heavy excavators equipped with advanced hydraulic breakers and specialized rock saws that ensure precision and speed of execution.",
      },
      {
        q: "Do your works include geotechnical testing?",
        a: "Yes, we run Proctor and field-density tests for every compacted layer and issue a certified report documenting the site's readiness for construction.",
      },
      {
        q: "What is the typical site-preparation timeframe?",
        a: "It depends on excavation volume and soil type; as a rule, our equipment starts working within 48 hours of contract completion and drawing readiness.",
      },
    ],
  },

  telecom: {
    slug: "telecom",
    title: "Telecom Towers & Networks",
    shortTitle: "Telecom Towers & Networks",
    subtitle:
      "Telecom tower construction, fiber optic networks, transmission stations, and solar power solutions for sites.",
    seoTitle: "Telecom Tower Construction & Networks in Yemen | Al-Fada Al-Wasaa",
    seoDescription:
      "Al-Fada Al-Wasaa builds telecom towers, fiber optic networks, transmission stations, and solar power solutions for sites across Yemen. Call: +967776999942",
    keywords: [
      "telecom towers Yemen",
      "telecom tower construction Sana'a",
      "fiber optic networks Yemen",
      "transmission stations Yemen",
      "solar power for telecom sites",
      "telecom tower maintenance Sana'a",
      "tower civil works Yemen",
    ],
    image: "/profile/telecom_tower_sky.webp",
    galleryImages: [
      "/profile/telecom_tower_sky.webp",
      "/profile/telecom_antenna_city.webp",
      "/profile/site_solar_array.webp",
      "/profile/site_power_inverters.webp",
    ],
    overview: [
      "The Al-Fada Al-Wasaa team holds an exceptional record in constructing telecom towers and building network infrastructure across Yemen, working with the leading operators and internet service providers from civil works all the way to tower on-air activation.",
      "We deliver an integrated system covering: civil works for foundations, erection of lattice and monopole towers, fiber optic network deployment, transmission-station and microwave builds, and hybrid solar power solutions for mountain and remote sites that keep transmissions running around the clock.",
    ],
    features: [
      {
        title: "Civil Works & Tower Foundations",
        desc: "Excavating and pouring concrete foundations to approved engineering dimensions with concrete strength testing.",
        icon: "HardHat",
      },
      {
        title: "Lattice & Monopole Tower Erection",
        desc: "Installing lattice and monopole towers at varying heights with bolt torquing to certified values.",
        icon: "RadioTower",
      },
      {
        title: "Transmission Stations & Microwave",
        desc: "Building transmission stations and mounting and aligning microwave links and RF connectors with high pointing accuracy.",
        icon: "Signal",
      },
      {
        title: "Fiber Optic Networks",
        desc: "Trenching and deploying aerial and underground fiber cables, and splicing fibers with advanced fusion splicers.",
        icon: "Cable",
      },
      {
        title: "Solar Power Solutions for Sites",
        desc: "Designing and building photovoltaic stations with lithium battery banks to run remote sites 24/7.",
        icon: "Sun",
      },
      {
        title: "Antenna Installation & Alignment",
        desc: "Mounting RF antennas and setting their orientations and pairings to approved coverage plans.",
        icon: "Wifi",
      },
      {
        title: "Earthing & Lightning Protection",
        desc: "Building earthing networks, measuring resistance, and installing lightning protection to international specifications.",
        icon: "Bolt",
      },
      {
        title: "Preventive & Emergency Maintenance",
        desc: "Preventive maintenance programs and rapid-response crews for tower emergencies and record-time on-air restoration.",
        icon: "Wrench",
      },
    ],
    advantages: [
      "Rope-access climbing and maintenance teams trained and certified to the highest international safety standards.",
      "Deep experience operating within Yemen's complex geographic and climatic environment.",
      "The ability to carry out emergency maintenance and restore transmission in record time.",
      "Trusted strategic partnerships with the leading local telecommunications operators.",
      "One integrated system covering civil works, erection, power, and maintenance.",
      "Dozens of solar power stations delivered for remote sites, documented in our portfolio.",
    ],
    process: [
      {
        title: "Survey & Site Selection",
        desc: "Technical visit, access and elevation study, and defining foundation and power requirements.",
      },
      {
        title: "Civil Works & Foundations",
        desc: "Excavating and pouring the concrete foundation and building the equipment room and earthing network.",
      },
      {
        title: "Erection & Topside Installations",
        desc: "Erecting the tower, mounting antennas and microwave systems, and aligning orientations.",
      },
      {
        title: "Power Systems & Activation",
        desc: "Installing solar or generator power and batteries, then running commissioning tests and on-air activation.",
      },
      {
        title: "Documentation & Maintenance",
        desc: "Documented handover with measurements and tests, plus a periodic preventive maintenance plan.",
      },
    ],
    highlights: [
      { value: "24/7", label: "Uptime across operated sites" },
      { value: "Dozens", label: "Solar power stations delivered" },
      { value: "45+", label: "Certified engineers & climbers" },
      { value: "15+", label: "Governorates within coverage" },
    ],
    facts: [
      { label: "Tower types", value: "Lattice and monopole structures" },
      { label: "Power systems", value: "Hybrid solar, battery banks, generators" },
      { label: "Quality control", value: "Documented earthing & resistance tests" },
      { label: "Safety", value: "Certified climbing teams with approved gear" },
    ],
    faqs: [
      {
        q: "Do you execute both the tower's civil works and its erection?",
        a: "Yes, we operate as one system covering foundation excavation and pouring, tower erection, topside installations, power, and earthing — without needing more than one contractor.",
      },
      {
        q: "Do you build solar power stations for telecom towers?",
        a: "Yes, we have successfully delivered dozens of hybrid solar power stations for remote sites, a record fully documented in our project portfolio.",
      },
      {
        q: "What preventive maintenance services do you offer for towers?",
        a: "They include bolt-torque inspection, corrosion checks, earthing and lightning system testing, and assessment of battery and generator performance.",
      },
      {
        q: "Do you deploy urban fiber optic networks?",
        a: "Yes, we deploy aerial and underground fiber extensions with fusion splicing and optical-loss testing.",
      },
    ],
  },

  shipping: {
    slug: "shipping",
    title: "Shipping & Customs Clearance",
    shortTitle: "Shipping & Clearance",
    subtitle:
      "Land and sea freight, customs release at ports and crossings, and supply chain management.",
    seoTitle: "Shipping & Customs Clearance Company in Yemen | Al-Fada Al-Wasaa",
    seoDescription:
      "Al-Fada Al-Wasaa for shipping and customs clearance in Yemen: land and sea freight, customs release at ports and crossings, and supply chain management. Call: +967776999942",
    keywords: [
      "customs clearance Yemen",
      "shipping company Sana'a",
      "customs release Hodeidah and Aden ports",
      "land and sea freight Yemen",
      "supply chain management Yemen",
      "container transport Sana'a",
      "licensed customs broker Yemen",
    ],
    image: "/profile/container_truck.webp",
    galleryImages: [
      "/profile/container_truck.webp",
      "/profile/port_ship.webp",
      "/profile/track_ship.webp",
      "/profile/track_truck.webp",
    ],
    overview: [
      "Trade and freight logistics are the backbone of development; Al-Fada Al-Wasaa therefore delivers integrated shipping and customs clearance services: land and sea freight, customs release at ports and crossings, and supply chain management through to the client's doorstep.",
      "We bring wide-ranging relationships and a precise command of all customs regulations, tariffs, and exemption schemes — saving our clients time and effort as well as demurrage charges and late-penalty costs.",
    ],
    features: [
      {
        title: "Sea Freight & Shipment Tracking",
        desc: "Booking sea space, following bills of lading, and monitoring arrival schedules at ports.",
        icon: "Ship",
      },
      {
        title: "Land Freight & Inland Distribution",
        desc: "A fleet of well-equipped trucks (trailers, flatbeds, platforms) hauling containers and goods to every governorate.",
        icon: "Truck",
      },
      {
        title: "Customs Release at Ports & Crossings",
        desc: "Completing release procedures at Hodeidah and Aden seaports and land crossings with precision and full legal compliance.",
        icon: "FileCheck",
      },
      {
        title: "Documents, Permits & Conformity",
        desc: "Liaising with the standards authority and agricultural/health quarantine, and obtaining every official permit.",
        icon: "FileText",
      },
      {
        title: "Storage & Logistics Solutions",
        desc: "Secured, fully equipped storage space for the sorting, loading, and unloading of goods and heavy equipment.",
        icon: "Warehouse",
      },
      {
        title: "Supply Chain Management",
        desc: "End-to-end planning of goods movement from source to warehouse with periodic tracking reports.",
        icon: "Network",
      },
    ],
    advantages: [
      "Licensed customs brokers with extensive command of ever-changing regulations and procedures.",
      "Comprehensive insurance and live tracking of your shipments until they reach their final destination.",
      "Reduced waiting times and avoidance of penalties and additional ground-rent fees.",
      "A high capacity to handle special cargo and oversized equipment.",
      "A land transport network covering every governorate from ports and airports.",
      "Complete transparency on fees and official charges from day one.",
    ],
    process: [
      {
        title: "Document Intake",
        desc: "Auditing the bill of lading, invoice, certificate of origin, and packing list before the shipment arrives.",
      },
      {
        title: "Customs Declaration",
        desc: "Preparing the customs declaration, booking the inspection slot, and following official channels.",
      },
      {
        title: "Inspection & Release",
        desc: "Escorting inspection and survey, paying duties, and obtaining the official release permit.",
      },
      {
        title: "Transport & Delivery",
        desc: "Securing land transport from the port to the warehouse with direct shipment tracking.",
      },
      {
        title: "Closure & Reporting",
        desc: "Delivering the final release documents and a comprehensive shipment-escort report.",
      },
    ],
    highlights: [
      { value: "3–5", label: "Working days — average release time" },
      { value: "Sea", label: "& land — multimodal freight" },
      { value: "All", label: "Yemeni ports and crossings covered" },
      { value: "100%", label: "Legal compliance & official documentation" },
    ],
    facts: [
      { label: "Gateways covered", value: "Hodeidah, Aden, and land crossings" },
      { label: "Cargo types", value: "Containers, general cargo, heavy equipment" },
      { label: "Required documents", value: "B/L, invoice, origin, packing list" },
      { label: "Tracking", value: "Live tracking with periodic client reports" },
    ],
    faqs: [
      {
        q: "What documents are required to start customs clearance procedures?",
        a: "The Bill of Lading, the original commercial invoice, the certificate of origin, and the Packing List.",
      },
      {
        q: "How long does customs release usually take at the port?",
        a: "Once the documents are complete, customs procedures, inspection, and survey typically take 3 to 5 working days until release.",
      },
      {
        q: "Do you cover land crossings in addition to seaports?",
        a: "Yes, we complete customs release procedures at all seaports and land crossings with certified teams at each location.",
      },
      {
        q: "Do you provide inland transport from the port to governorates?",
        a: "Yes, we operate a well-equipped land fleet (trailers and flatbeds) that moves containers and heavy equipment to every governorate.",
      },
    ],
  },

  supplies: {
    slug: "supplies",
    title: "General Supplies & Equipment",
    shortTitle: "General Supplies",
    subtitle:
      "Import and supply of construction materials, cables, heavy equipment, and genuine spare parts.",
    seoTitle: "General Supplies, Equipment & Spare Parts in Yemen | Al-Fada Al-Wasaa",
    seoDescription:
      "Al-Fada Al-Wasaa for general supplies and equipment in Yemen: importing and supplying construction materials, cables, heavy equipment, and genuine spare parts. Call: +967776999942",
    keywords: [
      "general supplies Yemen",
      "construction materials supply Sana'a",
      "cables supply Yemen",
      "heavy equipment Yemen",
      "genuine spare parts Sana'a",
      "import and supply Yemen",
      "field logistics supplies Yemen",
    ],
    image: "/profile/track_forklift.webp",
    galleryImages: [
      "/profile/track_forklift.webp",
      "/profile/track_truck.webp",
      "/profile/container_truck.webp",
      "/profile/oil_tanks_truck.webp",
    ],
    overview: [
      "Reliable supply is a fundamental lifeline for keeping projects running; Al-Fada Al-Wasaa therefore provides general supply and equipment services: importing and supplying construction materials, cables, heavy equipment, and genuine spare parts from approved sources.",
      "We manage the entire supply cycle — from international procurement and customs through to delivery at the project site — with rigorous quality inspection and conformity certificates for every shipment, and a response speed that prevents work stoppages.",
    ],
    features: [
      {
        title: "Construction Materials",
        desc: "Importing and supplying cement, steel, and essential materials in commercial volumes to specification.",
        icon: "BrickWall",
      },
      {
        title: "Cables & Electrical Supplies",
        desc: "Supplying copper cables, medium-voltage lines, and electrical accessories with conformity certificates.",
        icon: "Cable",
      },
      {
        title: "Heavy Equipment & Machinery",
        desc: "Supplying heavy equipment and engineering machinery with their attachments and operational testing.",
        icon: "Tractor",
      },
      {
        title: "Genuine Spare Parts",
        desc: "Providing genuine spare parts for equipment and vehicles from certified dealers with verified sourcing.",
        icon: "Cog",
      },
      {
        title: "Fuels & Operational Oils",
        desc: "Supplying fuels and industrial oils to sites and generators via safety-certified tankers.",
        icon: "Fuel",
      },
      {
        title: "Field & Logistics Provisioning",
        desc: "Equipping sites with operational and field requirements quickly and with high reliability.",
        icon: "Package",
      },
    ],
    advantages: [
      "A network of approved external and local suppliers guaranteeing product authenticity and conformity certificates.",
      "Full management of the import and customs cycle in-house through the shipping sector.",
      "Quality inspection upon receipt and detailed reports documenting every shipment.",
      "Competitive pricing for commercial volumes and periodic supply contracts.",
      "High-speed response to urgent site supply requests.",
      "Technical expertise that helps clients specify the correct requirements for every item.",
    ],
    process: [
      {
        title: "Requirements Intake",
        desc: "Auditing items, specifications, and quantities while setting time priorities.",
      },
      {
        title: "Sourcing & Pricing",
        desc: "Requesting quotes from approved suppliers and presenting a transparent comparison to the client.",
      },
      {
        title: "Import & Clearance",
        desc: "Managing international procurement and customs procedures via the shipping and clearance sector.",
      },
      {
        title: "Inspection & Quality",
        desc: "Surveying shipments, verifying specifications, and documenting source certificates.",
      },
      {
        title: "On-Site Delivery",
        desc: "Transporting and delivering supplies at the project site with official acceptance minutes.",
      },
    ],
    highlights: [
      { value: "Genuine", label: "Spare parts with verified sourcing" },
      { value: "End-to-end", label: "Import, customs, and on-site delivery" },
      { value: "Inspected", label: "Quality check on every shipment" },
      { value: "Fast", label: "Response to urgent site requests" },
    ],
    facts: [
      { label: "Supply items", value: "Construction, cables, equipment, spares" },
      { label: "Sources", value: "Approved suppliers with conformity certificates" },
      { label: "Integration", value: "Customs & inland transport via shipping sector" },
      { label: "Documentation", value: "Inspection reports & official acceptance minutes" },
    ],
    faqs: [
      {
        q: "Do your services include importing materials from abroad?",
        a: "Yes, we manage the full import cycle from international procurement through customs release and delivery at the project site via our shipping and clearance sector.",
      },
      {
        q: "Do you guarantee the authenticity of supplied spare parts?",
        a: "Yes, we provide genuine spare parts from certified dealers with documented source certificates for every shipment.",
      },
      {
        q: "Can we contract for regular periodic supply to projects?",
        a: "Yes, we offer annual and monthly supply contracts that guarantee supply stability and priority provisioning under all circumstances.",
      },
      {
        q: "Do you supply heavy equipment as well as attachments?",
        a: "Both: we supply complete heavy equipment with operational testing, and separately provide attachments and spare parts as needed.",
      },
    ],
  },

  marketing: {
    slug: "marketing",
    title: "Real Estate Marketing & Investment",
    shortTitle: "Real Estate Marketing",
    subtitle:
      "Feasibility studies, land and compound marketing, development, and real estate asset management.",
    seoTitle: "Real Estate Marketing & Investment Opportunities in Sana'a | Al-Fada Al-Wasaa",
    seoDescription:
      "Real estate marketing and investment services in Yemen: feasibility studies, land and compound marketing, property development, and real estate asset management. Call: +967776999942",
    keywords: [
      "real estate marketing Sana'a",
      "investment opportunities Yemen",
      "real estate feasibility studies Yemen",
      "land for sale Sana'a",
      "compound marketing Yemen",
      "real estate asset management Yemen",
      "property development Sana'a",
    ],
    image: "/profile/site_hadramout_building.webp",
    galleryImages: [
      "/profile/site_hadramout_building.webp",
      "/profile/construction_building.webp",
      "/profile/site_mountain_station.webp",
    ],
    overview: [
      "The Real Estate Marketing & Investment division at Al-Fada Al-Wasaa delivers an integrated system that connects landowners and developers with serious investors and buyers, backed by precise economic feasibility studies and deep knowledge of the Yemeni property market.",
      "We work across the full life cycle of the asset: feasibility study, marketing of land, plots, and compounds, supervising development, then managing the real estate assets to preserve and grow their market value over the long term.",
    ],
    features: [
      {
        title: "Economic Feasibility Studies",
        desc: "Comprehensive real estate and investment feasibility studies: market analysis, costs, returns, and break-even points.",
        icon: "TrendingUp",
      },
      {
        title: "Land & Plot Marketing",
        desc: "Marketing land and residential/commercial plots to a network of serious clients through field and digital campaigns.",
        icon: "MapPinned",
      },
      {
        title: "Compounds & Units Marketing",
        desc: "Launching and marketing residential and commercial compounds and ready units with professional sales plans.",
        icon: "Building",
      },
      {
        title: "Development & Supervision",
        desc: "Managing development projects from concept to handover in integration with the company's contracting sector.",
        icon: "DraftingCompass",
      },
      {
        title: "Real Estate Asset Management",
        desc: "Managing and maintaining real estate assets, leasing, and preserving and growing their market value.",
        icon: "Briefcase",
      },
      {
        title: "Investment Advisory",
        desc: "Guiding investors to suitable opportunities, assessing risks, and structuring real estate partnerships.",
        icon: "Handshake",
      },
    ],
    advantages: [
      "Deep knowledge of the property market in Sana'a and the key governorates, with real price references.",
      "Unique integration with the company's contracting and excavation sectors for technical asset assessment.",
      "A network of serious investors and buyers built on years of institutional work.",
      "Realistic feasibility studies grounded in actual market figures, not theoretical estimates.",
      "Full transparency on commissions and agreements from the first meeting.",
      "Legal follow-up of sale and partnership procedures with specialized counsel.",
    ],
    process: [
      {
        title: "Asset Valuation",
        desc: "Field and technical inspection of the asset benchmarked against actual market prices.",
      },
      {
        title: "Feasibility Study",
        desc: "Analyzing the target market, costs, returns, and the best alternative uses.",
      },
      {
        title: "Marketing Plan",
        desc: "Defining the client segment, pricing, channels, and the campaign schedule.",
      },
      {
        title: "Launch & Follow-up",
        desc: "Executing field and digital campaigns with engagement reports and organized negotiations.",
      },
      {
        title: "Closing & Management",
        desc: "Finalizing contracts under legal supervision, then managing the asset or post-sale follow-up.",
      },
    ],
    highlights: [
      { value: "Feasibility", label: "Studies built on real market figures" },
      { value: "Field", label: "& digital campaigns for asset marketing" },
      { value: "Integrated", label: "Technical valuation via contracting sector" },
      { value: "Legal", label: "Full follow-up of contracting procedures" },
    ],
    facts: [
      { label: "Asset types", value: "Land, plots, compounds, and units" },
      { label: "Markets", value: "Sana'a and the key governorates" },
      { label: "Integration", value: "Construction valuation via contracting sector" },
      { label: "Transparency", value: "Clear commissions and agreements from day one" },
    ],
    faqs: [
      {
        q: "Do your services include feasibility studies for land and plot projects?",
        a: "Yes, we deliver comprehensive real estate and investment feasibility studies covering market analysis, costs, returns, and the best alternative uses of the asset.",
      },
      {
        q: "How do you market land and residential compounds?",
        a: "We build a tailored marketing plan combining field and digital campaigns with our network of serious clients, backed by periodic engagement reports throughout the campaign.",
      },
      {
        q: "Do you provide real estate asset management after sale?",
        a: "Yes, we offer asset management, maintenance, and leasing to preserve market value through clear annual management contracts.",
      },
      {
        q: "What makes your property valuation different?",
        a: "Our integration with the contracting and excavation sectors allows us to assess the asset technically and structurally — not just commercially — producing more accurate and realistic estimates.",
      },
    ],
  },
};
