import httpclient
import json
import options
import tables
import strformat
import strutils
from unicode import toLower
from uri import encodeUrl

type
  ParamT = TableRef[string, string]

  Matrix* = ref object of RootObj
    config: JsonNode
    client: HttpClient
    userID: string
    roomID: string
    accessToken: string
    nextBatch: string
    filterID: string
    txId: int

  Message* = tuple[body: string, sender: string, eventID: string]

let NULLJSON*: JsonNode = %*{}

# Getters for Matrix config (from JSON), see spec/json file for details

proc username*(self: Matrix): string =
  self.config["username"].getStr

proc password*(self: Matrix): string =
  self.config["password"].getStr

proc address*(self: Matrix): string =
  self.config["address"].getStr

proc room*(self: Matrix): string =
  self.config["room"].getStr

# Other procedures

proc createMatrix*(config: JsonNode): Matrix =
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  Matrix(config: config, client: client)

proc makeParams(params: Option[ParamT]): string =
  if params.isNone:
    return ""

  for k, v in params.get:
    result &= &"{k}={v}&"
  result.strip(chars={'&'})

proc buildUrl(self: Matrix, endpoint: string, params: Option[ParamT],
              version: string): string =
  var
    url = &"{self.address}/_matrix/client/{version}/{endpoint}"
    concat = '?'

  let paramString = makeParams(params)
  if len(paramString) > 0:
    url &= &"?{paramString}"
    concat = '&'

  if len(self.accessToken) > 0:
    url &= &"{concat}access_token={self.accessToken}"

  return url

proc extractMessages*(self: Matrix, data: JsonNode): seq[Message] =
  let roomData: JsonNode = data["rooms"]["join"]
  if self.roomID in roomData:
    let events: JsonNode = roomData[self.roomID]["timeline"]["events"]
    for e in events:
      if "body" in e["content"]:
        result.add((e["content"]["body"].getStr.toLower,
                    e["sender"].getStr,
                    e["event_id"].getStr,
                    ))

# REST procedures

proc POST(self: Matrix, endpoint: string, data: JsonNode,
          params: Option[ParamT] = none(ParamT),
          version: string = "unstable"): JsonNode =
  let url: string = self.buildUrl(endpoint, params, version)
  let response: Response = self.client.request(url,
                                               httpMethod=HttpPost,
                                               body = $data)
  return response.body.parseJson

proc GET(self: Matrix, endpoint: string, params: Option[ParamT] = none(ParamT),
         version: string = "unstable"): JsonNode =
  let url: string = self.buildUrl(endpoint, params, version)
  let response: Response = self.client.request(url,
                                               httpMethod=HttpGet)
  return response.body.parseJson

proc PUT(self: Matrix, endpoint: string, data: JsonNode,
         params: Option[ParamT] = none(ParamT),
         version: string = "unstable"): JsonNode =
  let url: string = self.buildUrl(endpoint, params, version)
  let response: Response = self.client.request(url,
                                               httpMethod=HttpPut,
                                               body = $data)
  return response.body.parseJson

# Endpoints

proc login*(self: var Matrix) =
  let data = %*{
    "user": self.username,
    "password": self.password,
    "type": "m.login.password",
  }
  let response: JsonNode = self.POST("login", data)
  self.accessToken = response["access_token"].getStr
  self.userID = response["user_id"].getStr

proc join*(self: var Matrix) =
  let response: JsonNode = self.POST(&"join/{encodeUrl(self.room)}", NULLJSON)
  self.roomID = response["room_id"].getStr

proc postMessageFilter*(self: var Matrix) =
  let data = %*{
    "account_data": {"types": ["m.room.message"]},
    "room": {"rooms": [self.roomID]},
  }
  let response: JsonNode = self.POST(&"user/{self.userID}/filter", data)
  self.filterID = response["filter_id"].getStr

proc sync*(self: var Matrix): JsonNode =
  var params: Option[ParamT] = some[ParamT]({
    "filter": self.filterID,
  }.newTable)

  if len(self.nextBatch) > 0:
    params.get["since"] = self.nextBatch

  let response: JsonNode = self.GET("sync", params)
  self.nextBatch = response["next_batch"].getStr

  return response

proc sendMessage*(self: var Matrix, message: string, mType: string = "m.text") =
  let data = %*{
    "body": message,
    "msgtype": mType,
  }
  discard self.PUT(&"rooms/{self.roomID}/send/m.room.message/{self.txId}", data)
  self.txId += 1

proc markRead*(self: Matrix, msg: Message) =
  let data = %*{
    "m.fully_read": msg.eventID,
    "m.read": msg.eventID,
  }
  discard self.POST(&"rooms/{self.roomID}/read_markers", data)
