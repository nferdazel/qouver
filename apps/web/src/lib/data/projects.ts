export interface CaseStudyDecision {
  heading: string;
  explanation: string;
}

// A record only carries a diagram when the architecture paragraph names the
// request path; drawing one from a stack list would invent the protocols
// between the blocks.
export interface CaseDiagram {
  title: string;
  description: string;
  blocks: Array<{ label: string; value: string; note: string; accent?: boolean }>;
  connectors: string[];
  footer?: string;
  caption: string;
}

export interface CaseStudy {
  title: string;
  overview: string;
  problem: string;
  architecture: string;
  decisions: CaseStudyDecision[];
  takeaways: string;
  diagram?: CaseDiagram;
}

export type ProjectStatus = 'Live' | 'Backend' | 'Archived';

export interface Project {
  index: string;
  slug: string;
  name: string;
  category: string;
  tagline: string;
  description: string;
  focus: string[];
  status: ProjectStatus;
  stack: string;
  stackItems: string[];
  url?: string;
  urlLabel?: string;
  caseStudy?: CaseStudy;
}

// Operating records first, archived records last. `index` is rendered as the
// "No." column and in the case-study header, so it is renumbered with the order.
export const projects: Project[] = [
  {
    index: '01',
    slug: 'majadu',
    name: 'Majadu Tools',
    category: 'Community systems',
    tagline: 'Systems that keep a community running.',
    description:
      'The backend that keeps a badminton community running: court scheduling, live scoring, tournaments, and a points board that rewards showing up. Qouver builds and operates the Nim API behind it, in production today.',
    focus: ['Scheduling', 'Live scoring', 'Ratings', 'Community growth'],
    status: 'Backend',
    stack: 'Nim · Postgres · OpenAPI',
    stackItems: ['Nim', 'Postgres', 'OpenAPI'],
    url: 'https://api.qouver.com/majadu',
    urlLabel: 'API',
    caseStudy: {
      title: 'Rolling Points Board & Contract-First Nim API',
      overview:
        'Majadu powers local sports session operations: balanced doubles matchups, live court scoring, tournament brackets, and a rolling points board.',
      problem:
        'Casual sports sessions suffer from subjective player seeding, manual paper scorekeeping, and network drops during live matches in sports halls with weak cellular coverage.',
      architecture:
        'A Nim 2.4 API served by Mummy over HTTP and WebSocket, backed by PostgreSQL 18 and 61 migrations. One database holds every community, and row-level security guards every community-owned table. This record covers the API and the data behind it.',
      decisions: [
        {
          heading: 'Contract-first Nim API',
          explanation:
            'Routes are generated from the 76-operation OpenAPI definition and run on Mummy over HTTP and WebSocket with db_connector. Clients compile from the same contract, so there is no framework layer to hand-maintain.',
        },
        {
          heading: 'Rolling points, not an absolute rating',
          explanation:
            'Standings come from the best 10 entries in a rolling 12-week window. A game is weighted by its margin and by an opponent tier multiplier clamped between 0.5 and 1.5. Glicko was retired with the v1 API.',
        },
        {
          heading: 'Tenancy enforced in the database',
          explanation:
            'Every community-owned row carries community_id, and row-level security fails closed when the tenant setting is missing. There is no schema per community to keep in sync.',
        },
      ],
      takeaways:
        'A contract-first Nim service and tenancy the database enforces keep one API serving many communities without a framework layer or a schema per club.',
      diagram: {
        title: 'Majadu request path',
        description:
          'A client sends a request to the Nim API over HTTPS; the API reads and writes PostgreSQL 18 over SQL, and every community-owned row is scoped by community_id and row-level security.',
        blocks: [
          { label: 'Client', value: 'Club app', note: 'Outside this record' },
          { label: 'API / Nim 2.4', value: 'Mummy + db_connector', note: 'Routes from the contract', accent: true },
          { label: 'Database', value: 'PostgreSQL 18', note: 'community_id + RLS' },
        ],
        connectors: ['HTTPS', 'SQL'],
        footer: 'Runs in rootless Podman',
        caption:
          'The request path as the record describes it: a club app to the Nim API over HTTPS, the API to PostgreSQL over SQL, with community_id and row-level security.',
      },
    },
  },
  {
    index: '02',
    slug: 'sds',
    name: 'SDS Management',
    category: 'Compliance',
    tagline: 'Chemical safety data management.',
    description:
      'A compliance tool that keeps chemical safety data sheets current and auditable: a searchable register, hazard pictograms, and clean PDF exports. In production for a real workplace.',
    focus: ['Compliance', 'Documentation', 'Workflow'],
    status: 'Live',
    stack: 'Vue · Go · Postgres',
    stackItems: ['Vue', 'Go', 'Postgres'],
    url: 'https://sds.qouver.com',
    urlLabel: 'VISIT',
    caseStudy: {
      title: 'Audit-Ready Safety Records & Server PDF Pipeline',
      overview:
        'Workplace compliance management system for chemical Safety Data Sheets (SDS/MSDS): a searchable chemical register, a pictogram matrix, and an automated PDF export pipeline.',
      problem:
        'Industrial chemical compliance demands exact GHS hazard pictogram mapping, a dated record of every edit, and immediate PDF availability for workplace safety audits.',
      architecture:
        'A Vue 3 + TypeScript single-page application on a Go REST API and PostgreSQL, with headless Chromium rendering PDFs inside the API container and a cache keyed by template hash.',
      decisions: [
        {
          heading: 'Headless Chromium PDF export',
          explanation:
            'Chromium renders safety sheets to PDF inside the API container, and the result is cached by template hash. One renderer serves every browser and device.',
        },
        {
          heading: 'One record per chemical per year',
          explanation:
            'A unique key on chemical and year keeps one record per chemical. Edits update it in place, and every create, update, delete and copy-year is written to the activity log with the old and new values.',
        },
        {
          heading: 'GHS pictogram matrix',
          explanation:
            'Hazards map to pictograms stored as images (PNG, JPEG, GIF, WebP), composited server-side and embedded in the PDF as data URIs for instant visual identification.',
        },
      ],
      takeaways:
        'One stored record and one renderer keep the sheet identical on every device, and the activity log keeps the history an audit asks for.',
    },
  },
  {
    index: '03',
    slug: 'skyward',
    name: 'Skyward',
    category: 'Simulation',
    tagline: 'Airline tycoon simulation.',
    description:
      "Run your own airline: build a fleet, open routes, and grow an economy that keeps moving while you're away. The whole world runs on a server-side simulation engine, so your device just plays it and everything stays fair and consistent.",
    focus: ['Simulation', 'Strategy', 'Systems design'],
    status: 'Archived',
    stack: 'Flutter · Go · Postgres',
    stackItems: ['Flutter', 'Go', 'Postgres'],
    caseStudy: {
      title: 'Server-Side Tick Simulation Engine & Authoritative State',
      overview:
        'Skyward is an airline management game where global economy, route calculations, fuel burn, and passenger demand ran continuously on a backend tick worker in Go.',
      problem:
        'Client-side calculated simulations suffer from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop clients.',
      architecture:
        'An authoritative Go 1.22+ backend executes a scheduled world tick loop, persisting state in PostgreSQL 18. The Flutter client (Web & Desktop) acts as a pure, reactive viewer rendering streamed server snapshots.',
      decisions: [
        {
          heading: 'Zero client simulation logic',
          explanation:
            'The Flutter client contains no financial or flight trajectory formulas. All flight paths, fuel consumption, and market yields are calculated strictly on the backend.',
        },
        {
          heading: 'Deterministic world tick loop',
          explanation:
            'World ticks execute at fixed server intervals. When a player logs in after days away, the backend processes past tick windows deterministically without melting client memory.',
        },
        {
          heading: 'ACID transaction isolation',
          explanation:
            'All airline financial operations use strict PostgreSQL database transactions to prevent double-spending or route duplication under concurrent player actions.',
        },
      ],
      takeaways:
        'Moving simulation authority entirely to backend workers removed the client as a cheat vector and kept Web and Desktop clients in sync.',
    },
  },
  {
    index: '04',
    slug: 'mdef',
    name: 'M-DEF',
    category: 'Analytics',
    tagline: 'Badminton analytics platform.',
    description:
      'A leaderboard and analytics platform built for a real badminton community, powered by a custom rating engine that weighed how convincingly you won and kept ratings honest when players went quiet. It ran in production with live rankings and seasonal standings; its ideas now live on inside Majadu.',
    focus: ['Ranking systems', 'Statistics', 'Community insights'],
    status: 'Archived',
    stack: 'Flutter · Supabase / Postgres',
    stackItems: ['Flutter', 'Supabase', 'Postgres'],
    caseStudy: {
      title: 'Lessons from an Early Badminton Analytics Engine',
      overview:
        'An early leaderboard and analytics platform built for recreational badminton leagues, providing dynamic player ratings and match statistics before being superseded by Majadu.',
      problem:
        'Tracking player standings across unstructured recreational matches required a dynamic ranking model before backend APIs were unified.',
      architecture:
        'Flutter frontend client paired with Supabase / PostgreSQL backend, featuring a custom rating algorithm weighing win margins and inactivity decay.',
      decisions: [
        {
          heading: 'Inactivity decay penalty',
          explanation:
            'Rankings automatically decayed when players stopped competing, preventing inactive players from occupying top leaderboard positions indefinitely.',
        },
        {
          heading: 'Retirement & algorithm migration',
          explanation:
            "When Majadu was established, M-DEF was retired. Its rating ideas informed Majadu's first API; the current Majadu points model replaced them.",
        },
      ],
      takeaways:
        'Retiring early standalone experiments in favor of unified backend APIs keeps system maintenance low while preserving core algorithm IP.',
    },
  },
];
