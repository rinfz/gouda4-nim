import random
import tables
import strutils
import sugar
from ../matrix import Message

const
  letters: seq[char] = lc[ x | (x <- {'a'..'z'}), char]
  modals: seq[string] = @[
    "can", "could", "may", "might", "shall", "should", "will", "would", "must",
    "ought", "are", "am", "is", "does", "did", "didnt", "didn't", "do", "don't",
    "dont", "was",
  ]
  greetings: seq[string] = @[
    "hi", "hello", "yo", "sup", "howdy", "hey",
  ]
  ynReplies: seq[string] = @[
    # yes
    "yes", "yarp", "ya", "yea", "yeah duh", "yess matey", "m8... yes!!",
    "aye", "yup", "yeh", "indeedy doodly", "affirmitive", "hell yeah",
    "hells to the yeah", "yop", "fuck yeah", "y to the e to the s",
    # no
    "no", "nonononono", "nahh", "fuck that", "nope", "no way!!", "nop",
    "yes... just kidding, no", "seriously?? no man..", "nein", "nuh",
  ]
  laughing: seq[string] = @[
    "lol", "lmao", "lmfao", "😂", "5", "b5", "a5",
  ]

proc greet(msg: Message): string =
  if "hello bot" in msg.body:
    result = rand(greetings)

proc acronym(msg: Message): string =
  if msg.body.startsWith("!acronym"):
    var lim: int = 5
    try:
      let splitStr: string = msg.body.splitWhitespace[1]
      if splitStr.isDigit:
        lim = ($splitStr).parseInt
    except IndexError:
      discard

    for _ in 1..lim:
      result &= rand(letters)

proc yesno(msg: Message): string =
  let splitMsg = msg.body.splitWhitespace
  try:
    if (splitMsg[0] in modals or splitMsg[1] in modals) and msg.body[^1] == '?':
      result = rand(ynReplies)
  except IndexError:
    discard

proc lol(msg: Message): string =
  if "lol" in msg.body or "5" in msg.body:
    if rand(4) == 2:
      result = rand(laughing)

proc rate(msg: Message): string =
  if "rate" in msg.body.splitWhitespace or
      "r8" in msg.body.splitWhitespace:
    result = ($rand(10)) & "/10"

proc nice(msg: Message): string =
  let words = msg.body.splitWhitespace
  if "nice" in words or "sick" in words:
    result = "👌"

const functions* = {
  "greet": greet,
  "acronym": acronym,
  "yesno": yesno,
  "lol": lol,
  "rate": rate,
  "nice": nice,
}
