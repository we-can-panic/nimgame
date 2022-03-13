#[
  logging
]#
import logging, posix, strutils


let fl = newFileLogger("logs.log", fmtStr="$datetime $levelname ")


proc logError* (args: varargs[string, `$`]) =
  echo "ERROR:\t" & args.join("")
  error args
  fl.file.flushFile()

proc logDebug* (args: varargs[string, `$`]) =
  echo "DEBUG:\t" & args.join("")
  debug args
  fl.file.flushFile()

proc logInfo* (args: varargs[string, `$`]) =
  echo "INFO :\t" & args.join("")
  info args
  fl.file.flushFile()


onSignal(SIGABRT):
  echo "<2>Received SIGABRT"
  quit(1)

fl.addHandler