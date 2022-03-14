#[
  描画/通信
]#

import json, jsffi
include karax/prelude
import karax/jwebsockets

# WebSocket Part #
const
  test = true
  url =
    when test: "ws://localhost:5000/wavelength/ws"
    else:      "ws://khc-nimgame.herokuapp.cpm/wavelength/ws"

var ws = newWebSocket(url)

ws.onmessage = proc(ev: MessageEvent) =
  echo "receive: ", ev.data

proc send() =
  var query = %* {"type": "Join", "name": "ffff"}
  ws.send($query)
  echo "send: " & $query


# HTML Part #
proc createHtml* (): VNode =
  buildHtml html(lang="ja"):
    head:
      meta(charset="UTF-8")
      title:
        text "NIMGAME"
    body:
      h1:
        text "Helllllllo"
        proc onclick(ev: Event, n: VNode) =
          send()

setRenderer createHtml