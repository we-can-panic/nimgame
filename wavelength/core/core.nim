#[
  front/backの共通type/処理
]#

import json, random

randomize()

type
  ApiSend* = enum
    Join
    Id
    Status
    Dial1 = "Dial"
    Dialed

  ApiReceive* = enum
    Users
    Id2 = "Id"
    Host
    Range1 = "Range"
    Theme
    Dial2 = "Dial"
    Score
    End

  UserStatus* = enum
    Standby
    Active

  Room* = enum
    Login
    Wait
    Game

  User* = ref object of RootObj
    id*: string
    name*: string
    status*: UserStatus
    room*: Room

  Range* = ref object
    pt1*, pt2*, pt3*, pt4*: array[0..1, Dial]

  Dial* = range[1..100]


proc newUser* (name: string, status=Standby, room=Wait): User
##[
  generate new User object
]##

proc generateRange* (): Range
##[
  generate new Range object by suitable value
]##

proc newDial(n: int): Dial
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
    pt1 = [ini, ini+5]
    pt2 = [ini-5, ini+10]
    pt3 = [ini-10, ini+15]
    pt4 = [ini-15, ini+20]
  result = Range(pt1: newDial(pt1), pt2: newDial(pt2), pt3: newDial(pt3), pt4: newDial(pt4))

proc parsePacket* (pkt: string): (bool, JsonNode) =
  try:
    result[0] = true
    result[1] = parseJson(pkt)
  except JsonParsingError:
    result[0] = false
    result[1] = %* {}
