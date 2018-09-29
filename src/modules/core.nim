import strutils
from ../matrix import Message

proc greet(msg: Message): string =
  if "hello bot" in msg.body:
    result = "hello from module"

const functions* = {"greet": greet}
