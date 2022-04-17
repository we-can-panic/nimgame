##[
  front.nimで使用するAPIの処理など
]##

import json, jsffi, strutils
include karax/prelude
import karax / [kdom, vdom, karax, karaxdsl, jstrutils, compact, localstorage, vstyles]
import karax/jwebsockets

import ../../general/logutils
import ../core/core

# WebSocket Part #
const url* = block:
        const test = true
        when test: "ws://localhost:5000/wavelength/ws"
        else:      "ws://khc-nimgame.herokuapp.cpm/wavelength/ws"

var
  user* = new User
  ws* = newWebSocket(url)
  otherUsers* : seq[User]

# utils procs
proc send* {.deplecated.} (apitype: ApiSend, query: JsonNode = %* {})
## send to server
proc send * (query: string)
proc pretty* (user: User): string
## convert user: User -> JsonNode -> string

# API
proc sendJoin* ()
## send request Join
proc sendId* ()
## send req. Id
proc sendStatus* ()
## send req. Status
proc sendDial* ()
## send req. Dial
proc sendDialed* ()
## send req. Dialed


proc send(apitype: ApiSend, query: JsonNode) =
  var typedQuery = query
  typedQuery["type"] = %* $apitype
  logInfo "SEND " & $typedQuery
  ws.send($typedQuery)

proc send(query: string) =
  logInfo "SEND " & query
  ws.send(query)

proc pretty* (user: User): string =
  let js = %* {
      "id": user.id,
      "name": user.name,
      "status": $user.status,
      "room": $user.room
    }
  result = js.pretty()

proc sendJoin() =
  ## send request Join
  let
    name = $getElementById("login-input").value
    query = %* {
      "type": $Join,
      "name": name
    }
  send($query)

proc sendId() =
  send($(%* {"type": $Id}))

proc sendStatus() =
  let query = %* {"type": $Status, "status": $user.status}
  send($query)

proc sendDial() =
  let
    id = "game-dial-input"
    dial = $getElementById(id).value.parseInt
    query = %* {"type": $Dial1, "value": dial}
  send($query)

proc sendDialed() =
  send($(%* {"type": $Dialed}))