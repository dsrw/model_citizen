import std / [strformat, strutils, sequtils, sets, tables, times, monotimes,
    sugar, options, sets]

import pkg / [print, flatty]
export dup, collect, strformat, strutils, sequtils, sets, tables

proc intersects*[T](self: set[T], other: set[T]): bool =
  for value in self:
    if value in other:
      return true

proc `?`*(self: ref): bool = not self.is_nil
proc `?`*(self: object): bool = not self == self.type.default
proc `?`*[T](option: Option[T]): bool = option.is_some
proc `?`*(self: SomeNumber): bool = self != 0
proc `?`*(self: string): bool = self != ""
proc `?`*[T](self: open_array[T]): bool = self.len > 0
proc `?`*[T](self: set[T]): bool = self.card > 0
proc `?`*[T](self: HashSet[T]): bool = self.card > 0
