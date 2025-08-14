import std/[tables, monotimes, times, importutils, strutils, sequtils, sets]
from std/sets import HashSet, initHashSet, contains, len, items, incl, excl, clear
import pkg/threading/channels
import pkg/[flatty, netty, pretty]
import flatty/binny
export times except seconds
export
  tables, monotimes, importutils, strutils, sequtils, channels, flatty, pretty,
  sets

export netty except Message

proc to_flatty*[T](s: HashSet[T]): string =
  result.addInt64(s.card.int64)
  for item in s:
    result.toFlatty(item)

proc from_flatty*[T](s: var HashSet[T], data: string) =
  var i = 0
  let len = data.readInt64(i).int
  i += 8
  s.clear()
  for j in 0 ..< len:
    var item: T
    data.fromFlatty(i, item)
    s.incl(item)

proc to_hash_set*[T](s: seq[T]): HashSet[T] =
  for item in s:
    result.incl(item)
