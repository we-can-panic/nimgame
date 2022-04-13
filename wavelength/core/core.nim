##[
  front/backの共通type/処理
]##

import json, random

randomize()

type
  ApiSend* = enum
    ##[
      Kind of API for send from client (Front -> Back)
    ]##
    Join
    Id
    Status
    Dial1 = "Dial"
    Dialed

  ApiReceive* = enum
    ##[
      Kind of API for send from server (Back -> Send)
    ]##
    Users
    Id2 = "Id"
    Host
    Range1 = "Range"
    Theme
    Dial2 = "Dial"
    Score
    End

  UserStatus* = enum
    ##[
      Kind of user's status for game start
      - Standby: 例えば、ユーザがそろっていない場合など
      - Active: 全ユーザーがこのステータスになったらゲーム開始
      - Nil: 未決定
    ]##
    Standby
    Active
    Nil

  Room* = enum
    ##[
      Kind of room that user in
      - Login: 名前決めなど
      - Wait: 他のユーザの待機中（Standby）
      - Game: ゲーム中
      - Nil: 未決定
    ]##
    Login
    Wait
    Game
    Nil2 = "Nil"

  User* = ref object of RootObj
    ##[
      user object
      - id: user's identifier
      - name: user's displayname
      - status: refer to `UserStatus`
      - room: refer to `Room`
    ]##
    id*: string
    name*: string
    status*: UserStatus
    room*: Room

  Range* = ref object
    ##[
      range object to calculate score
      - pt1: if pt1[0] < dial < pt1[1] : score is 1
      - pt2: if pt2[0] < dial < pt2[1] : score is 2 (pliority over pt1)
      - pt3: if pt3[0] < dial < pt3[1] : score is 3 (pliority over pt2)
      - pt4: if pt4[0] < dial < pt4[1] : score is 4 (pliority over pt3)
      
      score range example:
        |--0--|--1--|--2--|--3--|--4--|--3--|--2--|--1--|--0--|
    ]##
    pt1*, pt2*, pt3*, pt4*: array[0..1, Dial]

  Dial* = range[1..100]
    ##[
      range of dial ( dial is the value 1..100 that users adjustsed )
    ]##


proc newUser* (name: string, status=Standby, room=Wait): User
  ##[
    generate new User object
  ]##

proc generateRange* (): Range
  ##[
    generate new Range object by suitable value
  ]##

proc newDial* (n: int): Dial
  ##[
    generate new Dial object from int
  ]##

proc newDial[I, int](s: array[I, int]): array[I, Dial]
  ##[
    generate new Dial object from array[int] (for `generateRange`)
  ]##

proc calc* (r: Range, d: Dial): int
  ##[
    get score of Dial from Range
  ]##

proc parsePacket* (pkt: string): (bool, JsonNode)
  ##[
    parse websocket message
    ApiSend / ApiReceive are usable this proc
  ]##


proc calc* (r: Range, d: Dial): int =
  # calc point
  result =
    if r.pt4[0] <= d and d <= r.pt4[1]: 4
    elif r.pt3[0] <= d and d <= r.pt3[1]: 3
    elif r.pt2[0] <= d and d <= r.pt2[1]: 2
    elif r.pt1[0] <= d and d <= r.pt1[1]: 1
    else: 0

proc newUser* (name: string, status=Standby, room=Wait): User =
  result.name = name
  result.status = status
  result.room = room

proc newDial(n: int): Dial =
  result = 
    if n in 1..100: n
    elif n<1: 1
    else: 100

proc newDial[I, int](s: array[I, int]): array[I, Dial] =
  for i in s.low..s.high:
    result[i] = newDial(s[i])

proc generateRange* (): Range =
  let
    ini = rand(1..100)
    pt4 = [ini, ini+5]
    pt3 = [ini-5, ini+10]
    pt2 = [ini-10, ini+15]
    pt1 = [ini-15, ini+20]
  result = Range(pt1: newDial(pt1), pt2: newDial(pt2), pt3: newDial(pt3), pt4: newDial(pt4))

proc parsePacket* (pkt: string): (bool, JsonNode) =
  try:
    result[0] = true
    result[1] = parseJson(pkt)
  except JsonParsingError:
    result[0] = false
    result[1] = %* {}
