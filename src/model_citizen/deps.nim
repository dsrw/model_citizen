import std/[tables, monotimes, times, importutils, strutils, sequtils, sets]
import pkg/threading/channels
import pkg/[flatty, netty, pretty]
import flatty/binny
export times except seconds
export
  tables, monotimes, importutils, strutils, sequtils, channels, flatty, pretty,
  sets

export netty except Message

# Ensure HashSet iterator is available (fix for iterator conflict)

proc to_flatty*[T](s: HashSet[T]): string =
  result.add_int64(s.card.int64)
  for item in sets.items(s):
    result.to_flatty(item)

proc from_flatty*[T](s: var HashSet[T], data: string) =
  var i = 0
  let len = data.read_int64(i).int
  i += 8
  s.clear()
  for j in 0 ..< len:
    var item: T
    data.from_flatty(i, item)
    s.incl(item)

proc to_hash_set*[T](s: seq[T]): HashSet[T] =
  for item in s:
    result.incl(item)

proc to_hash_set*[T](s: set[T]): HashSet[T] =
  for item in s:
    result.incl(item)

proc `==`*[T](hs: HashSet[T], s: set[T]): bool =
  hs == s.to_hash_set

proc `==`*[T](s: set[T], hs: HashSet[T]): bool =
  s.to_hash_set == hs

