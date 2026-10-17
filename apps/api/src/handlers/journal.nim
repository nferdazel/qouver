## Journal handlers

import std/[json, options]
import mummy
import ./common
import ../db

proc handleListJournalArticles*(db: Database, req: Request) {.gcsafe.} =
  let articles = db.getJournalArticles()
  var arr = newJArray()
  for a in articles:
    arr.add(%*{
      "slug": a.slug,
      "title": a.title,
      "date": a.date,
      "readTime": a.readTime,
      "category": a.category,
      "summary": a.summary
    })
  req.respondJson(200, arr)

proc handleGetJournalArticleBySlug*(db: Database, req: Request) {.gcsafe.} =
  let slug = req.pathParams.getOrDefault("slug", "")
  let opt = db.getJournalArticle(slug)
  if opt.isNone:
    req.respondError(404, "NOT_FOUND", "Journal article not found")
    return

  let a = opt.get
  let body = %*{
    "slug": a.slug,
    "title": a.title,
    "date": a.date,
    "readTime": a.readTime,
    "category": a.category,
    "summary": a.summary,
    "quote": if a.quote.len > 0: %a.quote else: newJNull(),
    "codeSnippet": if a.codeSnippet.len > 0: %a.codeSnippet else: newJNull(),
    "paragraphs": %a.paragraphs
  }
  req.respondJson(200, body)
