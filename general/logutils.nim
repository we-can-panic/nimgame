#[
  logging
]#
import logging, posix, strutils


when defined(c):
  let fl = newFileLogger("logs.log", fmtStr="$datetime $levelname ")


proc logError* (args: varargs[string, `$`]) =
  echo "ERROR:\t" & args.join("")
  when defined(c):
    error args
    fl.file.flushFile()

proc logDebug* (args: varargs[string, `$`]) =
  echo "DEBUG:\t" & args.join("")
  when defined(c):
    debug args
    fl.file.flushFile()

proc logInfo* (args: varargs[string, `$`]) =
  echo "INFO :\t" & args.join("")
  when defined(c):
    info args
    fl.file.flushFile()

when defined(c):
  onSignal(SIGABRT):
    echo "<2>Received SIGABRT"
    quit(1)

  fl.addHandler