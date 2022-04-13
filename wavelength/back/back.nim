#[
  WebSocketの処理
]#

import json, strutils, sequtils, sugar
import jester, ws, ws/jester_extra

import ../../general/logutils
import ../core/core
import backcomponent

proc onRequest* (request: Request) {.async.} =
  try:
    var
      ws = await newWebSocket(request)
      user = newUser(ws)

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

      let
        apiType = block:
          try:
            parseEnum[ApiSend](query["type"].getStr)
          except ValueError:
            logInfo("Invalid ApiSend: ", query["type"].getStr)
            return

      case apiType:
      of Join:
        # add the user to currentUsers / send currentUsers to all users
        if user.isExists:
          continue
        user.addParam(query)
        user.regist()
        sendUsers()
      of Id:
        # send id to the user who sent the api
        user.sendId()
      of Status:
        # change to sent status / send currentUsers to all users / start game if all users are active.
        if not user.isExists:
          continue
        user.addParam(query)
        user.save()
        if currentUsers.all(it => it.status==Active):
          currentUsers.apply(proc(it: var WSUser) = it.room = Game)
        sendUsers()
      of Dial1:
        if query.hasKey("value"):
          board.dial = newDial(query["value"].getInt(1))
        sendDial()
      of Dialed:
        if not user.isExists:
          continue
        user.dialed = true
        user.save()
        if currentUsers.all(it => it.dialed):
          sendScore()

  except JsonParsingError:
    logDebug "Json invalid: " & getCurrentExceptionMsg()
  except WebSocketClosedError:
    logInfo "Socket closed."
  except WebSocketProtocolMismatchError:
    logError "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  except WebSocketError:
    logError "Unexpected socket error: ", getCurrentExceptionMsg()


