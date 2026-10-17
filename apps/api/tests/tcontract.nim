import std/[os, strutils, tables, unittest]
import ../src/routes

const ContractPath = "packages/contracts/openapi/qouver-api.yaml"

type
  ContractOp = object
    httpMethod: string
    path: string
    operationId: string

proc parseContractOps(filePath: string): seq[ContractOp] =
  let content = readFile(filePath)
  var currentPath = ""
  var currentMethod = ""

  for line in content.splitLines():
    let trimmed = line.strip()
    if line.startsWith("  /") and line.endsWith(":"):
      currentPath = line.strip()[0 .. ^2]
    elif (line.startsWith("    get:") or line.startsWith("    post:")):
      currentMethod = trimmed[0 .. ^2].toUpperAscii()
    elif line.startsWith("      operationId:"):
      let opId = trimmed.replace("operationId:", "").strip()
      if currentPath.len > 0 and currentMethod.len > 0 and opId.len > 0:
        result.add(ContractOp(httpMethod: currentMethod, path: currentPath, operationId: opId))
        currentMethod = ""

suite "OpenAPI Contract vs Routes Implementation":
  test "contract exists at expected location":
    check fileExists(ContractPath)

  test "all implemented routes match contract exactly":
    let contractOps = parseContractOps(ContractPath)
    let routes = allRoutes()

    check contractOps.len == routes.len
    check routes.len > 0

    var contractMap = initTable[string, string]()
    for op in contractOps:
      contractMap[op.httpMethod & " " & op.path] = op.operationId

    for r in routes:
      let key = $r.httpMethod & " " & r.path
      check contractMap.hasKey(key)
      if contractMap.hasKey(key):
        check contractMap[key] == r.operationId

  test "operationIds are unique across routes":
    var seen = initTable[string, bool]()
    for r in allRoutes():
      check not seen.getOrDefault(r.operationId, false)
      seen[r.operationId] = true
