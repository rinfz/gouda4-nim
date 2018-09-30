import httpclient
import json
import strformat
import strutils
import uri

from ../matrix import Message


proc ddg*(msg: Message): string =
  if "what is" in msg.body:
    let
      client = newHttpClient()
      query: string = encodeUrl(msg.body[msg.body.find("what is")..^1])
      response = client.getContent(
        &"https://api.duckduckgo.com/?q={query}&format=json&no_html=1"
      )
      data = parseJson(response)

    if "AbstractText" in data:
      let txt = data["AbstractText"].getStr
      if len(txt) > 0:
        result = txt

const functions* = {
  "ddg": ddg,
}
