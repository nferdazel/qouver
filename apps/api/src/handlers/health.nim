## Health check handler

import std/[json, times]
import mummy
import ./common
import ../db

## Build revision, injected with -d:GitRev=<sha> by the container build.
const GitRev {.strdefine.} = "dev"

proc handleHealth*(db: Database, req: Request) {.gcsafe.} =
  let isDbOk = db.isConnected()
  let uptime = int(epochTime() - db.startTime)

  let body = %*{
    "status": "ok",
    "database": if isDbOk: "connected" else: "disconnected",
    "version": "0.1.0",
    "revision": GitRev,
    "uptimeSeconds": uptime
  }

  req.respondJson(200, body)
