#[
  描画/通信
]#

import json, jsffi, strutils

include karax/prelude
import karax / [kdom, vdom, karax, karaxdsl, jstrutils, compact, localstorage, vstyles]
import karax/jwebsockets

import ../../general/logutils
import ../core/core
import indexcomponent


ws.onmessage = proc(ev: MessageEvent) =
  let (res, query) = parsePacket($ev.data)
  if not res:
    logInfo "jsonparseError"
    return

  logInfo "GOT ", $query

  if not query.hasKey("type"):
    logInfo "Invalid api format: " & $query
    return

  let
    apiType = block:
      try:
        parseEnum[ApiReceive](query["type"].getStr)
      except ValueError:
        logInfo("Invalid ApiReceive: ", query["type"].getStr)
        return

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

# HTML Part #
proc createHtml* (): VNode =
  buildHtml html(lang="ja"):
    head:
      meta(charset="UTF-8")
      title:
        text "NIMGAME"
    body:
      case user.room:
      of Login, Nil2:
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
        input(`type`="number", id="game-dial-input")


setRenderer createHtml