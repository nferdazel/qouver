import std/os
import std/strutils

type
  Config* = object
    host*: string
    port*: int
    databaseUrl*: string
    env*: string

proc loadConfig*(): Config =
  result.host = getEnv("QOUVER_HOST", "127.0.0.1")
  result.port = parseInt(getEnv("QOUVER_PORT", "8091"))
  result.databaseUrl = getEnv("QOUVER_DATABASE_URL", "")
  result.env = getEnv("QOUVER_ENV", "development")
