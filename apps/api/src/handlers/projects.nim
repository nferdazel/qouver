## Projects handlers

import std/[json, options]
import mummy
import kernel/types
import ./common
import ../db

proc projectToJson(p: Project, includeCaseStudy: bool = false): JsonNode =
  result = %*{
    "index": p.index,
    "slug": p.slug,
    "name": p.name,
    "category": p.category,
    "tagline": p.tagline,
    "description": p.description,
    "focus": %p.focus,
    "status": $p.status,
    "stack": p.stack,
    "url": if p.url.len > 0: %p.url else: newJNull(),
    "urlLabel": p.urlLabel
  }

  if includeCaseStudy and not p.caseStudy.isNil:
    var decisionsNode = newJArray()
    for d in p.caseStudy.decisions:
      decisionsNode.add(%*{
        "heading": d.heading,
        "explanation": d.explanation
      })

    result["caseStudy"] = %*{
      "title": p.caseStudy.title,
      "overview": p.caseStudy.overview,
      "problem": p.caseStudy.problem,
      "architecture": p.caseStudy.architecture,
      "decisions": decisionsNode,
      "takeaways": p.caseStudy.takeaways
    }

proc handleListProjects*(db: Database, req: Request) {.gcsafe.} =
  let list = db.getProjects()
  var arr = newJArray()
  for p in list:
    arr.add(projectToJson(p, includeCaseStudy = false))
  req.respondJson(200, arr)

proc handleGetProjectBySlug*(db: Database, req: Request) {.gcsafe.} =
  let slug = req.pathParams.getOrDefault("slug", "")
  let opt = db.getProject(slug)
  if opt.isNone:
    req.respondError(404, "NOT_FOUND", "Project not found")
    return

  req.respondJson(200, projectToJson(opt.get, includeCaseStudy = true))
