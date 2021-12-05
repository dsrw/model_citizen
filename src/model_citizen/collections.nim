import std / [tables, sequtils, sugar, macros, genasts]
import pkg/print

type
  ChangeKind* = enum
      Added, Removed, Modified

  Change*[T] = tuple[obj: T, kinds: set[ChangeKind]]

  ZenSet*[T] = ref object
    tracked: set[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, proc(changes: seq[Change[T]])]

  ZenSeq*[T] = ref object
    tracked: seq[T]
    changed_callback_gid: int
    changed_callbacks: Table[int, proc(changes: seq[Change[T]])]

  ZenTable*[K, V] = ref object
    tracked: Table[K, V]
    changed_callback_gid: int
    changed_callbacks: Table[int, proc(changes: seq[Change[Pair[K, V]]])]

  List[T] = set[T] | seq[T]
  ZenList[T] = ZenSet[T] | ZenSeq[T]
  Zen = ZenSet | ZenSeq | ZenTable

  Pair*[K, V] = tuple[key: K, value: V]

proc contains*[T](self: ZenList[T], flag: T): bool =
  flag in self.tracked

proc contains*[T](self: ZenSet[T], flags: set[T]): bool =
  result = true
  for flag in flags:
    if flag notin self:
      return false

proc contains*[K, V](self: ZenTable[K, V], key: K): bool =
  key in self.tracked

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

proc len(self: Zen): int = self.tracked.len

proc trigger_callbacks[T](self: Zen, changes: seq[Change[T]]) =
  for _, callback in self.changed_callbacks.pairs:
    callback(changes)

proc link_child[K, V](self: ZenTable[K, V], pair: Pair[K, V]) =
  if not pair.value.is_nil:
    pair.value.track proc(changes: auto) =
      let change = (obj: (pair.key, pair.value), kinds: {Modified})
      self.trigger_callbacks(@[change])

proc link_child[T](self: ZenSeq[T], child: T) =
  if not child.is_nil:
    child.track proc(changes: auto) =
      let change = (obj: child, kinds: {Modified})
      self.trigger_callbacks(@[change])

proc unlink(self: Zen) =
  self.changed_callbacks.clear

proc process_changes[T](self: ZenList[T], initial: List[T]) =
  if self.tracked != initial:
    let added = (self.tracked - initial).map_it (obj: it, kinds: {Added})
    let removed = (initial - self.tracked).map_it (obj: it, kinds: {Removed})

    self.trigger_callbacks(added & removed)

    when T is Zen:
      for change in added:
        self.link_child(change.obj)
      for change in removed:
        if not change.obj.is_nil:
          change.obj.unlink

proc process_changes[K, V](self: ZenTable[K, V], initial_table: Table[K, V]) =
  if self.tracked != initial_table:
    let
      tracked: seq[Pair[K, V]] = self.tracked.pairs.to_seq
      initial: seq[Pair[K, V]] = initial_table.pairs.to_seq

      added = (tracked - initial).map_it:
        var kinds = {Added}
        if it.key in initial_table: kinds.incl Modified
        (obj: it, kinds: kinds)

      removed = (initial - tracked).map_it:
        var kinds = {Removed}
        if it.key in self.tracked: kinds.incl Modified
        (obj: it, kinds: kinds)

    self.trigger_callbacks(added & removed)

    when V is Zen:
      for change in added:
        self.link_child(change.obj)
      for change in removed:
        if not change.obj.value.is_nil:
          change.obj.value.unlink

template mutate(body) =
  when compiles(self.tracked[]):
    let initial_values = self.tracked[]
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values)

proc change[T](self: ZenList[T], items: List[T], add: bool) =
  mutate:
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*(self: Zen) =
  mutate:
    self.tracked = self.tracked.type.default

proc `set=`*[T](self: ZenList[T], flags: List[T]) =
  mutate:
    self.tracked = flags

proc `[]`*[K, V](self: ZenTable[K, V], index: K): V =
  when result is Zen:
    if index notin self.tracked:
      mutate:
        let v = V()
        self.tracked[index] = v
  result = self.tracked[index]

proc `[]=`*[K, V](self: ZenTable[K, V], index: K, value: V) =
  mutate:
    self.tracked[index] = value

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal): T =
  self.tracked[index]

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T) =
  mutate:
    self.tracked[index] = value

proc add*[T](self: ZenSeq[T], value: T) =
  mutate:
    self.tracked.add value

proc set*[T](self: ZenSet[T]): set[T] = self.tracked
proc set*[T](self: ZenSeq[T]): seq[T] = self.tracked

proc `+=`*[T](self: ZenSet[T], flag: T) =
  self.change({flag}, true)

proc `+=`*[T](self: ZenSet[T], flags: set[T]) =
  self.change(flags, true)

proc `+=`*[T](self: ZenSeq[T], item: T) =
  self.change(@[item], true)

proc `+=`*[T](self: ZenSeq[T], items: seq[T]) =
  self.change(items, true)

proc `-=`*[T](self: ZenSet[T], flag: T) =
  self.change({flag}, false)

proc `-=`*[T](self: ZenSet[T], flags: set[T]) =
  self.change(flags, false)

proc `-=`*[T](self: ZenSeq[T], flag: T) =
  self.change(@[flag], false)

proc `-=`*[T](self: ZenSet[T], flags: seq[T]) =
  self.change(flags, false)

proc del*[K, V](self: ZenTable[K, V], index: K) =
  mutate:
    self.tracked.del(index)

proc del*[T](self: ZenSeq[T], index: SomeOrdinal) =
  mutate:
    self.tracked.del(index)

proc del*[T](self: ZenSeq[T], index: T) =
  let index = self.find(index)
  if index > -1:
    mutate:
      self.tracked.del(index)

proc delete*[T](self: ZenSeq[T], index: SomeOrdinal) =
  mutate:
    self.tracked.delete(index)

proc delete*[T](self: ZenSeq[T], index: T) =
  let index = self.find(index)
  if index > -1:
    mutate:
      self.tracked.delete(index)

proc init*[T](t: typedesc[ZenSet], flags: set[T]): ZenSet[T] =
  result = ZenSet[T](tracked: flags)

proc init*(s: typedesc[ZenSeq], T: typedesc): ZenSeq[T] =
  result = ZenSeq[T]()

proc init*[T](t: typedesc[ZenSeq], tracked: open_array[T]): ZenSeq[T] =
  var self = ZenSeq[T]()
  mutate:
    self.tracked = tracked.to_seq
  result = self

proc init*(t: typedesc[ZenTable], K, V: typedesc): ZenTable[K, V] =
  result = ZenTable[K, V]()

proc init*[T: ZenTable](t: typedesc[T]): T =
  result = T()

proc init*[K, V](t: typedesc[ZenTable], tracked: Table[K, V]): ZenTable[K, V] =
  var self = ZenTable[K, V]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[K, V](t: typedesc[ZenTable], tracked: open_array[(K, V)]): ZenTable[K, V] =
  result = ZenTable.init(tracked.to_table)

proc init*(s: typedesc[ZenSet], T: typedesc[enum]): ZenSet[T] =
  result = ZenSet[T]()

proc default*[T](_: typedesc[ZenSet[T]]): ZenSet[T] =
  ZenSet[T].init

proc default*[T](_: typedesc[ZenSeq[T]]): ZenSeq[T] =
  ZenSeq.init(T)

proc default*[K, V](_: typedesc[ZenTable[K, V]]): ZenTable[K, V] =
  ZenTable[K, V].init

macro `%`*(body: untyped): untyped =
  let typ = case body.kind
  of nnkTableConstr: "ZenTable"
  of nnkCurly: "ZenSet"
  of nnkBracket: "ZenSeq"
  else:
    error("Invalid Zen literal", body)
    return # Unreachable

  gen_ast(typ = ident(typ), body):
    typ.init(body)

proc track*[T](self: ZenList[T], callback: proc(changes: seq[Change[T]])): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc track*[K, V](self: ZenTable[K, V], callback: proc(changes: seq[Change[Pair[K, V]]])): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc untrack*(self: Zen, gid: int) =
  self.changed_callbacks.del(gid)

proc untrack_all*(self: Zen) =
  self.changed_callbacks.clear

iterator items*[T](self: ZenList[T]): T =
  for item in self.tracked.items:
    yield item

when is_main_module:
  import unittest
  var change_count = 0
  proc count_changes(obj: auto): int {.discardable.} =
    obj.track proc(changes:auto) =
      for change in changes:
        change_count += 1

  template changes(expected_count: int, body) =
    change_count = 0
    body
    if change_count != expected_count:
      echo ast_to_str(body)
      echo "Expected ", expected_count, " changes. Got ", change_count

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

    let gid = s.track proc(changes: auto) =
      added = {}
      removed = {}
      for c in changes:
        if Added in c.kinds: added.incl(c.obj)
        elif Removed in c.kinds: removed.incl(c.obj)

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
    s.track proc(changes: auto) =
      also_added = {}
      also_removed = {}
      for c in changes:
        if Added in c.kinds: also_added.incl(c.obj)
        elif Removed in c.kinds: also_removed.incl(c.obj)

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

    var id = s.track proc(changes: auto) =
      added_items.add changes.filter_it(Added in it.kinds).map_it it.obj
      removed_items.add changes.filter_it(Removed in it.kinds).map_it it.obj
    s.add "hello"
    s.add "world"

    check added_items == @["hello", "world"]
    s -= "world"
    check removed_items == @["world"]
    removed_items = @[]
    s.clear()
    check removed_items == @["hello"]
    s.untrack(id)

    id = s.count_changes
    1.changes: s += "hello"
    check s.len == 1
    1.changes: s.del(0)
    check s.len == 0

  block set_literal:
    type TestFlags = enum
      Flag1, Flag2, Flag3
    var a = %{Flag1, Flag3}

  block tables:
    var a = ZenTable.init(int, ZenSeq[string])
    a.track proc(changes: auto) =
      discard
    a[1] += "nim"
    a[5] = %["vin", "rw"]
    a.clear

  block primitive_table:
    var a = ZenTable.init(int, int)
    a[1] = 2

  block nested:
    var a = ZenTable.init(int, ZenSeq[int])
    a[1] = %[1, 2]
    a[1] += 3

  block nested_changes:
    type Flags = enum Flag1, Flag2
    let buffers = %{1: %{1: %[%{Flag1}, %{Flag2}]}}
    var id = buffers.count_changes

    # we're watching the top level object. Any child change will
    # come through as a single Modified change on the top level child,
    # regardless of how deep it is or how much actually changed

    1.changes: buffers[1][1][0] += Flag2
    0.changes: buffers[1][1][0] += Flag1 # already there. No change
    1.changes: buffers[1][1][0] -= {Flag1, Flag2}
    1.changes: buffers[1][1] += %{Flag1, Flag2}
    1.changes: buffers[1][1] = %[%{Flag1}]
    2.changes: buffers[1] = nil # Added and Removed changes
    buffers.untrack(id)

    buffers[1] = %{1: %[%{Flag1}]}
    id = buffers[1][1][0].count_changes
    1.changes: buffers[1][1][0] += {Flag1, Flag2}
    0.changes: buffers[1][1][0] += {Flag1, Flag2}
    2.changes: buffers[1][1][0] -= {Flag1, Flag2}
    buffers[1][1][0].untrack(id)

    var changed = false
    id = buffers.track proc(changes: auto) =
      changed = true
      check changes.len == 2
      check changes[0].kinds == {Added, Modified}
      check changes[0].obj.value.is_nil
      check changes[1].kinds == {Removed, Modified}
    buffers[1] = nil
    check changed
    buffers.untrack(id)

    buffers.count_changes
    1.changes: buffers.del(1)
    check 1 notin buffers

  block:
    var a = ZenTable[int, int].init
