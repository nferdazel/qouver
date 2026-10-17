## Core domain types for Qouver

type
  ProjectStatus* = enum
    psLive = "Live"
    psBackend = "Backend"
    psArchived = "Archived"

  CaseStudyDecision* = object
    heading*: string
    explanation*: string

  CaseStudy* = object
    title*: string
    overview*: string
    problem*: string
    architecture*: string
    decisions*: seq[CaseStudyDecision]
    takeaways*: string

  Project* = object
    index*: string
    slug*: string
    name*: string
    category*: string
    tagline*: string
    description*: string
    focus*: seq[string]
    status*: ProjectStatus
    stack*: string
    url*: string
    urlLabel*: string
    caseStudy*: ref CaseStudy

  JournalArticleSummary* = object
    slug*: string
    title*: string
    date*: string
    readTime*: string
    category*: string
    summary*: string

  JournalArticle* = object
    slug*: string
    title*: string
    date*: string
    readTime*: string
    category*: string
    summary*: string
    quote*: string
    codeSnippet*: string
    paragraphs*: seq[string]

  SystemStatus* = enum
    ssOnline = "online"
    ssDegraded = "degraded"
    ssOffline = "offline"

  SystemHealth* = object
    name*: string
    slug*: string
    targetUrl*: string
    status*: SystemStatus
    lastCheckedAt*: string
    responseTimeMs*: int

  ContactInquiry* = object
    id*: string
    name*: string
    email*: string
    subject*: string
    message*: string
    status*: string
    createdAt*: string
