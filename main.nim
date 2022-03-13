#[
  main
    - rounting
]#
import os, asyncdispatch, strutils
import jester

import general/logutils
import wavelength/back/back as wl


let settings = newSettings()
if existsEnv("PORT"):
  settings.port = Port(parseInt(getEnv("PORT")))

routes:
  get "/":
    resp "<h1>Hello myservice!!!</h1>"
  get "/wavelength":
    resp "<html><head></head><body>hello</body></html>"
  get "/wavelength/ws":
    await wl.onRequest(request)
    resp "WebSocket Only"

when isMainModule:
  log_info "starting"
  runForever()