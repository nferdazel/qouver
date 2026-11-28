## Regression test for the mummy 0.4.8 SIGILL on qouver-api.
##
## mummy 0.4.8 shifted its receive buffer in place with copyMem (memcpy) on
## overlapping ranges. memcpy with overlap is undefined behaviour; the
## Alpine/musl release build traps it as SIGILL (exit 132) whenever a POST
## arrives with its headers and a body longer than the header block in the same
## TCP read.
##
## This test runs the real qummy server on a loopback port in a thread and
## writes headers + body in one send(), so it exercises the receive path that
## trapped production. It must fail on the unpatched source and pass on the
## published qummy package, which carries the four copyMem -> moveMem fixes.

import std/[macros, net, os, strutils, unittest]
import qummy
import qummy/routers

const BodySizes = [1, 63, 200, 400, 5000, 200000]

# The compile-time checks below fail if `import qummy` resolves to anything but
# the installed qummy package (a vendored copy or upstream mummy), or if the
# receive shifts still use copyMem. Without them a build could silently link an
# unpatched module.
macro qummyPackageSource(): untyped =
  let path = getImpl(bindSym("serve", brClosed)).lineInfoObj.filename.replace('\\', '/')
  doAssert path.endsWith("/qummy.nim"),
    "import qummy resolved to " & path & ", expected qummy.nim"
  doAssert "/pkgs2/qummy-" in path or "/pkgs/qummy-" in path or "/nimbledeps/qummy" in path,
    "qummy resolved to " & path &
      ", expected the installed qummy package (nimble pkgs2 or nimbledeps)"
  newLit(readFile(path))

const QummySrc = qummyPackageSource()

static:
  doAssert QummySrc.count("moveMem(") == 4,
    "expected the four overlapping buffer shifts to use moveMem"
  doAssert QummySrc.count("copyMem(") == 6,
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

suite "Qummy receive buffer regression (SIGILL on POST body > header block)":
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
