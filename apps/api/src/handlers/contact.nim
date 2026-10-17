## Contact form handler

import std/[json, strutils]
import mummy
import ./common
import ../db

proc handleContact*(db: Database, req: Request) {.gcsafe.} =
  if req.body.len == 0:
    req.respondError(400, "BAD_REQUEST", "Empty request body")
    return

  var jsonBody: JsonNode
  try:
    jsonBody = parseJson(req.body)
  except CatchableError:
    req.respondError(400, "BAD_REQUEST", "Invalid JSON payload")
    return

  let name = jsonBody.getOrDefault("name").getStr("")
  let email = jsonBody.getOrDefault("email").getStr("")
  let subject = jsonBody.getOrDefault("subject").getStr("")
  let message = jsonBody.getOrDefault("message").getStr("")

  if name.len < 2 or email.len < 5 or "@" notin email or subject.len < 2 or message.len < 5:
    req.respondError(400, "VALIDATION_FAILED", "Invalid fields in contact inquiry")
    return

  let inquiry = db.addInquiry(name, email, subject, message)

  let resNode = %*{
    "id": inquiry.id,
    "status": inquiry.status,
    "createdAt": inquiry.createdAt
  }

  req.respondJson(201, resNode)
