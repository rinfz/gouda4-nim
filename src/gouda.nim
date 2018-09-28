import json
import matrix
import tables

const CONFIGFILE = "config.json"

proc readConfig(): JsonNode = parseFile(CONFIGFILE)

proc run() =
  let config = readConfig()
  var connection: Matrix = createMatrix(config)
  connection.login()

when isMainModule:
  run()
