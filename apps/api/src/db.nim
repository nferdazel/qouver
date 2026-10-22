## PostgreSQL Database Layer for Qouver

import std/[locks, options, strutils, times, sysrand]
import db_connector/db_postgres
import kernel/types

type
  Database* = ref object
    conn*: Option[DbConn]
    lock*: Lock
    startTime*: float
    inMemoryProjects*: seq[Project]
    inMemoryArticles*: seq[JournalArticle]
    inMemorySystems*: seq[SystemHealth]
    inMemoryInquiries*: seq[ContactInquiry]

template withDb*(db: Database, body: untyped) =
  withLock db.lock:
    body

proc newDatabase*(databaseUrl: string = ""): Database =
  new(result)
  initLock(result.lock)
  result.conn = none(DbConn)
  result.startTime = epochTime()
  result.inMemoryProjects = @[]
  result.inMemoryArticles = @[]
  result.inMemorySystems = @[]
  result.inMemoryInquiries = @[]

  if databaseUrl.len > 0:
    try:
      let conn = open("", "", "", databaseUrl)
      result.conn = some(conn)
    except CatchableError as e:
      echo "[DB WARN] Failed to connect to PostgreSQL: ", e.msg, " (falling back to memory data)"

proc isConnected*(db: Database): bool =
  if db.conn.isSome:
    try:
      withLock db.lock:
        let row = db.conn.get.getRow(sql"SELECT 1")
        return row.len > 0 and row[0] == "1"
    except CatchableError:
      return false
  false

proc migrate*(db: Database) =
  if db.conn.isNone:
    return

  withLock db.lock:
    let c = db.conn.get
    c.exec(sql"""
    CREATE TABLE IF NOT EXISTS projects (
      slug VARCHAR(64) PRIMARY KEY,
      index_num VARCHAR(8) NOT NULL,
      name VARCHAR(128) NOT NULL,
      category VARCHAR(64) NOT NULL,
      tagline TEXT NOT NULL,
      description TEXT NOT NULL,
      focus TEXT[] NOT NULL DEFAULT '{}',
      status VARCHAR(32) NOT NULL,
      stack TEXT NOT NULL,
      url TEXT,
      url_label VARCHAR(32) DEFAULT 'VISIT',
      case_study JSONB
    );
  """)

    c.exec(sql"""
    CREATE TABLE IF NOT EXISTS journal_articles (
      slug VARCHAR(128) PRIMARY KEY,
      title VARCHAR(256) NOT NULL,
      date_published DATE NOT NULL,
      read_time VARCHAR(32) NOT NULL,
      category VARCHAR(64) NOT NULL,
      summary TEXT NOT NULL,
      quote TEXT,
      code_snippet TEXT,
      paragraphs TEXT[] NOT NULL DEFAULT '{}'
    );
  """)

    c.exec(sql"""
    CREATE TABLE IF NOT EXISTS systems_health (
      slug VARCHAR(64) PRIMARY KEY,
      name VARCHAR(128) NOT NULL,
      target_url TEXT NOT NULL,
      status VARCHAR(32) NOT NULL DEFAULT 'online',
      last_checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      response_time_ms INT NOT NULL DEFAULT 0
    );
  """)

    c.exec(sql"""
    CREATE TABLE IF NOT EXISTS inquiries (
      id UUID PRIMARY KEY,
      name VARCHAR(128) NOT NULL,
      email VARCHAR(256) NOT NULL,
      subject VARCHAR(256) NOT NULL,
      message TEXT NOT NULL,
      status VARCHAR(32) NOT NULL DEFAULT 'received',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  """)

proc seedMemory*(db: Database) =
  ## Default initial seeds loaded into memory
  db.inMemoryProjects = @[
    Project(
      index: "01",
      slug: "skyward",
      name: "Skyward",
      category: "Simulation",
      tagline: "Airline tycoon simulation.",
      description: "Run your own airline: build a fleet, open routes, and grow an economy that keeps moving while you're away. The whole world runs on a server-side simulation engine, so your device just plays it and everything stays fair and consistent. Live now at skyward.qouver.com.",
      focus: @["Simulation", "Strategy", "Systems design"],
      status: psLive,
      stack: "Flutter · Go · Postgres",
      url: "https://skyward.qouver.com",
      urlLabel: "VISIT",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Server-Side Tick Simulation Engine & Authoritative State"
        cs.overview = "Skyward is an airline management game where global economy, route calculations, fuel burn, and passenger demand operate continuously on a backend tick worker in Go."
        cs.problem = "Client-side calculated simulations suffer from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop clients."
        cs.architecture = "An authoritative Go 1.22+ backend executes a scheduled world tick loop, persisting state in PostgreSQL 18. The Flutter client acts as a pure, reactive viewer rendering streamed server snapshots."
        cs.decisions = @[
          CaseStudyDecision(heading: "Zero client simulation logic", explanation: "The Flutter client contains no financial or flight trajectory formulas. All flight paths, fuel consumption, and market yields are calculated strictly on the backend."),
          CaseStudyDecision(heading: "Deterministic world tick loop", explanation: "World ticks execute at fixed server intervals. When a player logs in after days away, the backend processes past tick windows deterministically without melting client memory."),
          CaseStudyDecision(heading: "ACID transaction isolation", explanation: "All airline financial operations use strict PostgreSQL database transactions to prevent double-spending or route duplication under concurrent player actions.")
        ]
        cs.takeaways = "Moving simulation authority entirely to Go backend workers guarantees 100% fair play, zero client-side cheat vectors, and instant synchronization between Web and Desktop clients."
        cs)
    ),
    Project(
      index: "02",
      slug: "majadu",
      name: "Majadu Tools",
      category: "Community systems",
      tagline: "Systems that keep a community running.",
      description: "The backend that keeps a badminton community running: court scheduling, live scoring, tournaments, and skill ratings that carry across seasons. Qouver builds and operates the Go API behind it, in production today. The mobile app is community-maintained.",
      focus: @["Scheduling", "Live scoring", "Ratings", "Community growth"],
      status: psBackend,
      stack: "Go · Postgres · OpenAPI",
      url: "https://api.qouver.com/majadu",
      urlLabel: "API",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Glicko-1 Rating Engine & Frameworkless Go API"
        cs.overview = "Majadu powers local sports session operations: balanced doubles matchups, live court scoring, tournament brackets, and cross-season skill rating tracking."
        cs.problem = "Casual sports sessions suffer from subjective player seeding, manual paper scorekeeping, and network drops during live matches in sports halls with weak cellular coverage."
        cs.architecture = "A monorepo with a React 19 PWA frontend and a zero-dependency Go 1.26 backend API using PostgreSQL 18 with schema-based multi-tenancy."
        cs.decisions = @[
          CaseStudyDecision(heading: "Frameworkless Go backend", explanation: "Built using Go standard library net/http and pgx/v5. Sub-millisecond response times and instant cold starts inside rootless Podman containers."),
          CaseStudyDecision(heading: "Glicko-1 rating with confidence decay", explanation: "Replaced raw win/loss tallies with a custom Glicko-1 rating engine (Glicko-1-lite) that factors in victory margin and increases rating deviation when players skip seasons."),
          CaseStudyDecision(heading: "Schema-isolated multi-tenancy", explanation: "Community databases use PostgreSQL search paths per seasonal domain rather than row-level tenant IDs, simplifying backup and data isolation.")
        ]
        cs.takeaways = "Standard-library Go code paired with a disciplined mathematical rating model delivers high production reliability with near-zero server resource usage."
        cs)
    ),
    Project(
      index: "03",
      slug: "sds",
      name: "SDS Management",
      category: "Compliance",
      tagline: "Chemical safety data management.",
      description: "A compliance tool that keeps chemical safety data sheets current and auditable: versioned documents, hazard pictograms, and clean PDF exports. In production for a real workplace.",
      focus: @["Compliance", "Documentation", "Workflow"],
      status: psLive,
      stack: "Vue · Go · Postgres",
      url: "https://sds.qouver.com",
      urlLabel: "VISIT",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Audit-Ready Document Versioning & Server PDF Pipeline"
        cs.overview = "Workplace compliance management system for chemical Safety Data Sheets (SDS/MSDS): versioned hazard documentation, pictogram matrix, and automated PDF export pipeline."
        cs.problem = "Industrial chemical compliance demands immutable document versioning, exact GHS hazard pictogram mapping, and immediate PDF availability for workplace safety audits."
        cs.architecture = "Vue 3 + TypeScript single-page application frontend paired with a Go REST API backend and a headless Chromium PDF rendering service running inside Podman containers."
        cs.decisions = @[
          CaseStudyDecision(heading: "Headless Chromium PDF export", explanation: "Server-side Chromium rendering guarantees 100% pixel-identical PDF exports across all browsers and devices for safety inspection audits."),
          CaseStudyDecision(heading: "Immutable document versioning", explanation: "Updates to safety data sheets never overwrite existing records. Every safety revision increments an immutable version index with complete audit trails."),
          CaseStudyDecision(heading: "GHS Pictogram Matrix", explanation: "Chemical hazards map directly to GHS pictograms rendered as inline SVGs for instant visual identification during emergency chemical lookups.")
        ]
        cs.takeaways = "Server-side document rendering guarantees regulatory compliance fidelity across all audit devices and print media."
        cs)
    ),
    Project(
      index: "04",
      slug: "mdef",
      name: "M-DEF",
      category: "Analytics",
      tagline: "Badminton analytics platform.",
      description: "A leaderboard and analytics platform built for a real badminton community, powered by a custom rating engine that weighed how convincingly you won and kept ratings honest when players went quiet. It ran in production with live rankings and seasonal standings; its ideas now live on inside Majadu.",
      focus: @["Ranking systems", "Statistics", "Community insights"],
      status: psArchived,
      stack: "Flutter · Supabase / Postgres",
      url: "",
      urlLabel: "VISIT",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Lessons from an Early Badminton Analytics Engine"
        cs.overview = "An early leaderboard and analytics platform built for recreational badminton leagues, providing dynamic player ratings and match statistics before being superseded by Majadu."
        cs.problem = "Tracking player standings across unstructured recreational matches required a dynamic ranking model before backend APIs were unified."
        cs.architecture = "Flutter frontend client paired with Supabase / PostgreSQL backend, featuring a custom rating algorithm weighing win margins and inactivity decay."
        cs.decisions = @[
          CaseStudyDecision(heading: "Inactivity decay penalty", explanation: "Rankings automatically decayed when players stopped competing, preventing inactive players from occupying top leaderboard positions indefinitely."),
          CaseStudyDecision(heading: "Retirement & algorithm migration", explanation: "When Majadu was established, M-DEF was retired and its core rating algorithms were extracted and rewritten in Go for Majadu API.")
        ]
        cs.takeaways = "Retiring early standalone experiments in favor of unified backend APIs keeps system maintenance low while preserving core algorithm IP."
        cs)
    )
  ]

  db.inMemoryArticles = @[
    JournalArticle(
      slug: "authoritative-go-simulations",
      title: "Authoritative World Tick Simulation Engines in Go",
      date: "2026-09-08",
      readTime: "6 min read",
      category: "Architecture",
      summary: "Why client-side calculated state always diverges, and how we built Skyward's deterministic server tick engine in standard library Go.",
      quote: "Moving simulation authority entirely to backend workers guarantees 100% fair play, zero cheat vectors, and instant state synchronization across clients.",
      codeSnippet: "// World tick loop in Go\nfunc (s *TickEngine) Start(ctx context.Context) {\n    ticker := time.NewTicker(s.interval)\n    defer ticker.Stop()\n    for {\n        select {\n        case <-ctx.Done():\n            return\n        case t := <-ticker.C:\n            s.processTickWindow(t)\n        }\n    }\n}",
      paragraphs: @[
        "When building Skyward, an airline tycoon simulation, the initial temptation was to calculate flight progression and market yields on the client. But client-side calculation suffers from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop apps.",
        "To solve this, we moved all mathematical authority to a deterministic backend tick worker in Go. The Flutter client acts purely as a reactive viewer rendering server snapshots.",
        "By decoupling calculation from presentation, the world tick loop runs continuously in production on PostgreSQL transactions without relying on any client JavaScript or client state hacks."
      ]
    ),
    JournalArticle(
      slug: "zero-js-static-jaspr",
      title: "Zero-JS Static Web: Why We Rebuilt Qouver with Jaspr",
      date: "2026-08-18",
      readTime: "4 min read",
      category: "Web Craft",
      summary: "Migrating from heavy SPA frameworks to Jaspr static mode: a 0-JS runtime, pre-rendered HTML, and server-baked SEO.",
      quote: "A corporate home page does not need 3MB of hydration scripts to render text and images. Pure static HTML delivers instant paint and zero fragile dependencies.",
      codeSnippet: "// Server prerendering in Jaspr static mode\nvoid main() {\n  runApp(Document(\n    title: 'Qouver',\n    head: [/* static SEO baked here */],\n    body: App(),\n  ));\n}",
      paragraphs: @[
        "In August 2026, we audited our web stack. Many modern sites ship megabytes of client JavaScript just to present static editorial text and project catalogues.",
        "By migrating to Jaspr in static mode, every route is prerendered to pure HTML at build time. There is no client bundle, no hydration delay, and zero client JS execution.",
        "The result is a site with no client JavaScript bundle at all: pre-rendered HTML served directly via Caddy, with self-hosted fonts and images making up the rest of the payload."
      ]
    ),
    JournalArticle(
      slug: "systems-prospector-manifesto",
      title: "The Systems Prospector: Finding Latent Value in Latent Problems",
      date: "2026-08-15",
      readTime: "5 min read",
      category: "Philosophy",
      summary: "Valuable systems hide in overlooked places: sports scoring, compliance documents, and simulation loops. Building for endurance over hype.",
      quote: "Something has value that others walk past. Find it, understand it, build a system from it, and write down what you learned.",
      codeSnippet: "",
      paragraphs: @[
        "Most software startups focus on saturated consumer markets or AI wrapper trends. But valuable problems often sit in plain sight: a local community needing structured session ratings, a workplace requiring chemical safety compliance, or a simulation engine.",
        "The role of a systems prospector is to notice these gaps, apply rigorous software craft, and build independent tools that stand up over time.",
        "Projects may evolve or integrate, but the commitment to independent building and open knowledge remains."
      ]
    )
  ]

  db.inMemorySystems = @[
    SystemHealth(name: "Skyward", slug: "skyward", targetUrl: "https://skyward.qouver.com", status: ssOnline, lastCheckedAt: now().utc().format("yyyy-MM-dd'T'HH:mm:ss'Z'"), responseTimeMs: 42),
    SystemHealth(name: "Majadu API", slug: "majadu", targetUrl: "https://api.qouver.com/majadu/healthz", status: ssOnline, lastCheckedAt: now().utc().format("yyyy-MM-dd'T'HH:mm:ss'Z'"), responseTimeMs: 28),
    SystemHealth(name: "SDS Management", slug: "sds", targetUrl: "https://sds.qouver.com", status: ssOnline, lastCheckedAt: now().utc().format("yyyy-MM-dd'T'HH:mm:ss'Z'"), responseTimeMs: 65)
  ]

proc getProjects*(db: Database): seq[Project] =
  db.inMemoryProjects

proc getProject*(db: Database, slug: string): Option[Project] =
  for p in db.inMemoryProjects:
    if p.slug == slug:
      return some(p)
  none(Project)

proc getJournalArticles*(db: Database): seq[JournalArticleSummary] =
  for a in db.inMemoryArticles:
    result.add(JournalArticleSummary(
      slug: a.slug,
      title: a.title,
      date: a.date,
      readTime: a.readTime,
      category: a.category,
      summary: a.summary
    ))

proc getJournalArticle*(db: Database, slug: string): Option[JournalArticle] =
  for a in db.inMemoryArticles:
    if a.slug == slug:
      return some(a)
  none(JournalArticle)

proc getSystemsHealth*(db: Database): seq[SystemHealth] =
  db.inMemorySystems

proc bytesToHex(bytes: openArray[byte]): string =
  result = newString(bytes.len * 2)
  const hexChars = "0123456789abcdef"
  for i, b in bytes:
    result[i * 2] = hexChars[int(b shr 4)]
    result[i * 2 + 1] = hexChars[int(b and 0x0f)]

proc close*(db: Database) =
  withLock db.lock:
    if db.conn.isSome:
      try:
        db.conn.get.close()
      except CatchableError:
        discard
      db.conn = none(DbConn)
  deinitLock(db.lock)

proc addInquiry*(db: Database, name, email, subject, message: string): ContactInquiry =
  var rnd: array[16, byte]
  discard urandom(rnd)
  # Simple formatted UUID v4
  let h = bytesToHex(rnd)
  let id = h[0..7] & "-" & h[8..11] & "-4" & h[13..15] & "-a" & h[17..19] & "-" & h[20..31]
  let nowStr = now().utc().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
  
  result = ContactInquiry(
    id: id.toLowerAscii(),
    name: name,
    email: email,
    subject: subject,
    message: message,
    status: "received",
    createdAt: nowStr
  )

  withLock db.lock:
    if db.conn.isSome:
      try:
        db.conn.get.exec(sql"""
          INSERT INTO inquiries (id, name, email, subject, message, status, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        """, result.id, result.name, result.email, result.subject, result.message, result.status, result.createdAt)
      except CatchableError as e:
        echo "[DB ERR] Failed to insert inquiry to postgres: ", e.msg
        result.status = "queued_local"

    if db.inMemoryInquiries.len >= 500:
      db.inMemoryInquiries.delete(0)
    db.inMemoryInquiries.add(result)
