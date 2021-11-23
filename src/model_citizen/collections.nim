import std / [tables, sequtils, sugar, macros, genasts]
import print

type
  ZenSet*[T] = object
    tracked: set[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, ChangeCallback[T]]

  ZenSeq*[T] = object
    tracked: seq[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, ChangeCallback[T]]

  Pair*[K, V] = tuple[key: K, value: V]

  ZenTable*[K, V] = object
    tracked: Table[K, V]
    changed_callback_gid: int
    use_default: bool
    changed_callbacks: Table[int, ChangeCallback[Pair[K, V]]]

  ChangeKind* = enum
    Added, Removed, Modified
  Change*[T] = tuple[obj: T, kind: ChangeKind]
  ChangeCallback*[T] = proc(changes: seq[Change[T]])

  List[T] = set[T] | seq[T]
  ZenList[T] = ZenSet[T] | ZenSeq[T]
  Zen = ZenSet | ZenSeq | ZenTable

proc contains*[T](self: ZenList[T], flag: T): bool =
  flag in self.tracked

proc contains*[T](self: ZenSet[T], flags: set[T]): bool =
  result = true
  for flag in flags:
    if flag notin self:
      return false

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

proc changes[T](self: ZenList[T], initial: List[T]): seq[Change[T]] =
  let added = (self.tracked - initial).map_it (it, Added)
  let removed = (initial - self.tracked).map_it (it, Removed)
  result = added & removed

proc changes[K, V](self: ZenTable[K, V], initial: Table[K, V]): seq[Change[Pair[K, V]]] =
  let
    tracked = self.tracked.pairs.to_seq
    initial = initial.pairs.to_seq
    added = (tracked - initial).map_it (it, Added)
    removed = (initial - tracked).map_it (it, Removed)
  result = added & removed

template mutate(body) =
  let initial_values = self.tracked.dup
  body
  if self.tracked != initial_values:
    let changes = self.changes(initial_values)
    for _, callback in self.changed_callbacks:
      callback(changes)

proc change[T](self: var ZenList[T], items: List[T], add: bool) =
  mutate:
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*(self: var Zen) =
  mutate:
    self.tracked = self.tracked.type.default

proc `set=`*[T](self: var ZenList[T], flags: List[T]) =
  mutate:
    self.tracked = flags

proc mget*[K, V](self: var ZenTable[K, V], index: K): var V =
  if index in self.tracked or not self.use_default:
    result = self.tracked[index]
  else:
    mutate:
      self.tracked[index] = V.default
    result = self.tracked[index]

proc get*[K, V](self: var ZenTable[K, V], index: K): V =
  result = self.tracked[index]

template `[]`*[K, V](self: var ZenTable[K, V], index: K): untyped =
  when V is Zen:
    self.mget(index)
  else:
    self.get(index)

proc `[]=`*[K, V](self: var ZenTable[K, V], index: K, value: V) =
  mutate:
    self.tracked[index] = value

proc `[]`*[T](self: ZenSeq[T], index: Ordinal): T = self.tracked[index]

proc `[]=`*[T](self: var ZenSeq[T], index: SomeOrdinal, value: T) =
  mutate:
    self.tracked[index] = value

proc add*[T](self: var ZenSeq[T], value: T) =
  mutate:
    self.tracked.add value

proc set*[T](self: ZenSet[T]): set[T] = self.tracked
proc set*[T](self: ZenSeq[T]): seq[T] = self.tracked

proc `+=`*[T](self: var ZenSet[T], flag: T) =
  self.change({flag}, true)

proc `+=`*[T](self: var ZenSet[T], flags: set[T]) =
  self.change(flags, true)

proc `-=`*[T](self: var ZenSet[T], flag: T) =
  self.change({flag}, false)

proc `-=`*[T](self: var ZenSet[T], flags: set[T]) =
  self.change(flags, false)

proc `+=`*[T](self: var ZenSeq[T], flag: T) =
  self.change(@[flag], true)

proc `+=`*[T](self: var ZenSet[T], flags: seq[T]) =
  self.change(flags, true)

proc `-=`*[T](self: var ZenSeq[T], flag: T) =
  self.change(@[flag], false)

proc `-=`*[T](self: var ZenSet[T], flags: seq[T]) =
  self.change(flags, false)

proc init*[T](t: typedesc[ZenSet], flags: set[T]): ZenSet[T] =
  result = ZenSet[T]()
  result.tracked = flags

proc init*(s: typedesc[ZenSeq], T: typedesc): ZenSeq[T] =
  result = ZenSeq[T]()

proc init*[T](t: typedesc[ZenSeq], flags: seq[T]): ZenSeq[T] =
  result = ZenSeq[T]()
  result.tracked = flags

proc init*(t: typedesc[ZenTable], K, V: typedesc): ZenTable[K, V] =
  result = ZenTable[K, V]()

proc init_tree*(t: typedesc[ZenTable], K, V: typedesc): ZenTable[K, V] =
  when V is Zen:
    result = ZenTable[K, V](use_default: true)
  else:
    {.error: "Value type must be Zen".}

proc init*(s: typedesc[ZenSet], T: typedesc[enum]): ZenSet[T] =
  result = ZenSet[T]()

proc track*[T](self: var ZenList[T], callback: ChangeCallback[T]): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc track*[K, V](self: var ZenTable[K, V], callback: ChangeCallback[Pair[K, V]]): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc untrack*(self: var Zen, gid: int) =
  self.changed_callbacks.del(gid)

iterator items*[T](self: ZenList[T]): T =
  for item in self.tracked:
    yield item

when is_main_module:
  import unittest

  block sets:
    type
      TestFlags = enum
        Flag1, Flag2, Flag3, Flag4

    var s = ZenSet.init({Flag1, Flag2})

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
      s = ZenSeq.init(string)
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

  block tables:
    var a = ZenTable.init_tree(int, ZenSeq[string])
    a.track proc(changes: seq[Change[(int, seq[string])]]) =
      print "changed: ", changes
    a[1] += "nim"
    #a[5] = @["vin", "rw"]
    print a
    a.clear
    print a
