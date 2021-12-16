import std / [tables, sequtils, sugar, macros, genasts, typetraits]
import pkg/print

type
  ChangeKind* = enum
      Added, Removed, Modified

  Zen*[T, O] = ref object
    tracked: T
    changed_callback_gid: int
    link_gid: int
    changes*: set[ChangeKind]
    changed_callbacks: Table[int, proc(changes: seq[Change[O]], gid: int)]

  ZenTable*[K, V] = Zen[Table[K, V], Pair[K, V]]
  ZenSeq*[T] = Zen[seq[T], T]
  ZenSet*[T] = Zen[set[T], T]

  Change*[O] = ref object
    obj*: O
    changes*: set[ChangeKind]

  Pair*[K, V] = tuple[key: K, value: V]

proc contains*[T, O](self: Zen[T, O], child: O): bool =
  child in self.tracked

proc contains*[K, V](self: ZenTable[K, V], key: K): bool =
  key in self.tracked

proc contains*[T, O](self: Zen[T, O], children: set[O] | seq[O]): bool =
  result = true
  for child in children:
    if child notin self:
      return false

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

proc len[T, O](self: Zen[T, O]): int = self.tracked.len

proc trigger_callbacks[T, O](self: Zen[T, O], changes: seq[Change[O]]) =
  let callbacks = self.changed_callbacks.dup
  for gid, callback in callbacks.pairs:
    callback(changes, gid)

proc link_child[K, V](self: ZenTable[K, V], child: Pair[K, V]) =
  proc link[S, K, V, T, O](self: S, pair: Pair[K, V], child: Zen[T, O]) =
    child.link_gid = child.track proc(changes: seq[Change[O]]) =
      let change = Change[Pair[K, V]](obj: pair, changes: {Modified})
      self.trigger_callbacks(@[change])

  if not child.value.is_nil:
    self.link(child, child.value)

proc link_child[T](self: ZenSeq[T], child: T) =
  proc link[S, T, O](self: S, child: Zen[T, O]) =
    child.link_gid = child.track proc(changes: seq[Change[O]]) =
      let change = Change[Zen[T, O]](obj: child, changes: {Modified})
      self.trigger_callbacks(@[change])

  if not child.is_nil:
    self.link(child)

proc unlink(self: Zen) =
  self.untrack(self.link_gid)
  self.link_gid = 0

proc process_changes[T, O](self: Zen[T, O], initial: T) =
  if self.tracked != initial:
    let added = (self.tracked - initial).map_it Change[O](obj: it, changes: {Added})
    let removed = (initial - self.tracked).map_it Change[O](obj: it, changes: {Removed})

    self.trigger_callbacks(added & removed)

    when O is Zen:
      for change in added:
        self.link_child(change.obj)
      for change in removed:
        if not change.obj.is_nil:
          change.obj.unlink

proc process_changes[K, V](self: Zen[Table[K, V], Pair[K, V]], initial_table: Table[K, V]) =
  if self.tracked != initial_table:
    let
      tracked: seq[Pair[K, V]] = self.tracked.pairs.to_seq
      initial: seq[Pair[K, V]] = initial_table.pairs.to_seq

      added = (tracked - initial).map_it:
        var changes = {Added}
        if it.key in initial_table: changes.incl Modified
        Change[Pair[K, V]](obj: it, changes: changes)

      removed = (initial - tracked).map_it:
        var changes = {Removed}
        if it.key in self.tracked: changes.incl Modified
        Change[Pair[K, V]](obj: it, changes: changes)

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

proc change[T, O](self: Zen[T, O], items: T, add: bool) =
  mutate:
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*[T, O](self: Zen[T, O]) =
  mutate:
    self.tracked = T.default

proc `value=`*[T, O](self: Zen[T, O], value: T) =
  mutate:
    self.tracked = value

proc value*[T, O](self: Zen[T, O]): T = self.tracked

proc `[]`*[K, V](self: Zen[Table[K, V], Pair[K, V]], index: K): V =
  when result is Zen:
    if index notin self.tracked:
      mutate:
        let v = V()
        self.tracked[index] = v
  result = self.tracked[index]

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal): T =
  self.tracked[index]

proc `[]=`*[K, V](self: ZenTable[K, V], index: K, value: V) =
  mutate:
    self.tracked[index] = value

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T) =
  mutate:
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O) =
  mutate:
    self.tracked.add value

proc del*[T, O](self: Zen[T, O], value: O) =
  mutate:
    self.tracked.del value

proc del*[K, V](self: ZenTable[K, V], key: K) =
  mutate:
    self.tracked.del key

proc del*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  mutate:
    self.tracked.del(index)

proc delete*[T, O](self: Zen[T, O], value: O) =
  mutate:
    self.tracked.delete value

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  mutate:
    self.tracked.delete key

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  mutate:
    self.tracked.delete(index)

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  self.change(value, true)

proc `+=`*[T: set, O](self: Zen[T, O], value: O) =
  self.change({value}, true)

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  self.change(@[value], true)

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  self.change(value, false)

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  self.change({value}, false)

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  self.change(@[value], false)

proc init*(T: typedesc[Zen]): T = T()

proc init*[O](_: typedesc[Zen], tracked: set[O]): Zen[set[O], O] =
  var self = Zen[set[O], O]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[K, V](_: typedesc[Zen], tracked: Table[K, V]): ZenTable[K, V] =
  var self = ZenTable[K, V]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[O](_: typedesc[Zen], tracked: open_array[O]): Zen[seq[O], O] =
  var self = Zen[seq[O], O]()
  mutate:
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: typedesc[Zen], T: typedesc[seq[O]]): Zen[seq[O], O] =
  result = Zen[seq[O], O]()

proc init*[O](_: typedesc[Zen], T: typedesc[set[O]]): Zen[set[O], O] =
  result = Zen[set[O], O]()

proc init*[K, V](_: typedesc[Zen], T: typedesc[Table[K, V]]): Zen[Table[K, V], Pair[K, V]] =
  result = Zen[Table[K, V], Pair[K, V]]()

proc init*(T: typedesc[Zen], K, V: typedesc): ZenTable[K, V] =
  ZenTable[K, V]()

proc init*[K, V](t: typedesc[Zen], tracked: open_array[(K, V)]): ZenTable[K, V] =
  result = Zen.init(tracked.to_table)

template `%`*(body: untyped): untyped =
  Zen.init(body)

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]], gid: int)): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]])): int {.discardable.} =
  self.track proc(changes, _: auto) = callback(changes)

proc untrack*(self: Zen, gid: int) =
  self.changed_callbacks.del(gid)

proc untrack_all*(self: Zen) =
  self.changed_callbacks.clear

iterator items*[T](self: ZenSet[T] | ZenSeq[T]): T =
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

    var s = Zen.init({Flag1, Flag2})

    check:
      Flag2 in s
      Flag2 in s
      Flag3 notin s
      Flag4 notin s
      {Flag1} in s
      {Flag1, Flag2} in s
      {Flag1, Flag2, Flag3} notin s

    var added: set[TestFlags]
    var removed: set[TestFlags]

    let gid = s.track proc(changes, gid: auto) =
      added = {}
      removed = {}
      for c in changes:
        if Added in c.changes: added.incl(c.obj)
        elif Removed in c.changes: removed.incl(c.obj)

    s += Flag3
    check:
      added == {Flag3}
      removed == {}
      s.value == {Flag1, Flag2, Flag3}

    s -= {Flag1, Flag2}
    check:
      added == {}
      removed == {Flag1, Flag2}
      s.value == {Flag3}

    s.value = {Flag4, Flag1}
    check:
      added == {Flag1, Flag4}
      removed == {Flag3}

    var also_added: set[TestFlags]
    var also_removed: set[TestFlags]
    s.track proc(changes, gid: auto) =
      also_added = {}
      also_removed = {}
      for c in changes:
        if Added in c.changes: also_added.incl(c.obj)
        elif Removed in c.changes: also_removed.incl(c.obj)

    s.untrack(gid)
    s.value = {Flag2, Flag3}
    check:
      added == {Flag1, Flag4}
      removed == {Flag3}
      s.value == {Flag2, Flag3}
      also_added == {Flag2, Flag3}
      also_removed == {Flag1, Flag4}
    s.clear()
    check also_removed == {Flag2, Flag3}

  block seqs:
    var
      s = Zen.init(seq[string])
      added_items, removed_items: seq[string]

    var id = s.track proc(changes: auto) =
      added_items.add changes.filter_it(Added in it.changes).map_it it.obj
      removed_items.add changes.filter_it(Removed in it.changes).map_it it.obj
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
    var a = Zen.init(Table[int, ZenSeq[string]])
    a.track proc(changes, _: auto) =
      discard
    a[1] += "nim"
    a[5] = %["vin", "rw"]
    a.clear

  block primitive_table:
    var a = Zen.init(Table[int, int])
    a[1] = 2

  block nested:
    var a = ZenTable[int, ZenSeq[int]].init
    a[1] = %[1, 2]
    a[1] += 3

  block nested_2:
    var a = %{1: %[1]}
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

    # unlink
    buffers[1][1][0].clear
    let child = buffers[1][1][0]
    buffers[1][1].del 0
    0.changes: child += Flag1
    buffers[1][1] += child
    1.changes: child += Flag2

    2.changes: buffers[1] = nil # Added and Removed changes
    buffers.untrack(id)

    buffers[1] = %{1: %[%{Flag1}]}
    id = buffers[1][1][0].count_changes
    1.changes: buffers[1][1][0] += {Flag1, Flag2}
    0.changes: buffers[1][1][0] += {Flag1, Flag2}
    2.changes: buffers[1][1][0] -= {Flag1, Flag2}

    buffers[1][1][0].untrack(id)

    var changed = false
    id = buffers.track proc(changes, _: auto) =
      changed = true
      check changes.len == 2
      check changes[0].changes == {Added, Modified}
      check changes[0].obj.value.is_nil
      check changes[1].changes == {Removed, Modified}
    buffers[1] = nil
    check changed
    buffers.untrack(id)

    buffers.count_changes
    1.changes: buffers.del(1)
    check 1 notin buffers

  block:
    var a = ZenTable[int, int].init
    var b = Zen[Table[int, string], Pair[int, string]].init
    check b is ZenTable[int, string]

  block:
    type TestFlag = enum
      Flag1, Flag2
    var a = Zen.init(seq[int])
    var b = Zen.init(set[TestFlag])
    check:
      a is Zen[seq[int], int]
      b is Zen[set[TestFlag], TestFlag]
