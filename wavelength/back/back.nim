#[
  WebSocketの処理
]#

import json, strutils, sequtils
import jester, ws, ws/jester_extra

import ../../general/logutils
import ../core/core

type
  # 接続中のユーザー
  WSUser = ref object of User
    conn: WebSocket

var currentUsers {.threadvar.} : seq[WSUser]
## connecting users

proc newUser(ws: WebSocket): WSUser
## create new user from websocket
proc isExists(user: WSUser): bool
## judge `currentUsers` is including this user
proc regist(user: WSUser)
## join user to `currentUsers`
proc exportUsers(): seq[JsonNode]
## List current users for Api `Users`
proc send(user: WSUser, msg: string)
## send query to user
proc send(users: seq[WSUser], msg: string)
## send query to some users
proc sendAll(msg: string)
## send query to all users


proc onRequest* (request: Request) {.async.} =
  try:
    var ws = await newWebSocket(request)
    var user = newUser(ws)
    while ws.readyState == Open:
      var
        msg = await ws.receiveStrPacket()
        (res, query) = parsePacket(msg)

      if not res:
        logInfo "jsonparseError"
        continue

      logInfo "GOT ", $query

      if not query.hasKey("type"):
        loginfo "Invalid api format: " & $query
        continue

      var apiType = parseEnum[ApiSend](query["type"].getStr)
      case apiType:
      of Join:
        user.name = query["name"].getStr
        if not user.isExists:
          regist(user)
        let
          userlist = exportUsers()
          usersquery = %* {
            "type": $Users,
            "users": userlist
          }
        sendAll($usersquery)

      of Status:
        discard
      of Dial1:
        discard
      of Dialed:
        discard

  except JsonParsingError:
    logDebug "Json invalid: " & getCurrentExceptionMsg()
  except WebSocketClosedError:
    logInfo "Socket closed."
  except WebSocketProtocolMismatchError:
    logError "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  except WebSocketError:
    logError "Unexpected socket error: ", getCurrentExceptionMsg()




proc newUser(ws: WebSocket): WSUser =
  ## create new user from websocket
  result = WSUser()
  result.id = ws.key
  result.conn = ws

proc isExists(user: WSUser): bool =
  ## judge `currentUsers` is including this user
  result = currentUsers.mapIt(it.id).contains(user.id)

proc regist(user: WSUser) =
  ## join user to `currentUsers`
  currentUsers.add(user)

proc exportUsers(): seq[JsonNode] =
  ## List current users for Api `Users`
  for user in currentUsers:
    if user.conn.readyState == Open:
      result.add( %* {
        "name": user.name,
        "status": $user.status,
        "id": user.id
      })

proc send(user: WSUser, msg: string) =
  ## send query to user
  let conn = user.conn
  if conn.readyState == Open:
    asyncCheck conn.send(msg)

proc send(users: seq[WSUser], msg: string) =
  ## send query to some users
  for usr in users:
    usr.send(msg)

proc sendAll(msg: string) =
  ## semd query tp all users
  send(currentUsers, msg)
