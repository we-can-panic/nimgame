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
proc send* (apitype: ApiSend, query: JsonNode = %* {})
## send to server
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
  var name = $getElementById("login-input").value
  send(Join, %* {"name": name})

proc sendId() =
  discard

proc sendStatus() =
  discard
proc sendDial() =
  discard
proc sendDialed() =
  discard