/**
 * English Blog Data — professional translation of blog-data.ts
 * Wording adopted verbatim from the approved final bilingual review
 * (6_CONTENT_REVIEW_AR_EN_10-10_FINAL_MASTER).
 * Same interface shape, same slugs, same images, dates, and keywords.
 * Single source of truth for the English blog index (/en/blog) and
 * article pages (/en/blog/[slug]).
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
    title: "How to Choose the Right Contracting Company in Sana'a, Yemen: 7 Essential Engineering Criteria",
    description:
      "A comprehensive guide to selecting a qualified building contractor in Yemen, covering past-project verification, execution contracts, quality control, and ways to avoid unforeseen construction costs in Sana'a.",
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
      intro:
        "Building a commercial or residential facility is a major financial investment that requires the right project partner. In the Yemeni market, companies and contractors vary widely in their levels of organizational discipline and field experience. This guide presents seven essential engineering criteria to verify before signing a construction contract.",
      sections: [
        {
          heading: "1. Reviewing the Company's Project Track Record",
          paragraphs: [
            "Do not rely solely on photographs or promotional profiles; request an on-site visit to projects the company has completed or sites that are currently under construction.",
            "A field inspection allows you to assess the quality of reinforced concrete, column alignment, finishing work, site cleanliness, and occupational health and safety."
          ]
        },
        {
          heading: "2. Availability of Specialized Engineering & Supervision Staff",
          paragraphs: [
            "A key difference between an experienced contracting company and an individual contractor is the presence of dedicated engineering supervision that monitors foundation reinforcement, concrete mix ratios, and soil and concrete compressive-strength testing.",
            "At Al-Fada Al-Wasaa, every project is supported by a certified site engineer to ensure full compliance with approved structural and architectural drawings."
          ]
        },
        {
          heading: "3. Company-Owned Heavy Equipment & Machinery",
          paragraphs: [
            "Using company-owned equipment (excavators, rollers, mixers, and transport trucks) can reduce the time spent waiting to rent machinery from external suppliers by 20% to 30%.",
            "This also supports more stable contract pricing and greater cost predictability for clients."
          ]
        },
        {
          heading: "4. Clarity and Detail of the Bill of Quantities (BOQ)",
          paragraphs: [
            "Avoid vague contracts or lump-sum pricing without a detailed Bill of Quantities specifying cement grades, reinforcement steel, mix ratios, insulation types, and finishing materials.",
            "Clear contractual terms help protect both parties' rights and reduce the risk of disputes during project execution."
          ]
        },
        {
          heading: "5. Deep Knowledge of Sana'a's Soil and Terrain",
          paragraphs: [
            "Sana'a has varied soil conditions, ranging from expansive clay to hard basaltic rock strata, requiring appropriate geotechnical expertise in foundation design and excavation methods that protect adjacent buildings."
          ]
        }
      ],
      conclusion:
        "Choosing the right contractor supports reliable project delivery and long-term building performance. At Al-Fada Al-Wasaa, quality, safety, and transparency remain central priorities across our projects in Sana'a and throughout Yemen."
    }
  },
  "telecom-infrastructure-solar-yemen": {
    slug: "telecom-infrastructure-solar-yemen",
    title: "The Role of Solar Power in Supporting Telecom Towers and Networks in Yemen",
    description:
      "A technical study on the role of hybrid photovoltaic power systems in the operation and maintenance of mobile towers at mountainous and rugged sites across Yemen, supporting reliable and uninterrupted service.",
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
      intro:
        "Telecom operators in Yemen face complex challenges arising from difficult mountainous terrain and the high cost of transporting fuel for conventional diesel generators. Hybrid solar power systems offer a sustainable and efficient engineering solution that supports continuous connectivity and reliable network service.",
      sections: [
        {
          heading: "1. Operational Challenges at Mountainous & Remote Sites",
          paragraphs: [
            "Many radio and cellular stations and towers are located on high mountain peaks to maximize geographic coverage, making diesel delivery and generator maintenance difficult and costly.",
            "Frequent power outages can lead to signal loss and affect subscribers in nearby districts and villages."
          ]
        },
        {
          heading: "2. Hybrid Solutions: Integrating Solar Panels with Lithium Battery Banks",
          paragraphs: [
            "Solar power systems designed specifically for telecom towers provide stable energy generation during daylight hours while charging advanced lithium battery banks with long service lives.",
            "The diesel generator operates only for limited periods as an emergency backup, reducing fuel consumption by more than 75% while also lowering emissions and routine maintenance costs."
          ]
        },
        {
          heading: "3. Al-Fada Al-Wasaa's Role in Telecom Infrastructure",
          paragraphs: [
            "Al-Fada Al-Wasaa has executed and rehabilitated dozens of solar power stations for telecom towers across Yemen, including wind-resistant mounting structures designed for mountain peaks and enhanced grounding and lightning-protection systems.",
            "Our specialized field teams also provide preventive and emergency maintenance to help maintain signal stability and network reliability."
          ]
        }
      ],
      conclusion:
        "The shift toward cleaner energy in the telecommunications sector is not merely an economic consideration; it is an essential step toward supporting digital security and reliable, continuous connectivity across Yemeni communities."
    }
  },
  "yemen-customs-clearance-ports-guide-2026": {
    slug: "yemen-customs-clearance-ports-guide-2026",
    title: "Yemen Customs Clearance & Port Procedures Guide 2026: How to Speed Up Customs Release and Avoid Penalties",
    description:
      "A practical guide for major importers and companies covering customs-clearance requirements at Yemeni ports and crossings, document verification, and ways to avoid storage charges and container demurrage charges.",
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
      intro:
        "Customs clearance is a vital link in the supply chains of trading companies and industrial facilities in Yemen. With complex procedures and varying requirements across land and sea crossings, accurate knowledge of applicable regulations and advance coordination can help reduce delays, penalties, and disruptions to project investments.",
      sections: [
        {
          heading: "1. Preparing Commercial Documents and Advance Compliance Verification",
          paragraphs: [
            "The first step in preventing delays is a careful review of bills of lading, certified commercial invoices, original certificates of origin, and detailed packing lists.",
            "Even a minor error in a customs description or HS code can subject a shipment to more complex inspection procedures and delay its release for weeks."
          ]
        },
        {
          heading: "2. Strategies for Managing Storage and Demurrage Charges",
          paragraphs: [
            "Shipping lines and freight agencies may impose escalating daily charges once the free period for containers at ports or customs facilities is exceeded.",
            "Through proactive digital tracking and document preparation before vessel arrival, container dwell time can be reduced by more than 60%, helping importers achieve direct cost savings."
          ]
        },
        {
          heading: "3. Logistics Linkage: From Port to Project Site",
          paragraphs: [
            "The process does not end with customs release; it also requires a ready land-transport fleet for the immediate loading and transport of goods and heavy equipment, with appropriate supervision, insurance coverage, and live tracking through delivery to the client's warehouses and sites."
          ]
        }
      ],
      conclusion:
        "Professional customs clearance is more than completing paperwork; it is a form of strategic risk management that helps keep goods moving without interruption while reducing avoidable delays and financial losses."
    }
  },
  "mountain-road-construction-standards-yemen": {
    slug: "mountain-road-construction-standards-yemen",
    title: "Engineering Standards for Road Construction and Asphalt Paving in Yemen's Mountainous and Rugged Terrain",
    description:
      "A specialized engineering study covering rock excavation techniques, stormwater and flood-drainage design, pavement and compaction layers, and slope reinforcement to protect mountain roads from washouts and rockfalls.",
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
      intro:
        "Yemen's geography includes steep mountainous terrain that makes road construction both essential and highly challenging. Long-term road performance in these environments requires advanced engineering practices that go beyond conventional methods and address heavy rainfall, runoff, and mountain washouts.",
      sections: [
        {
          heading: "1. Topographic Surveying and Choosing a Safe Alignment",
          paragraphs: [
            "The work begins with detailed topographic surveys to determine appropriate grades for the road alignment and to avoid geological faults and active rockslide zones.",
            "Specialized excavation equipment and controlled rock blasting help open road corridors while minimizing disturbance to surrounding rock formations."
          ]
        },
        {
          heading: "2. Hydrology: Stormwater and Flood Drainage Systems",
          paragraphs: [
            "Rainfall and flash floods are major threats to mountain roads in Yemen. Designing and constructing box and pipe culverts, side drainage ditches, and stone retaining walls is therefore essential to protecting road layers from erosion.",
            "Reinforcing slopes with steel mesh and shotcrete helps protect road users from sudden rockfalls."
          ]
        },
        {
          heading: "3. Quality Control of Base Layers and Laboratory Compaction Testing",
          paragraphs: [
            "Each road section undergoes strict laboratory testing of compaction density (Proctor Test) and California Bearing Ratio (CBR) for sub-base and gravel base layers before hot-mix asphalt is laid at specified thicknesses in accordance with applicable standards, providing the required bearing capacity to withstand heavy truck axle loads."
          ]
        }
      ],
      conclusion:
        "Mountain road construction is an investment in community development and long-term connectivity. The quality of engineering execution is critical to determining whether a road delivers reliable performance over decades or deteriorates after a severe rainy season."
    }
  }
};
