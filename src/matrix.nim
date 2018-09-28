import httpclient
import json
import options
import tables
import strformat
import strutils

type
  ParamT = TableRef[string, string]
  Matrix* = ref object of RootObj
    config: JsonNode
    client: HttpClient
    userID: string
    roomID: string
    accessToken: string
    nextBatch: string
    filter: string
    txId: int

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
  var url = &"{self.address}/_matrix/client/{version}/{endpoint}"
  if len(self.accessToken) > 0:
    params.get["access_token"] = self.accessToken

  let paramString = makeParams(params)
  if len(paramString) > 0:
    url &= &"?{paramString}"

  return url

# REST procedures

proc POST(self: Matrix, endpoint: string, data: JsonNode,
          params: Option[ParamT] = none(ParamT),
          version: string = "unstable"): JsonNode =
  let url: string = self.buildUrl(endpoint, params, version)
  let response: Response = self.client.request(url,
                                               httpMethod=HttpPost,
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
