## Entry point for Qouver API service
##
## Two roles share this binary, selected with `--role`:
##   api      serve HTTP on the configured host and port (default 127.0.0.1:8091)
##   migrate  apply pending database migrations, then exit
##
## The container image is built from `ops/container/qouver-api.Dockerfile` and
## deployed to the VPS by `ops/scripts/deploy-vps.sh`; a source change here needs
## a rebuild, a web-only change does not.

import std/[parseopt, strutils, options]
import ./config
import ./db
import ./server

proc printUsage() =
  echo "Usage: qouver-api [options]"
  echo "  --role=api|migrate   Process role (default: api)"
  echo "  --port=PORT          Port to listen on (default: 8091)"
  echo "  --host=HOST          Host to bind on (default: 127.0.0.1)"
  echo "  --help               Show this help"

proc main() =
  var cfg = loadConfig()
  var role = "api"

  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key.toLowerAscii()
      of "role":
        role = p.val
      of "port":
        cfg.port = parseInt(p.val)
      of "host":
        cfg.host = p.val
      of "help":
        printUsage()
        return
      else:
        echo "Unknown option: --", p.key
    of cmdArgument:
      discard

  case role
  of "api":
    startServer(cfg)
  of "migrate":
    echo "[MIGRATE] Running database migrations..."
    let db = newDatabase(cfg.databaseUrl)
    if db.conn.isSome:
      db.migrate()
      echo "[MIGRATE] Completed successfully."
    else:
      echo "[MIGRATE ERR] Cannot run migrations without QOUVER_DATABASE_URL"
  else:
    echo "Unknown role: ", role
    quit(1)

when isMainModule:
  main()
