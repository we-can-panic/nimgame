#[
  front/backの共通type/処理
]#

import json

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
    pt1, pt2, pt3, pt4: array[0..1, 1..100]

  Dial* = range[1..100]


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

proc parsePacket* (pkt: string): (bool, JsonNode) =
  try:
    result[0] = true
    result[1] = parseJson(pkt)
  except JsonParsingError:
    result[0] = false
    result[1] = %* {}
