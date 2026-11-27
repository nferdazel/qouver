## Regression test for the mummy 0.4.8 SIGILL on qouver-api.
##
## mummy 0.4.8 shifted its receive buffer in place with copyMem (memcpy) on
## overlapping ranges. memcpy with overlap is undefined behaviour; the
## Alpine/musl release build traps it as SIGILL (exit 132) whenever a POST
## arrives with its headers and a body longer than the header block in the same
## TCP read.
##
## This test runs the real mummy server on a loopback port in a thread and
## writes headers + body in one send(), so it exercises the receive path that
## trapped production. It must fail on the unpatched source and pass on the
## vendored copy with the four copyMem -> moveMem fixes.

import std/[macros, net, os, strutils, unittest]
import mummy
import mummy/routers

const BodySizes = [1, 63, 200, 400, 5000, 200000]

# The compile-time checks below fail if the imported mummy is the nimble
# package instead of vendor/mummy, or if the overlapping shifts still use
# copyMem. Without them a build could silently link the unpatched module.
macro vendoredMummySource(): untyped =
  let path = getImpl(bindSym("serve", brClosed)).lineInfoObj.filename
  doAssert "vendor/mummy" in path.replace('\\', '/'),
    "mummy resolved to " & path & ", expected vendor/mummy/mummy.nim"
  newLit(readFile(path))

const MummySrc = vendoredMummySource()

static:
  doAssert MummySrc.count("moveMem(") == 4,
    "expected the four overlapping buffer shifts to use moveMem"
  doAssert MummySrc.count("copyMem(") == 6,
    "the disjoint copies must stay copyMem; patch touches four sites only"

proc newTestServer(port: Port) {.thread.} =
  var router: Router
  router.post("/api/loopback", proc(req: Request) {.gcsafe.} =
    var headers: HttpHeaders
    headers["Content-Type"] = "text/plain"
    req.respond(201, headers, "ok")
  )
  let server = newServer(router.toHandler)
  server.serve(port, "127.0.0.1")

proc freeLoopbackPort(): Port =
  let probe = newSocket()
  probe.bindAddr(Port(0), "127.0.0.1")
  let (_, port) = probe.getLocalAddr()
  probe.close()
  result = port

proc waitUntilServing(port: Port) =
  var lastError = ""
  for _ in 0 ..< 100:
    try:
      let sock = newSocket()
      sock.connect("127.0.0.1", port)
      sock.close()
      return
    except CatchableError as e:
      lastError = e.msg
      sleep(20)
  raise newException(IOError, "test server did not start: " & lastError)

proc postInOneWrite(port: Port, bodyLen: int): string =
  ## Sends the request line, headers and body in a single write, which is the
  ## shape that produced the overlapping shift. Returns the status line.
  let body = repeat('x', bodyLen)
  let request =
    "POST /api/loopback HTTP/1.1\r\n" &
    "Host: 127.0.0.1\r\n" &
    "Content-Type: text/plain\r\n" &
    "Content-Length: " & $bodyLen & "\r\n" &
    "Connection: close\r\n" &
    "\r\n" &
    body

  let sock = newSocket()
  defer: sock.close()
  sock.connect("127.0.0.1", port)
  sock.send(request)
  result = sock.recvLine()

suite "Mummy receive buffer regression (SIGILL on POST body > header block)":
  test "loopback server accepts bodies from 1 to 200000 bytes in one write":
    let port = freeLoopbackPort()
    var serverThread: Thread[Port]
    createThread(serverThread, newTestServer, port)
    waitUntilServing(port)

    for bodyLen in BodySizes:
      let statusLine = postInOneWrite(port, bodyLen)
      checkpoint("body=" & $bodyLen & " status=" & statusLine)
      check statusLine.contains("201")

    # The process must still serve after every body size above.
    let finalStatus = postInOneWrite(port, 400)
    check finalStatus.contains("201")
