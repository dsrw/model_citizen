import std/[tables, monotimes, times, importutils, strutils, sequtils, sets]
from std/sets import HashSet, initHashSet, contains, len, items, incl, excl, clear
import pkg/threading/channels
import pkg/[flatty, netty, pretty]
export times except seconds
export
  tables, monotimes, importutils, strutils, sequtils, channels, flatty, pretty,
  sets, HashSet, initHashSet

export netty except Message

proc to_flatty*[T](s: HashSet[T]): string =
  var data: seq[T]
  for item in s:
    data.add(item)
  data.to_flatty

proc from_flatty*[T](s: var HashSet[T], data: string) =
  var temp_seq: seq[T]
  temp_seq.from_flatty(data)
  s = initHashSet[T]()
  for item in temp_seq:
    s.incl(item)

proc to_hash_set*[T](s: seq[T]): HashSet[T] =
  result = initHashSet[T]()
  for item in s:
    result.incl(item)
