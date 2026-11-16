## Mummy HTTP Server Builder

import std/[posix, strutils]
import mummy
import mummy/routers
import ./config
import ./db
import ./routes

# Inside the container this binary is PID 1, which gets no default action for
# SIGTERM, so without a handler `podman stop` waits out StopTimeout and SIGKILLs
# us (unit reports status=137). close() stops accepting and lets in-flight
# handlers finish, then serve() returns and the process exits 0.
var shutdownTarget: Server

proc onShutdownSignal(sig: cint) {.noconv.} =
  if not shutdownTarget.isNil:
    shutdownTarget.close()

proc installShutdownSignals*(server: Server) =
  shutdownTarget = server
  # No `discard`: posix.signal returns nothing on the Nim 2.2 line that CI and
  # the image build use, so discarding its result is a type error there.
  signal(SIGTERM, onShutdownSignal)
  signal(SIGINT, onShutdownSignal)

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
  # CORS preflight OPTIONS handling for all endpoints
  result.options("/**", proc(req: Request) {.gcsafe.} =
    handleOptions(req)
  )
  result.options("/*", proc(req: Request) {.gcsafe.} =
    handleOptions(req)
  )
  result.options("/", proc(req: Request) {.gcsafe.} =
    handleOptions(req)
  )

  for spec in allRoutes():
    let handleRequest = bindHandler(spec.handler, db)
    let pattern = mummyPattern(spec.path)
    result.options(pattern, proc(req: Request) {.gcsafe.} =
      handleOptions(req)
    )
    case spec.httpMethod
    of hmGet:
      result.get(pattern, handleRequest)
    of hmPost:
      result.post(pattern, handleRequest)

  # Fallback for methodNotAllowed on preflight OPTIONS
  result.methodNotAllowedHandler = proc(req: Request) {.gcsafe.} =
    if req.httpMethod == "OPTIONS":
      handleOptions(req)
    else:
      var headers: HttpHeaders
      headers["Content-Type"] = "text/html"
      req.respond(405, headers, "<h1>Method Not Allowed</h1>")

proc startServer*(cfg: Config) =
  let db = newDatabase(cfg.databaseUrl)
  db.seedMemory()
  if cfg.databaseUrl.len > 0:
    db.migrate()

  let router = buildRouter(db)
  let server = newServer(router)
  installShutdownSignals(server)

  echo "[QOUVER API] Server listening on http://", cfg.host, ":", cfg.port
  server.serve(Port(cfg.port), cfg.host)
