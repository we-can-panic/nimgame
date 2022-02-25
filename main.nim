import jester, posix, json, logging, os, strutils, asyncdispatch
import htmlgen as h

onSignal(SIGABRT):
  echo "<2>Received SIGABRT"
  quit(1)

let
  fl   = newFileLogger("logs.log",
                       fmtStr = "$datetime $levelname ")
addHandler(fl)

proc log_debug(args: varargs[string, `$`]) =
  debug args
  fl.file.flushFile()

proc log_info(args: varargs[string, `$`]) =
  info args
  fl.file.flushFile()

var settings = newSettings()
if existsEnv("PORT"):
  settings.port = Port(parseInt(getEnv("PORT")))

routes:
  get "/":
    resp h.h1("Hello myservice!!!")

when isMainModule:
  log_info "starting"
  runForever()