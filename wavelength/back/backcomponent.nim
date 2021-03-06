##[
  back.nimで使用するAPIの処理など
]##

import json, strutils, sequtils, sugar, random, parsecsv
import jester, ws, ws/jester_extra

import ../../general/logutils
import ../core/core

randomize()

type
  WSUser* = ref object of User
    conn*: WebSocket
    dialed*: bool
    ##[
      User object for backend.
      user:
        id: string
        name: string
        status: UserStatus
        room: Room
    ]##
  Board* = ref object
    dial* : Dial
    ranges* : Range
    theme* : array[0..1, string]
    ##[
      board object
    ]##

var
  currentUsers* {.threadvar.} : seq[WSUser]
  ## connecting users list
  hostUserId* : string
  ## host user's id
  board* = Board(
            dial: newDial(1),
            ranges: generateRange(),
            theme: ["", ""])


# proc for make object
proc newUser* (ws: WebSocket): WSUser
## create new user from websocket

# util procs(regist)
#[
  query -> user -> currentUsers
  1. parse query
  2. set query's params to user (addParam)
  3. set user's params to currentUsers (save)
    (if user not registed to currentUsers, add user to currentUsers (regist))
]#
proc regist* (user: WSUser)
## add user to `currentUsers`
proc addParam* (user: var WSUser, query: JsonNode)
## add name, status, room in query to user
proc save* (user: WSUser)
## add user's status to user in currentUsers

# utils procs(info)
proc isExists* (user: WSUser): bool
## check `currentUsers` is including this user
proc exportUsers* (): seq[JsonNode]
## List current users for Api `Users`
proc searchUserFromId(id: string): WSUser
## search from currentUsers

# api core
proc send* (user: WSUser, msg: string)
## send query to user
proc send* (users: seq[WSUser], msg: string)
## send query to some users
proc sendAll* (msg: string)
## send query to all users

# api
proc sendId* (user: WSUser)
## share user's id to requested user
proc sendUsers* ()
## share current user's status to all
proc sendHost* ()
## share host user to all
proc sendRange* ()
## share board's range to host
proc sendTheme* ()
## share theme to all
proc sendDial* ()
## share dial's value to all
proc sendScore* ()
## share board/dial's info to all


proc newUser(ws: WebSocket): WSUser =
  ## create new user from websocket
  result = WSUser()
  result.id = ws.key
  result.status = Nil # init value
  result.room = Nil2
  result.dialed = false
  result.conn = ws

proc regist(user: WSUser) =
  ## join user to `currentUsers`
  currentUsers.add(user)

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
  if query.hasKey("dialed"):
    user.dialed = query["room"].getBool


proc save(user: WSUser) =
  if user.isExists:
    let curUsersNum = currentUsers.mapIt(it.id).find(user.id)
    if user.name!="":
      currentUsers[curUsersNum].name = user.name
    if user.status!=Nil:
      currentUsers[curUsersNum].status = user.status
    if user.room!=Nil2:
      currentUsers[curUsersNum].room = user.room

proc isExists(user: WSUser): bool =
  ## judge `currentUsers` is including this user
  result = currentUsers.mapIt(it.id).contains(user.id)

proc exportUsers(): seq[JsonNode] =
  ## List current users for Api `Users`
  for user in currentUsers:
    if user.conn.readyState == Open:
      result.add( %* {
        "name": user.name,
        "status": $user.status,
        "id": user.id,
        "room": $user.room
      })

proc searchUserFromId(id: string): WSUser =
  let idx = currentUsers.mapIt(it.id).find(id)
  result = currentUsers[idx]

proc send(user: WSUser, msg: string) =
  ## send query to user
  let conn = user.conn
  if conn.readyState == Open:
    logInfo "SEND " & msg
    asyncCheck conn.send(msg)

proc send(users: seq[WSUser], msg: string) =
  ## send query to some users
  for usr in users:
    usr.send(msg)

proc sendAll(msg: string) =
  ## semd query tp all users
  send(currentUsers, msg)

proc sendId(user: WSUser) =
  let usersquery = %* {
    "type": $Id2,
    "id": user.id
  }
  user.send($usersquery)

proc sendUsers() =
  let
    userlist = exportUsers()
    usersquery = %* {
      "type": $Users,
      "users": userlist
    }
  sendAll($usersquery)

proc sendHost() = # Todo
  let
    host = currentUsers.sample
    query = %* {"type": $Host, "user": host.name}
  hostUserId = host.id
  sendAll($query)

proc sendRange() = # Todo
  board.ranges = generateRange()
  let
    query = %* {
      "type": $Range1,
      "1": board.ranges.pt1,
      "2": board.ranges.pt2,
      "3": board.ranges.pt3,
      "4": board.ranges.pt4
    }
    host = searchUserFromId(hostUserId)
  host.send($query)

proc sendTheme() = # Todo
  let
    themes = block:
      var p: CsvParser
      defer: p.close()
      p.open("themes.csv")
      var res: seq[seq[string]]
      while p.readRow():
        res.add(p.row)
      res

    theme = themes.sample


    query = %* {"type": $Theme, "theme1": theme[0], "theme2": theme[1]}
    host = searchUserFromId(hostUserId)
  board.theme = [theme[0], theme[1]]
  host.send($query)

proc sendDial() =
  let usersquery = %* {
    "type": $Dial2,
    "value": board.dial
  }
  sendAll($usersquery)

proc sendScore() =
  let query = %* {
    "type": $Score,
    "range": {
      "1": board.ranges.pt1,
      "2": board.ranges.pt2,
      "3": board.ranges.pt3,
      "4": board.ranges.pt4
    },
    "dial": {
      "value": board.dial
    }
  }
  currentUsers.send($query)
