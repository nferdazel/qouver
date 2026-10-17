## Systems health handler

import std/json
import mummy
import ./common
import ../db

proc handleGetSystemsStatus*(db: Database, req: Request) {.gcsafe.} =
  let list = db.getSystemsHealth()
  var arr = newJArray()
  for s in list:
    arr.add(%*{
      "name": s.name,
      "slug": s.slug,
      "targetUrl": s.targetUrl,
      "status": $s.status,
      "lastCheckedAt": s.lastCheckedAt,
      "responseTimeMs": s.responseTimeMs
    })
  req.respondJson(200, arr)
