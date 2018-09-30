import tables
import sugar
import core as core
import ddg as ddg
from ../matrix import Message

var
  funcTable: TableRef[string, proc (msg: Message): string] =
    newTable[string, proc (msg: Message): string]()

for fn in core.functions:
  funcTable[fn[0]] = fn[1]

for fn in ddg.functions:
  funcTable[fn[0]] = fn[1]

let allFunctions* = lc[ fn | (fn <- funcTable.values), proc(msg: Message): string]
