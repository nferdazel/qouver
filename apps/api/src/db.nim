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

# Reading time is derived from the body, not typed by hand: a stored
# "6 min read" next to three short paragraphs is a claim nothing backs up.
# 200 words a minute, rounded to the nearest minute, never below one.
proc readingTime*(paragraphs: seq[string]): string =
  var words = 0
  for p in paragraphs:
    for word in p.splitWhitespace():
      if word.len > 0: inc words
  result = $(max(1, (words + 100) div 200)) & " min read"

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
  ## Default initial seeds loaded into memory.
  ## Order is the register order: operating records first, archived last. The
  ## index is rendered as the "No." column, so it moves with the order.
  db.inMemoryProjects = @[
    Project(
      index: "01",
      slug: "majadu",
      name: "Majadu Tools",
      category: "Community systems",
      tagline: "Systems that keep a community running.",
      description: "The backend that keeps a badminton community running: court scheduling, live scoring, tournaments, and a points board that rewards showing up. Qouver builds and operates the Nim API behind it, in production today.",
      focus: @["Scheduling", "Live scoring", "Ratings", "Community growth"],
      status: psBackend,
      stack: "Nim · Postgres · OpenAPI",
      url: "https://api.qouver.com/majadu",
      urlLabel: "API",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Rolling Points Board & Contract-First Nim API"
        cs.overview = "Majadu powers local sports session operations: balanced doubles matchups, live court scoring, tournament brackets, and a rolling points board."
        cs.problem = "Casual sports sessions suffer from subjective player seeding, manual paper scorekeeping, and network drops during live matches in sports halls with weak cellular coverage."
        cs.architecture = "A Nim 2.4 API served by Mummy over HTTP and WebSocket, backed by PostgreSQL 18 and 61 migrations. One database holds every community, and row-level security guards every community-owned table. This record covers the API and the data behind it."
        cs.decisions = @[
          CaseStudyDecision(heading: "Contract-first Nim API", explanation: "Routes are generated from the 76-operation OpenAPI definition and run on Mummy over HTTP and WebSocket with db_connector. Clients compile from the same contract, so there is no framework layer to hand-maintain."),
          CaseStudyDecision(heading: "Rolling points, not an absolute rating", explanation: "Standings come from the best 10 entries in a rolling 12-week window. A game is weighted by its margin and by an opponent tier multiplier clamped between 0.5 and 1.5. Glicko was retired with the v1 API."),
          CaseStudyDecision(heading: "Tenancy enforced in the database", explanation: "Every community-owned row carries community_id, and row-level security fails closed when the tenant setting is missing. There is no schema per community to keep in sync.")
        ]
        cs.takeaways = "A contract-first Nim service and tenancy the database enforces keep one API serving many communities without a framework layer or a schema per club."
        cs)
    ),
    Project(
      index: "02",
      slug: "sds",
      name: "SDS Management",
      category: "Compliance",
      tagline: "Chemical safety data management.",
      description: "A compliance tool that keeps chemical safety data sheets current and auditable: a searchable register, hazard pictograms, and clean PDF exports. In production for a real workplace.",
      focus: @["Compliance", "Documentation", "Workflow"],
      status: psLive,
      stack: "Vue · Go · Postgres",
      url: "https://sds.qouver.com",
      urlLabel: "VISIT",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Audit-Ready Safety Records & Server PDF Pipeline"
        cs.overview = "Workplace compliance management system for chemical Safety Data Sheets (SDS/MSDS): a searchable chemical register, a pictogram matrix, and an automated PDF export pipeline."
        cs.problem = "Industrial chemical compliance demands exact GHS hazard pictogram mapping, a dated record of every edit, and immediate PDF availability for workplace safety audits."
        cs.architecture = "A Vue 3 + TypeScript single-page application on a Go REST API and PostgreSQL, with headless Chromium rendering PDFs inside the API container and a cache keyed by template hash."
        cs.decisions = @[
          CaseStudyDecision(heading: "Headless Chromium PDF export", explanation: "Chromium renders safety sheets to PDF inside the API container, and the result is cached by template hash. One renderer serves every browser and device."),
          CaseStudyDecision(heading: "One record per chemical per year", explanation: "A unique key on chemical and year keeps one record per chemical. Edits update it in place, and every create, update, delete and copy-year is written to the activity log with the old and new values."),
          CaseStudyDecision(heading: "GHS pictogram matrix", explanation: "Hazards map to pictograms stored as images (PNG, JPEG, GIF, WebP), composited server-side and embedded in the PDF as data URIs for instant visual identification.")
        ]
        cs.takeaways = "One stored record and one renderer keep the sheet identical on every device, and the activity log keeps the history an audit asks for."
        cs)
    ),
    Project(
      index: "03",
      slug: "skyward",
      name: "Skyward",
      category: "Simulation",
      tagline: "Airline tycoon simulation.",
      description: "Run your own airline: build a fleet, open routes, and grow an economy that keeps moving while you're away. The whole world runs on a server-side simulation engine, so your device just plays it and everything stays fair and consistent.",
      focus: @["Simulation", "Strategy", "Systems design"],
      status: psArchived,
      stack: "Flutter · Go · Postgres",
      url: "",
      urlLabel: "VISIT",
      caseStudy: (block:
        var cs = new(CaseStudy)
        cs.title = "Server-Side Tick Simulation Engine & Authoritative State"
        cs.overview = "Skyward is an airline management game where global economy, route calculations, fuel burn, and passenger demand ran continuously on a backend tick worker in Go."
        cs.problem = "Client-side calculated simulations suffer from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop clients."
        cs.architecture = "An authoritative Go 1.22+ backend executes a scheduled world tick loop, persisting state in PostgreSQL 18. The Flutter client (Web & Desktop) acts as a pure, reactive viewer rendering streamed server snapshots."
        cs.decisions = @[
          CaseStudyDecision(heading: "Zero client simulation logic", explanation: "The Flutter client contains no financial or flight trajectory formulas. All flight paths, fuel consumption, and market yields are calculated strictly on the backend."),
          CaseStudyDecision(heading: "Deterministic world tick loop", explanation: "World ticks execute at fixed server intervals. When a player logs in after days away, the backend processes past tick windows deterministically without melting client memory."),
          CaseStudyDecision(heading: "ACID transaction isolation", explanation: "All airline financial operations use strict PostgreSQL database transactions to prevent double-spending or route duplication under concurrent player actions.")
        ]
        cs.takeaways = "Moving simulation authority entirely to backend workers removed the client as a cheat vector and kept Web and Desktop clients in sync."
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
          CaseStudyDecision(heading: "Retirement & algorithm migration", explanation: "When Majadu was established, M-DEF was retired. Its rating ideas informed Majadu's first API; the current Majadu points model replaced them.")
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
      category: "Architecture",
      summary: "Why client-side calculated state always diverges, and how we built Skyward's deterministic server tick engine in standard library Go.",
      quote: "Moving simulation authority entirely to backend workers guarantees 100% fair play, zero cheat vectors, and instant state synchronization across clients.",
      codeSnippet: "// World tick loop in Go\nfunc (s *TickEngine) Start(ctx context.Context) {\n    ticker := time.NewTicker(s.interval)\n    defer ticker.Stop()\n    for {\n        select {\n        case <-ctx.Done():\n            return\n        case t := <-ticker.C:\n            s.processTickWindow(t)\n        }\n    }\n}",
      paragraphs: @[
        "When building Skyward, an airline tycoon simulation, the initial temptation was to calculate flight progression and market yields on the client. But client-side calculation suffers from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop apps.",
        "To solve this, we moved all mathematical authority to a deterministic backend tick worker in Go. The Flutter client acts purely as a reactive viewer rendering server snapshots.",
        "By decoupling calculation from presentation, the world tick loop ran continuously in production on PostgreSQL transactions, without relying on any client JavaScript or client state hacks. It stopped when the game was archived, and the code is no longer deployed."
      ]
    ),
    JournalArticle(
      slug: "zero-js-static-jaspr",
      title: "Static First: How This Site Ships HTML Before JavaScript",
      date: "2026-08-18",
      category: "Web Craft",
      summary: "Every route is prerendered at build time with adapter-static, then hydrated by a small SvelteKit bundle. What that buys, and what it costs.",
      quote: "Prerendering removes the server from the request path. It does not remove the browser from the page, and pretending otherwise is the part that fails.",
      codeSnippet: "// apps/web/src/routes/+layout.ts\nexport const prerender = true;\nexport const ssr = true;\nexport const trailingSlash = 'never';",
      paragraphs: @[
        "This site is built with SvelteKit and adapter-static. Every route is rendered to HTML at build time, and Caddy serves that tree as plain files: no web server renders a page at request time, and there is no loader state to wait for before the text arrives.",
        "What ships alongside the HTML is honest to measure. A home page load fetches twenty module scripts, 46 KiB gzipped and 115 KiB decoded. An article page is 41 KiB gzipped. Those bytes buy client-side navigation, the contact form, and the mail link, and they are fetched after the HTML has already painted.",
        "The trade-off is worth naming. With JavaScript blocked, the text, the links and the case studies still work, because the markup is real. The contact form does not, because it posts through fetch. That is the boundary this site accepts: content readable without script, interaction requiring it."
      ]
    ),
    JournalArticle(
      slug: "systems-prospector-manifesto",
      title: "The Systems Prospector: Finding Latent Value in Latent Problems",
      date: "2026-08-15",
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

  for a in db.inMemoryArticles.mitems:
    a.readTime = readingTime(a.paragraphs)

  # Nothing probes these hosts at runtime, so the list carries only systems whose
  # target answers, with the date of the last manual check. Latency is 0, which
  # means "not measured" — an invented millisecond figure is worse than a blank.
  # Skyward is archived and its host no longer resolves, so it is not listed.
  const seedCheckedAt = "2026-11-26T00:00:00Z"
  db.inMemorySystems = @[
    SystemHealth(name: "Majadu API", slug: "majadu", targetUrl: "https://api.qouver.com/majadu/healthz", status: ssOnline, lastCheckedAt: seedCheckedAt, responseTimeMs: 0),
    SystemHealth(name: "SDS Management", slug: "sds", targetUrl: "https://sds.qouver.com", status: ssOnline, lastCheckedAt: seedCheckedAt, responseTimeMs: 0)
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
