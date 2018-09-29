import json
import matrix
import os
import strutils
import tables

import modules/load

const CONFIGFILE = "config.json"

proc readConfig(): JsonNode = parseFile(CONFIGFILE)

proc run() =
  let config = readConfig()
  var connection: Matrix = createMatrix(config)
  connection.login()
  connection.join()
  connection.postMessageFilter()
  discard connection.sync()  # initial sync - ignore

  while true:
    let
      data: JsonNode = connection.sync()
      messages: seq[Message] = connection.extractMessages(data)

    for msg in messages:
      for fn in allFunctions:
        let reply = fn(msg)

        if len(reply) > 0:
          connection.sendMessage(reply)

    sleep(3000)  # 3 sec

when isMainModule:
  run()
