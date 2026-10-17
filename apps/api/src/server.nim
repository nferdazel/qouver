## Mummy HTTP Server Builder

import std/strutils
import mummy
import mummy/routers
import ./config
import ./db
import ./routes

proc mummyPattern*(path: string): string =
  var segments: seq[string]
  for segment in path.split('/'):
    if segment.len > 2 and segment[0] == '{' and segment[^1] == '}':
      segments.add("@" & segment[1 .. ^2])
    else:
      segments.add(segment)
  segments.join("/")

proc bindHandler*(handler: RouteHandler, db: Database): RequestHandler =
  result = proc(req: Request) {.gcsafe.} =
    handler(db, req)

proc buildRouter*(db: Database): Router =
  for spec in allRoutes():
    let handleRequest = bindHandler(spec.handler, db)
    let pattern = mummyPattern(spec.path)
    case spec.httpMethod
    of hmGet:
      result.get(pattern, handleRequest)
    of hmPost:
      result.post(pattern, handleRequest)

proc startServer*(cfg: Config) =
  let db = newDatabase(cfg.databaseUrl)
  db.seedMemory()
  if cfg.databaseUrl.len > 0:
    db.migrate()

  let router = buildRouter(db)
  let server = newServer(router)

  echo "[QOUVER API] Server listening on http://", cfg.host, ":", cfg.port
  server.serve(Port(cfg.port), cfg.host)
