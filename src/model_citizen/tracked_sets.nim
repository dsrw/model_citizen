import std / [tables]

type
  ChangeCallback*[T] =
    proc(added: set[T], removed: set[T])

  TrackedSet*[T] = object
    flags: set[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, ChangeCallback[T]]

proc contains*[T](self: TrackedSet[T], flag: T): bool =
  flag in self.flags

proc contains*[T](self: TrackedSet[T], flags: set[T]): bool =
  result = true
  for flag in flags:
    if flag notin self:
      return false

proc change*[T](self: var TrackedSet[T], flags: set[T], add: bool) =
  let initial_values = self.flags
  if add:
    self.flags = self.flags + flags
  else:
    self.flags = self.flags - flags
  if self.flags != initial_values:
    let added = self.flags - initial_values
    let removed = initial_values - self.flags
    for _, callback in self.changed_callbacks:
      callback(added, removed)

proc `set=`*[T](self: var TrackedSet[T], flags: set[T]) =
  let initial_values = self.flags
  self.flags = flags
  if self.flags != initial_values:
    let added = self.flags - initial_values
    let removed = initial_values - self.flags
    for _, callback in self.changed_callbacks:
      callback(added, removed)

proc set*[T](self: TrackedSet[T]): set[T] = self.flags

proc `+=`*[T](self: var TrackedSet[T], flag: T) =
  self.change({flag}, true)

proc `+=`*[T](self: var TrackedSet[T], flags: set[T]) =
  self.change(flags, true)

proc `-=`*[T](self: var TrackedSet[T], flag: T) =
  self.change({flag}, false)

proc `-=`*[T](self: var TrackedSet[T], flags: set[T]) =
  self.change(flags, false)

proc init*[T](t: typedesc[TrackedSet], flags: set[T]): TrackedSet[T] =
  result = TrackedSet[T]()
  result.flags = flags

proc init*(s: typedesc[TrackedSet], T: typedesc[enum]): TrackedSet[T] =
  result = TrackedSet[T]()

proc track*[T](self: var TrackedSet[T], callback: ChangeCallback[T]): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc untrack*[T](self: var TrackedSet[T], gid: int) =
  self.changed_callbacks.del(gid)

when is_main_module:
  import unittest

  type
    TestFlags = enum
      Flag1, Flag2, Flag3, Flag4

  var s = TrackedSet.init({Flag1, Flag2})

  check:
    Flag1 in s
    Flag2 in s
    Flag3 notin s
    Flag4 notin s
    {Flag1} in s
    {Flag1, Flag2} in s
    {Flag1, Flag2, Flag3} notin s

  var added: set[TestFlags]
  var removed: set[TestFlags]

  let gid = s.track proc(added_flags, removed_flags: set[TestFlags]) =
    added = added_flags
    removed = removed_flags

  s += Flag3
  check:
    added == {Flag3}
    removed == {}
    s.set == {Flag1, Flag2, Flag3}

  s -= {Flag1, Flag2}
  check:
    added == {}
    removed == {Flag1, Flag2}
    s.set == {Flag3}

  s.set = {Flag4, Flag1}
  check:
    added == {Flag1, Flag4}
    removed == {Flag3}

  var also_added: set[TestFlags]
  var also_removed: set[TestFlags]
  s.track proc(change_added: set[TestFlags], change_removed: set[TestFlags]) =
    also_added = change_added
    also_removed = change_removed

  s.untrack(gid)
  s.set = {Flag2, Flag3}
  check:
    added == {Flag1, Flag4}
    removed == {Flag3}
    s.set == {Flag2, Flag3}
    also_added == {Flag2, Flag3}
    also_removed == {Flag1, Flag4}
