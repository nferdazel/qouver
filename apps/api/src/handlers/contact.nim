## Contact form handler

import std/[json, locks, strutils, tables, times]
import mummy
import ./common
import ../db

type
  ContactRateBucket = object
    count: int
    resetAt: float

var
  contactBuckets: Table[string, ContactRateBucket]
  rateLimiterLock: Lock

initLock(rateLimiterLock)

proc extractClientIp(req: Request): string =
  if req.headers.contains("CF-Connecting-IP") and req.headers["CF-Connecting-IP"].strip.len > 0:
    return req.headers["CF-Connecting-IP"].strip
  if req.headers.contains("X-Forwarded-For") and req.headers["X-Forwarded-For"].strip.len > 0:
    let first = req.headers["X-Forwarded-For"].split(',')[0].strip
    if first.len > 0:
      return first
  return "127.0.0.1"

proc allowContact(ip: string): bool =
  ## Max 5 contact submissions per 5 minutes per IP
  const maxSubmissions = 5
  const windowSec = 300.0
  {.cast(gcsafe).}:
    withLock rateLimiterLock:
      let now = epochTime()

      if contactBuckets.len > 1024:
        var toDel: seq[string] = @[]
        for k, v in contactBuckets:
          if now > v.resetAt:
            toDel.add(k)
        for k in toDel:
          contactBuckets.del(k)

      if not contactBuckets.hasKey(ip):
        contactBuckets[ip] = ContactRateBucket(count: 1, resetAt: now + windowSec)
        return true

      var b = contactBuckets[ip]
      if now > b.resetAt:
        b.count = 1
        b.resetAt = now + windowSec
        contactBuckets[ip] = b
        return true

      inc b.count
      contactBuckets[ip] = b
      return b.count <= maxSubmissions

proc handleContact*(db: Database, req: Request) {.gcsafe.} =
  let ip = extractClientIp(req)
  if not allowContact(ip):
    req.respondError(429, "RATE_LIMIT_EXCEEDED", "Too many messages sent. Please try again later.")
    return

  if req.body.len == 0:
    req.respondError(400, "BAD_REQUEST", "Empty request body")
    return

  var jsonBody: JsonNode
  try:
    jsonBody = parseJson(req.body)
  except CatchableError:
    req.respondError(400, "BAD_REQUEST", "Invalid JSON payload")
    return

  let name = jsonBody.getOrDefault("name").getStr("").strip()
  let email = jsonBody.getOrDefault("email").getStr("").strip()
  let subject = jsonBody.getOrDefault("subject").getStr("").strip()
  let message = jsonBody.getOrDefault("message").getStr("").strip()

  if name.len < 2 or email.len < 5 or "@" notin email or subject.len < 2 or message.len < 5:
    req.respondError(400, "VALIDATION_FAILED", "Invalid fields in contact inquiry")
    return

  if name.len > 100 or email.len > 150 or subject.len > 200 or message.len > 5000:
    req.respondError(400, "VALIDATION_FAILED", "Payload fields exceed maximum allowable length")
    return

  let inquiry = db.addInquiry(name, email, subject, message)

  let resNode = %*{
    "id": inquiry.id,
    "status": inquiry.status,
    "createdAt": inquiry.createdAt
  }

  req.respondJson(201, resNode)
