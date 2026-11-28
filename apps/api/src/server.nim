## Qummy HTTP Server Builder

import std/[posix, strutils, atomics]
import qummy
import qummy/routers
import ./config
import ./db
import ./routes

proc exitNow(code: cint) {.importc: "_exit", header: "<unistd.h>".}

# Stop signals.
#
# Inside the container this binary is PID 1, which gets no default action for
# SIGTERM, so without a handler `podman stop` waits out StopTimeout and SIGKILLs
# us (unit reports status=137).
#
# Signal context stays async-signal-safe: one atomic load, one atomic exchange
# and a plain `_exit` syscall. bf4a4b1 crashed with SIGSEGV because it called
# Qummy's Server.close() here, and close() takes the selector lock.
#
# A request that is already being served is allowed to finish before the process
# leaves. `alarm` arms a hard cap at signal time, so a stuck client cannot push
# the stop past podman's 10s StopTimeout.
const StopDrainCapSeconds = 5
const ResponseFlushGraceUs = 50_000

var stopRequested: Atomic[bool]
var inFlightRequests: Atomic[int]

proc exitOnDrainTimeout(sig: cint) {.noconv.} =
  exitNow(0)

proc exitOnStopSignal(sig: cint) {.noconv.} =
  if inFlightRequests.load(moRelaxed) == 0:
    exitNow(0)
  if not stopRequested.exchange(true, moRelaxed):
    discard alarm(StopDrainCapSeconds)

proc installShutdownSignals*() =
  signal(SIGTERM, exitOnStopSignal)
  signal(SIGINT, exitOnStopSignal)
  signal(SIGALRM, exitOnDrainTimeout)

proc trackInFlight(handler: RequestHandler): RequestHandler =
  ## Counts requests being served, so a stop signal can wait for the last one.
  result = proc(req: Request) {.gcsafe.} =
    discard inFlightRequests.fetchAdd(1, moRelaxed)
    try:
      handler(req)
    finally:
      if inFlightRequests.fetchSub(1, moRelaxed) == 1 and
          stopRequested.load(moRelaxed):
        # respond() only queues the response; give the serving loop a moment to
        # write it before we leave, otherwise the last client gets a cut body.
        discard usleep(ResponseFlushGraceUs)
        exitNow(0)

proc qummyPattern*(path: string): string =
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
    let pattern = qummyPattern(spec.path)
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
  let server = newServer(trackInFlight(router.toHandler))
  installShutdownSignals()

  echo "[QOUVER API] Server listening on http://", cfg.host, ":", cfg.port
  server.serve(Port(cfg.port), cfg.host)
