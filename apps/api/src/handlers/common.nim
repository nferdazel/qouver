## Common HTTP helpers for handlers

import std/json
import mummy

proc respondJson*(req: Request, status: int, body: JsonNode) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  headers["Access-Control-Allow-Origin"] = "*"
  headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
  headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  req.respond(status, headers, $body)

proc respondError*(req: Request, status: int, err: string, message: string) =
  let body = %*{
    "error": err,
    "message": message
  }
  req.respondJson(status, body)
