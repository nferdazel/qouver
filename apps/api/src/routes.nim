## Route definitions matching packages/contracts/openapi/qouver-api.yaml

import mummy
import ./db
import ./handlers/[health, projects, journal, systems, contact]

type
  HttpMethod* = enum
    hmGet = "GET"
    hmPost = "POST"

  RouteHandler* = proc(db: Database, req: Request) {.gcsafe.}

  RouteSpec* = object
    httpMethod*: HttpMethod
    path*: string
    operationId*: string
    handler*: RouteHandler

proc handleOptions*(req: Request) {.gcsafe.} =
  ## Responds to HTTP OPTIONS preflight requests with 204 No Content and CORS headers
  var headers: HttpHeaders
  headers["Access-Control-Allow-Origin"] = "*"
  headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
  headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  req.respond(204, headers)

proc handleOptions*(db: Database, req: Request) {.gcsafe.} =
  ## Database overload for handleOptions to match RouteHandler signature if needed
  handleOptions(req)

proc allRoutes*(): seq[RouteSpec] =
  @[
    RouteSpec(
      httpMethod: hmGet,
      path: "/healthz",
      operationId: "getHealth",
      handler: handleHealth
    ),
    RouteSpec(
      httpMethod: hmGet,
      path: "/api/projects",
      operationId: "listProjects",
      handler: handleListProjects
    ),
    RouteSpec(
      httpMethod: hmGet,
      path: "/api/projects/{slug}",
      operationId: "getProjectBySlug",
      handler: handleGetProjectBySlug
    ),
    RouteSpec(
      httpMethod: hmGet,
      path: "/api/journal",
      operationId: "listJournalArticles",
      handler: handleListJournalArticles
    ),
    RouteSpec(
      httpMethod: hmGet,
      path: "/api/journal/{slug}",
      operationId: "getJournalArticleBySlug",
      handler: handleGetJournalArticleBySlug
    ),
    RouteSpec(
      httpMethod: hmGet,
      path: "/api/systems/status",
      operationId: "getSystemsStatus",
      handler: handleGetSystemsStatus
    ),
    RouteSpec(
      httpMethod: hmPost,
      path: "/api/contact",
      operationId: "submitContactInquiry",
      handler: handleContact
    ),
  ]
