import random
import strutils
import sugar
from ../matrix import Message

const letters = lc[ x | (x <- {'a'..'z'}), char]

proc greet(msg: Message): string =
  if "hello bot" in msg.body:
    result = "hello from module"

proc acronym(msg: Message): string =
  if msg.body.startsWith("!acronym"):
    for _ in 1..5:
      result &= rand(letters)

const functions* = {
  "greet": greet,
  "acronym": acronym,
}
