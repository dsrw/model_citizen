import std / [strformat, strutils, sequtils, sets, tables, times, monotimes,
    sugar, options, sets]

import pkg / [print, flatty, nanoid]
export dup, collect, strformat, strutils, sequtils, sets, tables

### Logic ###

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

### Ids ###

proc generate_id*(): string =
  generate(alphabet = "abcdefghijklmnopqrstuvwxyz0123456789", size = 13)
