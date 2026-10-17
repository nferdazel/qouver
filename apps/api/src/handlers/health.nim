## Health check handler

import std/[json, times]
import mummy
import ./common
import ../db

proc handleHealth*(db: Database, req: Request) {.gcsafe.} =
  let isDbOk = db.isConnected()
  let uptime = int(epochTime() - db.startTime)

  let body = %*{
    "status": "ok",
    "database": if isDbOk: "connected" else: "disconnected",
    "version": "0.1.0",
    "uptimeSeconds": uptime
  }

  req.respondJson(200, body)
