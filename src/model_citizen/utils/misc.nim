import std / [options, sets, macrocache, strformat, strutils, times, monotimes]
import pkg / [nanoid]

# Logic

proc intersects*[T](self: set[T], other: set[T]): bool =
  for value in self:
    if value in other:
      return true

template `?`*(self: ref): bool = not self.is_nil
template `?`*(self: object): bool = self != self.type.default
template `?`*[T](option: Option[T]): bool = option.is_some
template `?`*(self: SomeNumber): bool = self != 0
template `?`*(self: string): bool = self != ""
template `?`*[T](self: open_array[T]): bool = self.len > 0
template `?`*[T](self: set[T]): bool = self.card > 0
template `?`*[T](self: HashSet[T]): bool = self.card > 0

# Ids

proc generate_id*(): string =
  generate(alphabet = "abcdefghijklmnopqrstuvwxyz0123456789", size = 13)

# Exceptions

proc init*[T: Exception](kind: type[T], message: string, parent:
    ref Exception = nil): ref Exception =

  (ref kind)(msg: message, parent: parent)

# General

# Workaround for templates not supporting {.discardable.}
proc make_discardable*[T](self: T): T {.discardable, inline.} = self

template `\`*(s: string): string =
  var f = fmt(s)
  f.remove_prefix("\n")
  f.remove_suffix(' ')
  f.remove_suffix("\n\n")
  f

const type_id = CacheCounter"type_id"

func tid*(T: type): int =
  const id = type_id.value
  static:
    inc type_id
  id

proc seconds*(s: float): Duration {.inline.} =
  init_duration(milliseconds = int(s * 1000))
