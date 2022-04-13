#[
  WebSocketの処理
]#

import json, strutils, sequtils, sugar
import jester, ws, ws/jester_extra

import ../../general/logutils
import ../core/core

type
  WSUser = ref object of User
    conn: WebSocket
    dialed: bool
    ##[
      user of back
      user:
        id: string
        name: string
        status: UserStatus
        room: Room
    ]##

# global variables
var
  currentUsers {.threadvar.} : seq[WSUser]
  ## connecting users
  dial: Dial
  ranges: Range

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
proc save(user: WSUser)
## save info to currentUsers
proc syncUsers()
## share the status all users
proc addParam(user: var WSUser, query: JsonNode)
## add name, status, room in query to user
proc sendScore(users: seq[WSUser])

proc onRequest* (request: Request) {.async.} =
  try:
    var ws = await newWebSocket(request)
    var user = newUser(ws)
    while ws.readyState == Open:
      let
        msg = await ws.receiveStrPacket()
        (res, query) = parsePacket(msg)

      if not res:
        logInfo "jsonparseError"
        continue

      logInfo "GOT ", $query

      if not query.hasKey("type"):
        logInfo "Invalid api format: " & $query
        continue

      let apiType = block:
        try:
          parseEnum[ApiSend](query["type"].getStr)
        except ValueError:
          logInfo("Invalid ApiSend: ", query["type"].getStr)
          return

      case apiType:
      of Join:
        # add the user to currentUsers / send currentUsers to all users
        user.addParam(query)
        if not user.isExists:
          regist(user)
        syncUsers()
      of Id:
        # send id to the user who sent the api
        let usersquery = %* {
          "type": $Id2,
          "id": user.id
        }
        user.send($usersquery)
      of Status:
        # change to sent status / send currentUsers to all users
        user.addParam(query)
        if user.isExists:
          user.save()
        # start game if all users are active.
        if currentUsers.all(it => it.status==Active):
          currentUsers.apply(proc(it: var WSUser) = it.room = Game)
        syncUsers()
      of Dial1:
        if query.hasKey("value"):
          dial = newDial(query["value"].getInt(1))
        let usersquery = %* {
          "type": $Dial2,
          "value": dial
        }
        sendAll($usersquery)
      of Dialed:
        user.dialed = true
        user.save()
        if currentUsers.all(it => it.dialed):
          currentUsers.sendScore()


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
  result.status = Nil # init value
  result.room = Nil2
  result.dialed = false
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


proc save(user: WSUser) =
  if user.isExists:
    let curUsersNum = currentUsers.mapIt(it.id).find(user.id)
    if user.name!="":
      currentUsers[curUsersNum].name = user.name
    if user.status!=Nil:
      currentUsers[curUsersNum].status = user.status
    if user.room!=Nil2:
      currentUsers[curUsersNum].room = user.room

proc syncUsers() =
  let
    userlist = exportUsers()
    usersquery = %* {
      "type": $Users,
      "users": userlist
    }
  sendAll($usersquery)

proc addParam(user: var WSUser, query: JsonNode) =
  if query.hasKey("name"):
    let name = query["name"].getStr
    if name!="":
      user.name = name
  if query.hasKey("status"):
    try:
      user.status = parseEnum[UserStatus](query["status"].getStr)
    except ValueError:
      logInfo("Invalid status: ", query["status"].getStr)
  if query.hasKey("room"):
    try:
      user.room = parseEnum[Room](query["room"].getStr)
    except ValueError:
      logInfo("Invalid room: ", query["room"].getStr)


proc sendScore(users: seq[WSUser]) =
  let query = %* {
    "type": $Score,
    "range": {
      "1": ranges.pt1,
      "2": ranges.pt2,
      "3": ranges.pt3,
      "4": ranges.pt4
    },
    "dial": {
      "value": dial
    }
  }
  users.send($query)
