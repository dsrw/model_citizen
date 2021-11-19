import std / [tables, sequtils, sugar, macros]

type
  TrackedSet*[T] = object
    tracked: set[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, ChangeCallback[T]]

  TrackedSeq*[T] = object
    tracked: seq[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, ChangeCallback[T]]

  Tracked*[T] = TrackedSet[T] | TrackedSeq[T]
  Trackable*[T] = set[T] | seq[T]
  ChangeKind* = enum
    Added, Removed, Modified

  Change*[T] = tuple[obj: T, kind: ChangeKind]

  ChangeCallback*[T] = proc(changes: seq[Change[T]])

proc contains*[T](self: Tracked[T], flag: T): bool =
  flag in self.tracked

proc contains*[T](self: TrackedSet[T], flags: set[T]): bool =
  result = true
  for flag in flags:
    if flag notin self:
      return false

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

template mutate(body) =
  let initial_values = self.tracked.dup
  body
  if self.tracked != initial_values:
    let
      added = (self.tracked - initial_values).map_it (it, Added)
      removed = (initial_values - self.tracked).map_it (it, Removed)
      changes = added & removed
    for _, callback in self.changed_callbacks:
      callback(changes)

proc change[T](self: var Tracked[T], items: Trackable[T], add: bool) =
  mutate:
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*[T](self: var TrackedSeq[T]) =
  mutate:
    self.tracked = @[]

proc clear*[T](self: var TrackedSet[T]) =
  mutate:
    self.tracked = {}

proc `set=`*[T](self: var Tracked[T], flags: Trackable[T]) =
  mutate:
    self.tracked = flags

proc `[]`*[T](self: TrackedSeq[T], index: Ordinal): T = self.set[index]

proc `[]=`*[T](self: var TrackedSeq[T], index: SomeOrdinal, value: T) =
  mutate:
    self.tracked[index] = value

proc add*[T](self: var TrackedSeq[T], value: T) =
  mutate:
    self.tracked.add value

proc set*[T](self: TrackedSet[T]): set[T] = self.tracked
proc set*[T](self: TrackedSeq[T]): seq[T] = self.tracked

proc `+=`*[T](self: var TrackedSet[T], flag: T) =
  self.change({flag}, true)

proc `+=`*[T](self: var TrackedSet[T], flags: set[T]) =
  self.change(flags, true)

proc `-=`*[T](self: var TrackedSet[T], flag: T) =
  self.change({flag}, false)

proc `-=`*[T](self: var TrackedSet[T], flags: set[T]) =
  self.change(flags, false)

proc `+=`*[T](self: var TrackedSeq[T], flag: T) =
  self.change(@[flag], true)

proc `+=`*[T](self: var TrackedSet[T], flags: seq[T]) =
  self.change(flags, true)

proc `-=`*[T](self: var TrackedSeq[T], flag: T) =
  self.change(@[flag], false)

proc `-=`*[T](self: var TrackedSet[T], flags: seq[T]) =
  self.change(flags, false)

proc init*[T](t: typedesc[TrackedSet], flags: set[T]): TrackedSet[T] =
  result = TrackedSet[T]()
  result.tracked = flags

proc init*(s: typedesc[TrackedSeq], T: typedesc): TrackedSeq[T] =
  result = TrackedSeq[T]()

proc init*[T](t: typedesc[TrackedSeq], flags: seq[T]): TrackedSeq[T] =
  result = TrackedSeq[T]()
  result.tracked = flags

proc init*(s: typedesc[TrackedSet], T: typedesc[enum]): TrackedSet[T] =
  result = TrackedSet[T]()

proc track*[T](self: var Tracked[T], callback: ChangeCallback[T]): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc untrack*[T](self: var Tracked[T], gid: int) =
  self.changed_callbacks.del(gid)

iterator items*[T](self: Tracked[T]): T =
  for item in self.tracked:
    yield item

when is_main_module:
  import unittest

  block sets:
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

    let gid = s.track proc(changes: seq[Change[TestFlags]]) =
      added = {}
      removed = {}
      for c in changes:
        if c.kind == Added: added.incl(c.obj)
        elif c.kind == Removed: removed.incl(c.obj)

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
    s.track proc(changes: seq[Change[TestFlags]]) =
      also_added = {}
      also_removed = {}
      for c in changes:
        if c.kind == Added: also_added.incl(c.obj)
        elif c.kind == Removed: also_removed.incl(c.obj)

    s.untrack(gid)
    s.set = {Flag2, Flag3}
    check:
      added == {Flag1, Flag4}
      removed == {Flag3}
      s.set == {Flag2, Flag3}
      also_added == {Flag2, Flag3}
      also_removed == {Flag1, Flag4}
    s.clear()
    check also_removed == {Flag2, Flag3}

  block seqs:
    var
      s = TrackedSeq.init(string)
      added_items, removed_items: seq[string]

    s.track proc(changes: seq[Change[string]]) =
      added_items.add changes.filter_it(it.kind == Added).map_it it.obj
      removed_items.add changes.filter_it(it.kind == Removed).map_it it.obj
    s.add "hello"
    s.add "world"

    check added_items == @["hello", "world"]
    s -= "world"
    check removed_items == @["world"]
    removed_items = @[]
    s.clear()
    check removed_items == @["hello"]