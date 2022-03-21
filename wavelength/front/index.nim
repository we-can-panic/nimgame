#[
  描画/通信
]#

import json, jsffi, strutils
include karax/prelude
import karax / [kdom, vdom, karax, karaxdsl, jstrutils, compact, localstorage, vstyles]
import karax/jwebsockets
import ../core/core

# WebSocket Part #
const
  test = true
  url =
    when test: "ws://localhost:5000/wavelength/ws"
    else:      "ws://khc-nimgame.herokuapp.cpm/wavelength/ws"

var
  user = new User
  ws = newWebSocket(url)
  otherUsers: seq[User]

ws.onmessage = proc(ev: MessageEvent) =
  var (res, query) = parsePacket($ev.data)
  if not res:
    echo "jsonparseError"
    return
  if not query.hasKey("type"):
    echo "Invalid api format: " & $query
    return
  echo "got: "
  echo query

  var apiType = parseEnum[ApiReceive](query["type"].getStr)
  case apiType:
  of Users:
    discard
  of Id2:
    discard
  of Host:
    discard
  of Range1:
    discard
  of Theme:
    discard
  of Dial2:
    discard
  of Score:
    discard
  of End:
    discard

proc send(apitype: ApiSend, query: JsonNode) =
  var typedQuery = query
  typedQuery["type"] = %* $apitype
  ws.send($typedQuery)
  echo "send: " & $typedQuery

proc sendJoin() =
  ## send request Join
  var name = $getElementById("login-input").value
  send(Join, %* {"name": name})

# HTML Part #
proc createHtml* (): VNode =
  buildHtml html(lang="ja"):
    head:
      meta(charset="UTF-8")
      title:
        text "NIMGAME"
    body:
      case user.room:
      of Login:
        tdiv():
          h1: text "wavelength"
          h2: text "Login"
          input(`type`="text", id="login-input")
          p()
          button:
            text "Enter"
            proc onclick(ev: Event, n: VNode) =
              sendJoin()
      of Wait:
        discard
      of Game:
        discard


setRenderer createHtml