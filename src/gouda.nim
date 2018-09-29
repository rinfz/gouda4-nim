import json
import matrix
import os
import strutils
import tables

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
      if "hello bot" in msg.body:
        connection.sendMessage("YO WHAT UP (from nim)")

    sleep(3000)  # 3 sec

when isMainModule:
  run()
