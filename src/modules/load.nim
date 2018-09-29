import sugar
import core as core
from ../matrix import Message

let allFunctions* = lc[ fn[1] | (fn <- core.functions), proc(msg: Message): string]
