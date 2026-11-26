import std/[options, unittest]
import kernel/types
import ../src/[db, routes, server]

suite "Qouver API Domain & Database Tests":
  setup:
    let db = newDatabase()
    db.seedMemory()

  test "seed projects are loaded correctly":
    let projects = db.getProjects()
    check projects.len == 4
    check projects[0].slug == "majadu"
    check projects[0].status == psBackend
    check projects[1].slug == "sds"
    check projects[1].status == psLive
    check projects[2].slug == "skyward"
    check projects[2].status == psArchived
    check projects[3].slug == "mdef"
    check projects[3].status == psArchived

  test "get project by slug returns case study":
    let opt = db.getProject("skyward")
    check opt.isSome
    let p = opt.get
    check p.name == "Skyward"
    check not p.caseStudy.isNil
    check p.caseStudy.decisions.len == 3

  test "get non-existent project returns none":
    let opt = db.getProject("non-existent-system")
    check opt.isNone

  test "journal articles are loaded correctly":
    let articles = db.getJournalArticles()
    check articles.len == 3
    check articles[0].slug == "authoritative-go-simulations"

  test "journal article detail contains paragraphs and quote":
    let opt = db.getJournalArticle("authoritative-go-simulations")
    check opt.isSome
    let a = opt.get
    check a.paragraphs.len == 3
    check a.quote.len > 0
    check a.codeSnippet.len > 0

  test "add contact inquiry creates valid record with UUID":
    let inquiry = db.addInquiry("Alice", "alice@example.com", "Hello", "Great project!")
    check inquiry.id.len == 36
    check inquiry.name == "Alice"
    check inquiry.email == "alice@example.com"
    check inquiry.status == "received"

  test "systems health lists measured targets only":
    let systems = db.getSystemsHealth()
    check systems.len == 2
    check systems[0].name == "Majadu API"
    check systems[0].status == ssOnline
    for s in systems:
      check s.responseTimeMs == 0 # 0 means "not measured"; nothing probes the host yet

  test "database operations are thread-safe under concurrent access":
    var threads: array[4, Thread[Database]]
    for i in 0 ..< 4:
      createThread(threads[i], proc(d: Database) {.thread.} =
        for j in 0 ..< 25:
          discard d.addInquiry("User " & $j, "user@example.com", "Subject", "Message content")
          discard d.isConnected()
      , db)
    joinThreads(threads)
    check not db.isConnected()

  test "router builds with OPTIONS preflight handling":
    let router = buildRouter(db)
    check router.routes.len >= allRoutes().len
