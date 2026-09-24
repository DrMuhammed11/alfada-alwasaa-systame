/**
 * English Blog Data — direct professional translation of blog-data.ts
 * Same interface shape, same slugs, same images and dates. Single source of
 * truth for the English blog index (/en/blog) and article pages (/en/blog/[slug]).
 */

export interface EnBlogPost {
  slug: string;
  title: string;
  description: string;
  category: string;
  date: string;
  readTime: string;
  author: string;
  image: string;
  keywords: string[];
  content: {
    intro: string;
    sections: {
      heading: string;
      paragraphs: string[];
    }[];
    conclusion: string;
  };
}

export const EN_BLOG_POSTS: Record<string, EnBlogPost> = {
  "guide-choosing-contractor-yemen-2026": {
    slug: "guide-choosing-contractor-yemen-2026",
    title: "How to Choose the Best Contracting Company in Sana'a and Yemen? 7 Decisive Engineering Criteria",
    description: "A comprehensive guide to selecting a certified building contractor in Yemen. Criteria for examining past projects, execution contracts, quality control, and avoiding unaccounted construction costs in Sana'a.",
    category: "General Contracting",
    date: "2026-09-15",
    readTime: "6 min read",
    author: "Engineering Management — Al-Fada Al-Wasaa",
    image: "/profile/construction_building.webp",
    keywords: [
      "choosing a contracting company Sana'a",
      "building contractor Yemen",
      "construction cost in Sana'a",
      "contracting contracts Yemen",
      "contracting engineer Sana'a"
    ],
    content: {
      intro: "Building a commercial or residential facility is a massive financial investment that requires choosing the right execution partner. In the Yemeni market, companies and contractors vary widely in levels of institutional discipline and field expertise. This guide summarizes 7 essential engineering criteria you should verify before signing any construction contract.",
      sections: [
        {
          heading: "1. Examining Existing Field Track Record",
          paragraphs: [
            "Do not rely on photos or promotional profiles; request an on-site visit to projects the company has actually delivered or sites currently under construction.",
            "A field inspection lets you assess reinforced concrete quality, column alignment, finishing precision, and the level of cleanliness and occupational safety on site."
          ]
        },
        {
          heading: "2. Availability of Specialized Engineering & Supervision Staff",
          paragraphs: [
            "The fundamental difference between an experienced contracting company and an individual contractor lies in a permanent engineering supervision apparatus that monitors foundation rebar stages, concrete mix ratios, and pressure and soil tests.",
            "At Al-Fada Al-Wasaa, every project is accompanied by a certified site engineer to guarantee full conformity with the approved structural and architectural drawings."
          ]
        },
        {
          heading: "3. Owning Heavy Equipment & Machinery",
          paragraphs: [
            "A company relying on its own equipment (excavators, rollers, mixers, transport trucks) saves 20% to 30% of the time wasted waiting to rent equipment from the external market.",
            "This also directly reflects on stable contract pricing and consistent cost for the client without surprises."
          ]
        },
        {
          heading: "4. Clarity and Detail of the Bill of Quantities (BOQ)",
          paragraphs: [
            "Avoid vague contracts or lump-sum pricing without a detailed bill of quantities specifying cement grades, rebar, mix ratios, insulation types, and finishing materials.",
            "Contractual clarity is the real guarantee for protecting both parties' rights and preventing future disputes during execution."
          ]
        },
        {
          heading: "5. Deep Knowledge of Sana'a's Soil and Terrain",
          paragraphs: [
            "Sana'a is characterized by varied soil layers, from expansive clay to harsh basalt rock strata, requiring special geotechnical expertise in foundation design and the right excavation methods without damaging neighboring buildings."
          ]
        }
      ],
      conclusion: "Choosing the right contractor means peace of mind and a building that lasts for decades. At Al-Fada Al-Wasaa, we place quality, safety, and full transparency at the top of our priorities across all our projects in Sana'a and Yemen."
    }
  },
  "telecom-infrastructure-solar-yemen": {
    slug: "telecom-infrastructure-solar-yemen",
    title: "The Role of Solar Power in Sustaining Telecom Towers and Networks in Yemen",
    description: "A technical study on the role of hybrid photovoltaic power stations in operating and maintaining mobile towers at mountainous and rugged sites across Yemen without interruption.",
    category: "Telecom Services",
    date: "2026-09-12",
    readTime: "5 min read",
    author: "Telecom & Technical Solutions Division",
    image: "/profile/telecom_tower_sky.webp",
    keywords: [
      "telecom towers Yemen",
      "solar power for telecom towers",
      "network maintenance Sana'a",
      "remote broadcast stations",
      "fiber optic networks Yemen"
    ],
    content: {
      intro: "Telecom operators in Yemen face complex challenges related to difficult mountainous site terrain and the high cost of hauling fuel to run conventional diesel generators. This is where hybrid solar power systems stand out as a sustainable and efficient engineering solution that guarantees round-the-clock broadcast and connectivity services.",
      sections: [
        {
          heading: "1. Operational Challenges of Mountain & Remote Sites",
          paragraphs: [
            "Most radio and cellular broadcast stations and towers sit atop high mountain peaks to secure the widest geographic coverage, making diesel delivery and generator maintenance extremely difficult and costly.",
            "Repeated power outages lead to signal loss affecting thousands of subscribers in nearby districts and villages."
          ]
        },
        {
          heading: "2. Hybrid Solutions: Integrating Solar Panels with Lithium Banks",
          paragraphs: [
            "Solar power stations designed specifically for telecom towers provide stable energy generation throughout Yemen's sunny daylight hours, charging advanced lithium battery banks with long service life.",
            "The diesel generator runs only limited hours as an emergency reserve, cutting fuel consumption by more than 75% and reducing emissions and routine maintenance costs."
          ]
        },
        {
          heading: "3. Al-Fada Al-Wasaa's Role in Telecom Infrastructure",
          paragraphs: [
            "Al-Fada Al-Wasaa has executed and rehabilitated dozens of solar power stations for telecom towers across the governorates of the Republic, with wind-resistant mounting structures designed for mountain peaks and ultra-protective grounding and lightning systems.",
            "Our specialized field teams also provide preventive and emergency maintenance services to ensure signal stability and network consistency."
          ]
        }
      ],
      conclusion: "The shift toward clean energy in the telecom sector is not merely an economic choice — it is an inevitable necessity to guarantee digital security and uninterrupted connectivity for all segments of Yemeni society."
    }
  },
  "yemen-customs-clearance-ports-guide-2026": {
    slug: "yemen-customs-clearance-ports-guide-2026",
    title: "Yemen Customs Clearance & Port Procedures Guide 2026: Speeding Up Release and Avoiding Penalties",
    description: "A practical guide for major importers and companies on customs clearance requirements at Yemeni ports and crossings, document auditing, and avoiding storage fees and container demurrage penalties.",
    category: "Logistics & Shipping",
    date: "2026-09-18",
    readTime: "7 min read",
    author: "Logistics & Customs Clearance Division — Al-Fada Al-Wasaa",
    image: "/profile/port_ship.webp",
    keywords: [
      "customs clearance Yemen",
      "Yemen port procedures 2026",
      "Hodeidah port clearance",
      "container shipping Sana'a",
      "Yemen supply chains"
    ],
    content: {
      intro: "Customs clearance is the vital link in supply chains for commercial companies and industrial facilities in Yemen. With complex regulatory procedures and varying requirements between land and sea crossings, precise knowledge of legal controls and advance coordination are the only guarantee against hefty delay penalties and protection of project investments.",
      sections: [
        {
          heading: "1. Preparing Commercial Documents and Advance Verification",
          paragraphs: [
            "The first step to prevent any setback is the meticulous audit of bills of lading, certified commercial invoices, original certificates of origin, and detailed packing lists.",
            "Even a minor error in tariff description or coordinated codes (HS Codes) can route a shipment into complex inspection tracks, holding up release for weeks."
          ]
        },
        {
          heading: "2. Strategies for Managing Storage and Demurrage Fees",
          paragraphs: [
            "Shipping lines and freight agencies impose escalating daily penalties once the free grace period granted for containers at ports and customs crossings is exceeded.",
            "Through advance digital follow-up and preparing forms before vessel arrival, container dwell time is cut by more than 60%, delivering direct financial savings to importers."
          ]
        },
        {
          heading: "3. Logistics Linkage: From the Port Quay to the Project Site",
          paragraphs: [
            "The mission does not end with issuing the customs release permit; it requires a ready land transport fleet for immediate loading to move goods and heavy equipment under full supervision, insurance, and live tracking until delivery at the client's warehouses and sites across the governorates."
          ]
        }
      ],
      conclusion: "Professionalism in customs clearance is not merely finishing paperwork — it is strategic risk management that guarantees goods flow without stoppages or financial waste."
    }
  },
  "mountain-road-construction-standards-yemen": {
    slug: "mountain-road-construction-standards-yemen",
    title: "Engineering Standards for Cutting and Asphalting Roads in Yemen's Mountainous and Rugged Terrain",
    description: "A specialized engineering study on rock excavation techniques, flood drainage design, surfacing and compaction layers, and slope reinforcement to protect mountain roads from washouts and rockfalls.",
    category: "General Contracting",
    date: "2026-09-20",
    readTime: "6 min read",
    author: "Engineering Management — Al-Fada Al-Wasaa",
    image: "/profile/road_roller.webp",
    keywords: [
      "mountain road construction Yemen",
      "road asphalting Sana'a",
      "flood culvert design",
      "infrastructure contracting Yemen",
      "soil compaction road code"
    ],
    content: {
      intro: "Yemen's geography is defined by towering mountain terrain and steep gradients that make road construction both a critically important and an extremely difficult development artery. Ensuring road sustainability in these harsh environments requires advanced engineering standards beyond conventional methods, capable of withstanding heavy rainy seasons and mountain washouts.",
      sections: [
        {
          heading: "1. Topographic Surveying and Choosing a Safe Alignment",
          paragraphs: [
            "Work begins with precise surveying studies to determine the most suitable engineering gradients for the alignment and to avoid geological faults and active rockslide zones.",
            "Using specialized heavy machinery for excavation and controlled rock blasting ensures opening paths without affecting the cohesion of surrounding mountain masses."
          ]
        },
        {
          heading: "2. Hydrology: Rainwater and Flood Drainage Networks",
          paragraphs: [
            "Rainwater and rushing floods are the number one enemy of mountain roads in Yemen. That is why designing and building box and pipe culverts, side drainage ditches, and stone retaining walls is the essential foundation for preventing road-layer erosion.",
            "Reinforcing slopes with steel mesh and shotcrete protects traffic from sudden rockfalls."
          ]
        },
        {
          heading: "3. Quality Control of Base Layers and Laboratory Compaction",
          paragraphs: [
            "Every sector undergoes strict laboratory tests for compaction density (Proctor Test) and California Bearing Ratio (CBR) for sub-base and gravel base layers before hot asphalt is laid at thicknesses and standards that guarantee resistance to the axial loads of heavy trucks."
          ]
        }
      ],
      conclusion: "Mountain road construction is an investment in communities' lives and development, and the quality of engineering execution is the real deciding factor between a road that lasts for decades and one that collapses with the first rainy season."
    }
  }
};
