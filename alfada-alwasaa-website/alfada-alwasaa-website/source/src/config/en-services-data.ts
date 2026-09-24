/**
 * English counterpart of `services-data.ts`.
 *
 * Contains the English translation of the seven service pages for
 * Al-Fada Al-Wasaa (Telecommunications, Contracting & Supplies — Sana'a, Yemen).
 * - `slug`, `image`, and `galleryImages` are kept EXACTLY identical to the
 *   Arabic file so both locales resolve the same assets and routes.
 * - All textual content is professionally translated corporate English.
 * - Phone numbers are preserved as-is.
 */

export interface ServiceDetail {
  slug: string;
  title: string;
  shortTitle: string;
  subtitle: string;
  seoTitle: string;
  seoDescription: string;
  keywords: string[];
  image: string;
  galleryImages: string[];
  overview: string[];
  features: { title: string; desc: string }[];
  advantages: string[];
  faqs: { q: string; a: string }[];
}

export const EN_SERVICES_DATA: Record<string, ServiceDetail> = {
  contracting: {
    slug: "contracting",
    title: "General Contracting and Engineering Construction",
    shortTitle: "General Contracting",
    subtitle: "Delivering construction, commercial, and residential projects across Sana'a and greater Yemen to the highest standards of quality and engineering discipline.",
    seoTitle: "General Contracting Company in Sana'a | Al-Fada Al-Wasaa Yemen",
    seoDescription: "Al-Fada Al-Wasaa — a leading general contracting and construction company in Sana'a and Yemen. Towers, residential and commercial buildings, concrete works, and finishing. Call us: +967776999942",
    keywords: [
      "contracting company Sana'a",
      "general contracting Yemen",
      "building contractor Sana'a",
      "construction companies Yemen",
      "residential building construction Sana'a",
      "concrete and finishing works Yemen",
      "Al-Fada Al-Wasaa contracting"
    ],
    image: "/profile/construction_building.webp",
    galleryImages: [
      "/profile/construction_building.webp",
      "/profile/site_hadramout_building.webp",
      "/profile/track_forklift.webp"
    ],
    overview: [
      "Al-Fada Al-Wasaa stands among the leading firms in the general contracting sector of the Republic of Yemen, combining seasoned hands-on field experience with the latest engineering methodologies in the management and execution of major projects.",
      "Across all of our projects in Sana'a and throughout the Yemeni governorates, we adhere strictly to international specifications and standards and to agreed delivery schedules, providing turnkey solutions that run from drawing studies all the way to final handover."
    ],
    features: [
      {
        title: "Residential and Commercial Construction",
        desc: "Execution of towers, residential blocks, commercial centers, and service facilities with true professionalism and precise structural planning."
      },
      {
        title: "Concrete Works and Steel Structures",
        desc: "Pouring of foundations, columns, and slabs, and erection of steel structures for warehouses and hangars using state-of-the-art equipment."
      },
      {
        title: "Integrated Architectural Finishing",
        desc: "Plastering, painting, thermal and waterproof insulation, and installation of glass facades and cladding."
      },
      {
        title: "Structural Restoration and Rehabilitation",
        desc: "Structural safety assessment, reinforcement of columns and slabs, and upgrading of older buildings in line with engineering safety codes."
      }
    ],
    advantages: [
      "A qualified engineering and supervision team with long field experience in the Yemeni market.",
      "A complete fleet of equipment and heavy machinery to guarantee speed of delivery.",
      "Strict commitment to approved budgets with no hidden costs or delays.",
      "A documented track record of successful works with major institutions and organizations across Yemen."
    ],
    faqs: [
      {
        q: "Which geographic areas do your contracting services cover?",
        a: "We deliver our services in the capital city of Sana'a and across all governorates of the Republic of Yemen, with the capacity to manage both established and remote field sites."
      },
      {
        q: "How are construction projects priced?",
        a: "Pricing is based on a detailed study of the bills of quantities and engineering drawings, supported by a competitive and transparent cost analysis tailored to the client's requirements."
      },
      {
        q: "Do you provide independent engineering supervision?",
        a: "Yes, we offer engineering supervision, quality control, and soil and concrete testing services carried out by certified engineers."
      }
    ]
  },
  roads: {
    slug: "roads",
    title: "Road and Bridge Construction and Maintenance",
    shortTitle: "Roads & Bridges",
    subtitle: "Developing infrastructure, paving and asphalting roads, and constructing bridges and culverts with efficiency and advanced heavy equipment across Yemen.",
    seoTitle: "Road and Bridge Construction and Maintenance in Yemen | Al-Fada Al-Wasaa",
    seoDescription: "Al-Fada Al-Wasaa executes road and bridge works across Yemen. Asphalting, stone paving, soil compaction, and maintenance of streets and vital corridors. Phone: +967776999942",
    keywords: [
      "road construction Yemen",
      "bridge maintenance Sana'a",
      "road asphalting Yemen",
      "stone paving Sana'a",
      "road and infrastructure contractors",
      "street paving Yemen"
    ],
    image: "/profile/road_roller.webp",
    galleryImages: [
      "/profile/road_roller.webp",
      "/profile/track_roller.webp",
      "/profile/track_truck.webp"
    ],
    overview: [
      "Road and bridge networks are the economic lifeline of Yemen; for this reason, Al-Fada Al-Wasaa places its expertise and mechanical capabilities at the service of constructing, developing, and maintaining vital corridors to the highest load-bearing and traffic safety specifications.",
      "We operate asphalt plants, modern rollers, milling machines, and asphalt pavers that ensure precise gradients, an even riding surface, and tolerance of the high axle loads imposed by cars and trucks."
    ],
    features: [
      {
        title: "Hot-Mix Asphalting and Paving",
        desc: "Laying asphalt courses to approved standard mixes engineered for Yemen's temperatures and climatic conditions."
      },
      {
        title: "Stone Paving and Slope Stabilization",
        desc: "Paving streets with natural stone and interlocking tiles, and building retaining walls to protect mountain roads."
      },
      {
        title: "Bridges and Flood Water Drainage",
        desc: "Constructing box and pipe culverts and surface bridges to protect roads against seasonal flood damage."
      },
      {
        title: "Maintenance and Rehabilitation",
        desc: "Treating cracks and potholes, milling deteriorated asphalt, and re-asphalting to restore the serviceability of aging roads."
      }
    ],
    advantages: [
      "High readiness to operate in mountainous and rugged terrain with complete efficiency.",
      "Regular laboratory testing of asphalt and bitumen samples as well as compaction density.",
      "Application of traffic safety specifications, directional signage, and lane markings.",
      "Rapid response for repairing damaged roads and reopening vital corridors."
    ],
    faqs: [
      {
        q: "Do you execute road projects in rugged or mountainous areas?",
        a: "Yes, we have extensive experience in overcoming Yemen's challenging terrain, opening alignments across slopes and stabilizing embankments with retaining walls."
      },
      {
        q: "What standards do you follow for soil compaction and asphalt testing?",
        a: "We rely on standard Proctor testing for soil density and Marshall testing for asphalt mixes, ensuring the road remains serviceable for many years."
      }
    ]
  },
  excavation: {
    slug: "excavation",
    title: "Excavation Works and Site Leveling",
    shortTitle: "Excavation Works",
    subtitle: "Preparing construction sites, breaking rock, backfilling, compacting, and hauling with the latest heavy machinery in Sana'a and across Yemen.",
    seoTitle: "Excavation and Site Leveling Services in Sana'a | Al-Fada Al-Wasaa",
    seoDescription: "Excavation, backfilling, and site preparation services in Sana'a and Yemen. Foundation excavation, rock breaking, land leveling, and debris hauling delivered efficiently and fast. Contact us now.",
    keywords: [
      "excavation works Sana'a",
      "site leveling Yemen",
      "rock breaking Sana'a",
      "foundation and basement excavation",
      "land backfilling and compaction Yemen",
      "excavator rental Sana'a"
    ],
    image: "/profile/site_mountain_station.webp",
    galleryImages: [
      "/profile/site_mountain_station.webp",
      "/profile/track_truck.webp",
      "/profile/road_roller.webp"
    ],
    overview: [
      "The foundation phase of any construction project is the bedrock of its success; accordingly, Al-Fada Al-Wasaa provides an integrated system of precise excavation, rock breaking, and topographic leveling for projects large and small.",
      "With excavators fitted with hydraulic breakers and high-capacity dump trucks, we strive to prepare sites efficiently and in the shortest possible timeframe while prioritizing the safety of neighboring structures."
    ],
    features: [
      {
        title: "Basement and Deep Foundation Excavation",
        desc: "Executing excavations for residential and commercial buildings, with shoring of excavation sides and protection of adjacent structures."
      },
      {
        title: "Hydraulic Rock Breaking",
        desc: "Fragmenting solid rock and the basalt layers common in Sana'a and mountainous regions without causing cracking in neighboring properties."
      },
      {
        title: "Backfilling and Engineering Compaction",
        desc: "Supplying selected backfill material (sub-base) and compacting in uniform layers while measuring moisture content and density."
      },
      {
        title: "Leveling and Preparing Development Land",
        desc: "Grading vast tracts of land for residential compounds, factories, and farms, including the opening of internal roadways."
      }
    ],
    advantages: [
      "A fleet of excavators in a range of sizes for work in both open and confined spaces.",
      "A professional operating crew and certified operators with full compliance with occupational safety standards.",
      "Rapid hauling of debris and soil to officially approved disposal sites.",
      "Competitive pricing based on the volume of works and contracting speed."
    ],
    faqs: [
      {
        q: "Do you provide excavation-side shoring services for neighboring buildings?",
        a: "Yes, we apply appropriate shoring and support techniques to guarantee the safety of neighboring properties and prevent any ground subsidence during deep excavation."
      },
      {
        q: "How do you handle extremely hard rocky ground?",
        a: "We deploy heavy excavators equipped with advanced hydraulic breaker attachments and specialized rock saws that ensure precision and speed of execution."
      }
    ]
  },
  supplies: {
    slug: "supplies",
    title: "Petroleum Services, Fuel Supply, and Equipment",
    shortTitle: "Petroleum Supplies",
    subtitle: "Providing fuels, petroleum products, logistics provisioning, and specialized equipment for field sites and critical projects.",
    seoTitle: "Petroleum Supplies and Fuel Services in Yemen | Al-Fada Al-Wasaa",
    seoDescription: "Al-Fada Al-Wasaa for petroleum services and fuel supplies in Yemen. Diesel and gasoline supply for factories and projects, plus certified tankers and field equipment.",
    keywords: [
      "petroleum supplies Yemen",
      "fuel services Sana'a",
      "diesel supply for projects",
      "petroleum tanker transport",
      "field logistics supplies Yemen",
      "oil equipment supply"
    ],
    image: "/profile/oil_tanks_truck.webp",
    galleryImages: [
      "/profile/oil_tanks_truck.webp",
      "/profile/oil_valve_flare.webp",
      "/profile/track_truck.webp"
    ],
    overview: [
      "Continuity of energy and petroleum product supply is a fundamental lifeline for operating factories and construction project sites in Yemen. Al-Fada Al-Wasaa provides dependable supply chains that comply with the highest safety specifications.",
      "We provide fuel transport tankers fitted with modern discharge systems, together with an uncompromising commitment to product quality and freedom from contaminants, ensuring generators and engines run at peak efficiency."
    ],
    features: [
      {
        title: "Fuel Supply to Sites and Projects",
        desc: "Delivering diesel and gasoline in commercial and industrial volumes to factories, hospitals, and field projects."
      },
      {
        title: "Tanker Rental and Operation",
        desc: "A tanker fleet with a range of capacities, fully compliant with safety codes for the transport of flammable materials."
      },
      {
        title: "Industrial Oils and Lubricants Supply",
        desc: "Supplying engine oils and heavy-equipment lubricants from the finest certified international brands."
      },
      {
        title: "Field Equipment for Oil Sites",
        desc: "Supplying temporary storage tanks, pumps, and high-pressure-rated distribution hoses."
      }
    ],
    advantages: [
      "Meticulous adherence to delivery schedules to prevent any halt of production lines and operations.",
      "Regular laboratory testing of the purity and density of the products supplied.",
      "Drivers trained in firefighting procedures and occupational health and safety.",
      "Geographic coverage that reaches the most demanding sites across every governorate of Yemen."
    ],
    faqs: [
      {
        q: "Can we contract for regular periodic supply to factories or companies?",
        a: "Yes, we offer convenient annual and monthly supply contracts that guarantee supply stability and priority delivery under all circumstances."
      },
      {
        q: "What safety requirements do you follow when transporting fuel?",
        a: "Our tankers are equipped with automatic fire-suppression systems, lightning and static-discharge protection, and tracking systems to monitor every shipment in transit."
      }
    ]
  },
  telecom: {
    slug: "telecom",
    title: "Telecommunications Services and Technical Solutions",
    shortTitle: "Telecommunications",
    subtitle: "Building and maintaining telecom towers, installing antennas, deploying fiber optic networks, and delivering solar power solutions for remote sites.",
    seoTitle: "Telecom Services and Tower Maintenance in Yemen | Al-Fada Al-Wasaa",
    seoDescription: "Al-Fada Al-Wasaa for telecommunications and network services in Yemen. Mobile tower installation and maintenance, fiber optics, and solar power stations for telecom sites.",
    keywords: [
      "telecom services Yemen",
      "telecom tower maintenance Sana'a",
      "mobile tower installation",
      "fiber optic networks Yemen",
      "solar power for telecom towers",
      "telecom and IT solutions Sana'a"
    ],
    image: "/profile/telecom_tower_sky.webp",
    galleryImages: [
      "/profile/telecom_tower_sky.webp",
      "/profile/telecom_antenna_city.webp",
      "/profile/site_solar_array.webp",
      "/profile/site_power_inverters.webp"
    ],
    overview: [
      "The Al-Fada Al-Wasaa team holds an exceptional track record in supporting and developing the telecommunications infrastructure of Yemen, working with the major telecom operators and internet service providers to extend and install their networks.",
      "We deliver end-to-end solutions covering tower civil works, steel structure erection, antenna maintenance, and hybrid solar power systems for mountain and remote sites, keeping transmissions running around the clock, 24/7."
    ],
    features: [
      {
        title: "Civil Works and Tower Erection",
        desc: "Excavating concrete foundations, erecting lattice and monopole towers, and installing earthing and grounding lines."
      },
      {
        title: "Antenna and Microwave Installation and Maintenance",
        desc: "Professional mounting and alignment of microwave and RF antennas to the highest standards."
      },
      {
        title: "Solar Power Systems and Diesel Generators",
        desc: "Designing and building photovoltaic power stations with lithium battery banks to run telecom towers without interruption."
      },
      {
        title: "Fiber Optic Network Deployment",
        desc: "Trenching and deploying aerial and underground fiber optic cables, and splicing fibers with advanced fusion splicers."
      }
    ],
    advantages: [
      "Rope-access climbing and maintenance teams trained and certified to the highest international safety standards.",
      "Deep experience operating within Yemen's complex geographic and climatic environment.",
      "The ability to carry out emergency maintenance and restore transmission in record time.",
      "Trusted strategic partnerships with the leading local telecommunications operators."
    ],
    faqs: [
      {
        q: "Do you build solar power stations for telecom towers?",
        a: "Yes, we have successfully delivered dozens of hybrid solar power stations for remote sites, a record fully documented in our project portfolio."
      },
      {
        q: "What preventive maintenance services do you offer for towers?",
        a: "They include bolt-torque inspection, corrosion protection checks, earthing and lightning system testing, and assessment of battery and generator performance."
      }
    ]
  },
  marketing: {
    slug: "marketing",
    title: "Digital Marketing and Digital Consulting",
    shortTitle: "Digital Marketing",
    subtitle: "Building a digital presence, managing corporate identity, running paid advertising campaigns, and boosting brand visibility across Yemen and the Gulf.",
    seoTitle: "Digital Marketing and Campaign Management Agency in Sana'a | Al-Fada Al-Wasaa",
    seoDescription: "Digital marketing and social media management services in Yemen. Brand identity building, paid ads on Facebook, Google, and Instagram, SEO, and creative content design.",
    keywords: [
      "digital marketing Sana'a",
      "marketing agency Yemen",
      "social media page management",
      "paid advertising Yemen",
      "brand identity design Sana'a",
      "digital marketing for companies Yemen"
    ],
    image: "/profile/marketing_laptop.webp",
    galleryImages: [
      "/profile/marketing_laptop.webp",
      "/profile/social_media.webp"
    ],
    overview: [
      "In an era of digital transformation, an excellent service alone is not enough without reaching the right audience. The digital marketing division at Al-Fada Al-Wasaa delivers integrated marketing growth strategies for companies and businesses of every size.",
      "We create creative content that speaks to the culture and aspirations of Yemeni and Arab audiences, combined with meticulous advertising campaign management to secure the highest possible return on investment (ROI)."
    ],
    features: [
      {
        title: "Social Media Management",
        desc: "Content creation, graphic design, marketing copywriting, and continuous engagement with your followers."
      },
      {
        title: "Paid Advertising Campaigns (Paid Ads)",
        desc: "Precision targeting across Meta platforms (Facebook & Instagram), Google Ads, and other social channels."
      },
      {
        title: "Search Engine Optimization (SEO)",
        desc: "Optimizing websites and online stores to rank on the first page of Google and attract customers without ongoing ad spend."
      },
      {
        title: "Visual Identity and Brand Building",
        desc: "Designing logos, company profiles, and promotional materials that reflect the standing and distinction of your organization."
      }
    ],
    advantages: [
      "A deep understanding of local consumer behavior in the Yemeni and Gulf markets.",
      "Regular, transparent performance reports detailing reach, engagement, and sales metrics.",
      "A creative team of designers, content writers, and certified advertising specialists.",
      "Flexible solutions that suit startups and large enterprises alike."
    ],
    faqs: [
      {
        q: "Can you manage paid campaigns targeting specific cities in Yemen?",
        a: "Yes, we fine-tune geographic and demographic targeting by city (Sana'a, Aden, Taiz, Hadhramaut, and more) and by the interests you specify."
      },
      {
        q: "How long does it take to build a complete corporate visual identity?",
        a: "It typically takes 10 to 15 working days, covering the concept study, mock-up design, and the complete brand identity usage guide."
      }
    ]
  },
  shipping: {
    slug: "shipping",
    title: "Logistics, Shipping, and Customs Clearance Services",
    shortTitle: "Shipping & Customs Clearance",
    subtitle: "Managing freight movement, land and sea shipping, and completing customs procedures with efficiency and full legal compliance at Yemeni ports of entry.",
    seoTitle: "Shipping and Customs Clearance Services in Yemen | Al-Fada Al-Wasaa",
    seoDescription: "Al-Fada Al-Wasaa for customs clearance and shipping in Yemen. Goods clearance via the ports of Hodeidah and Aden and land crossings. Safe, reliable transport and logistics distribution.",
    keywords: [
      "customs clearance Yemen",
      "shipping company Sana'a",
      "cargo clearance Aden and Hodeidah ports",
      "land and sea freight Yemen",
      "logistics and storage services Sana'a",
      "licensed customs broker Yemen"
    ],
    image: "/profile/container_truck.webp",
    galleryImages: [
      "/profile/container_truck.webp",
      "/profile/port_ship.webp",
      "/profile/track_ship.webp",
      "/profile/track_truck.webp"
    ],
    overview: [
      "Trade and shipping logistics are the backbone of development; Al-Fada Al-Wasaa therefore provides integrated import and customs clearance services that ensure your goods and equipment pass through every sea and land crossing in the shortest possible time.",
      "We bring wide-ranging relationships and a precise understanding of all customs regulations, tariffs, and exemption schemes, saving our clients time and effort as well as demurrage charges and late-payment penalties."
    ],
    features: [
      {
        title: "Customs Clearance at All Ports",
        desc: "Completing procedures at the seaports (Hodeidah, Aden) and land customs crossings with precision and full legal compliance."
      },
      {
        title: "Inland Transport and Distribution",
        desc: "A fleet of well-equipped trucks (trailers, flatbeds, and platform trucks) to haul containers and goods to your warehouses."
      },
      {
        title: "Permits and Conformity Certificates",
        desc: "Liaising with the standards and metrology authority, plant and agricultural quarantine, and obtaining every official release permit."
      },
      {
        title: "Storage and Field Logistics Solutions",
        desc: "Providing secured, fully equipped storage space for the sorting, loading, and unloading of goods and heavy equipment."
      }
    ],
    advantages: [
      "Licensed customs brokers with extensive command of ever-changing regulations and procedures.",
      "Comprehensive insurance and live tracking of your shipments until they reach their final destination.",
      "Reduced waiting times and avoidance of penalties and additional ground-rent fees.",
      "A high capacity to handle special cargo and oversized equipment."
    ],
    faqs: [
      {
        q: "What documents are required to start customs clearance procedures?",
        a: "The Bill of Lading, the original commercial invoice, the certificate of origin, and the Packing List."
      },
      {
        q: "How long does container clearance usually take at the port?",
        a: "Once the documents are complete, customs procedures, inspection, and survey typically take 3 to 5 working days until release."
      }
    ]
  }
};
