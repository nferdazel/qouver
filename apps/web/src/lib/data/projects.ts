export interface CaseStudyDecision {
  heading: string;
  explanation: string;
}

export interface CaseStudy {
  title: string;
  overview: string;
  problem: string;
  architecture: string;
  decisions: CaseStudyDecision[];
  takeaways: string;
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

export const projects: Project[] = [
  {
    index: '01',
    slug: 'skyward',
    name: 'Skyward',
    category: 'Simulation',
    tagline: 'Airline tycoon simulation.',
    description:
      "Run your own airline: build a fleet, open routes, and grow an economy that keeps moving while you're away. The whole world runs on a server-side simulation engine, so your device just plays it and everything stays fair and consistent. Live now at skyward.qouver.com.",
    focus: ['Simulation', 'Strategy', 'Systems design'],
    status: 'Live',
    stack: 'Flutter · Go · Postgres',
    stackItems: ['Flutter', 'Go', 'Postgres'],
    url: 'https://skyward.qouver.com',
    urlLabel: 'VISIT',
    caseStudy: {
      title: 'Server-Side Tick Simulation Engine & Authoritative State',
      overview:
        'Skyward is an airline management game where global economy, route calculations, fuel burn, and passenger demand operate continuously on a backend tick worker in Go.',
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
        'Moving simulation authority entirely to Go backend workers guarantees 100% fair play, zero client-side cheat vectors, and instant synchronization between Web and Desktop clients.',
    },
  },
  {
    index: '02',
    slug: 'majadu',
    name: 'Majadu Tools',
    category: 'Community systems',
    tagline: 'Systems that keep a community running.',
    description:
      'The backend that keeps a badminton community running: court scheduling, live scoring, tournaments, and skill ratings that carry across seasons. Qouver builds and operates the Go API behind it, in production today. The mobile app is community-maintained.',
    focus: ['Scheduling', 'Live scoring', 'Ratings', 'Community growth'],
    status: 'Backend',
    stack: 'Go · Postgres · OpenAPI',
    stackItems: ['Go', 'Postgres', 'OpenAPI'],
    url: 'https://api.qouver.com/majadu',
    urlLabel: 'API',
    caseStudy: {
      title: 'Glicko-1 Rating Engine & Frameworkless Go API',
      overview:
        'Majadu powers local sports session operations: balanced doubles matchups, live court scoring, tournament brackets, and cross-season skill rating tracking.',
      problem:
        'Casual sports sessions suffer from subjective player seeding, manual paper scorekeeping, and network drops during live matches in sports halls with weak cellular coverage.',
      architecture:
        'A monorepo with a React 19 PWA frontend and a zero-dependency Go 1.26 backend API using PostgreSQL 18 with schema-based multi-tenancy.',
      decisions: [
        {
          heading: 'Frameworkless Go backend',
          explanation:
            'Built using Go standard library net/http and pgx/v5. Sub-millisecond response times and instant cold starts inside rootless Podman containers.',
        },
        {
          heading: 'Glicko-1 rating with confidence decay',
          explanation:
            'Replaced raw win/loss tallies with a custom Glicko-1 rating engine (Glicko-1-lite) that factors in victory margin and increases rating deviation when players skip seasons.',
        },
        {
          heading: 'Schema-isolated multi-tenancy',
          explanation:
            'Community databases use PostgreSQL search paths per seasonal domain rather than row-level tenant IDs, simplifying backup and data isolation.',
        },
      ],
      takeaways:
        'Standard-library Go code paired with a disciplined mathematical rating model delivers high production reliability with near-zero server resource usage.',
    },
  },
  {
    index: '03',
    slug: 'sds',
    name: 'SDS Management',
    category: 'Compliance',
    tagline: 'Chemical safety data management.',
    description:
      'A compliance tool that keeps chemical safety data sheets current and auditable: versioned documents, hazard pictograms, and clean PDF exports. In production for a real workplace.',
    focus: ['Compliance', 'Documentation', 'Workflow'],
    status: 'Live',
    stack: 'Vue · Go · Postgres',
    stackItems: ['Vue', 'Go', 'Postgres'],
    url: 'https://sds.qouver.com',
    urlLabel: 'VISIT',
    caseStudy: {
      title: 'Audit-Ready Document Versioning & Server PDF Pipeline',
      overview:
        'Workplace compliance management system for chemical Safety Data Sheets (SDS/MSDS): versioned hazard documentation, pictogram matrix, and automated PDF export pipeline.',
      problem:
        'Industrial chemical compliance demands immutable document versioning, exact GHS hazard pictogram mapping, and immediate PDF availability for workplace safety audits.',
      architecture:
        'Vue 3 + TypeScript single-page application frontend paired with a Go REST API backend and a headless Chromium PDF rendering service running inside Podman containers.',
      decisions: [
        {
          heading: 'Headless Chromium PDF export',
          explanation:
            'Server-side Chromium rendering guarantees 100% pixel-identical PDF exports across all browsers and devices for safety inspection audits.',
        },
        {
          heading: 'Immutable document versioning',
          explanation:
            'Updates to safety data sheets never overwrite existing records. Every safety revision increments an immutable version index with complete audit trails.',
        },
        {
          heading: 'GHS Pictogram Matrix',
          explanation:
            'Chemical hazards map directly to GHS pictograms rendered as inline SVGs for instant visual identification during emergency chemical lookups.',
        },
      ],
      takeaways:
        'Server-side document rendering guarantees regulatory compliance fidelity across all audit devices and print media.',
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
            'When Majadu was established, M-DEF was retired and its core rating algorithms were extracted and rewritten in Go for Majadu API.',
        },
      ],
      takeaways:
        'Retiring early standalone experiments in favor of unified backend APIs keeps system maintenance low while preserving core algorithm IP.',
    },
  },
];
