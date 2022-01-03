import std / [tables, sequtils, sugar, macros, genasts, typetraits]
import pkg/print

type
  ChangeKind* = enum
      Added, Removed, Modified, Touched

  Zen*[T, O] = ref object
    tracked: T
    changed_callback_gid: int
    link_gid: int
    changed_callbacks: Table[int, proc(changes: seq[Change[O]], gid: int)]

  ZenTable*[K, V] = Zen[Table[K, V], Pair[K, V]]
  ZenSeq*[T] = Zen[seq[T], T]
  ZenSet*[T] = Zen[set[T], T]
  ZenValue*[T] = Zen[T, T]

  BaseChange* = ref object of RootObj
    changes*: set[ChangeKind]
    field_name*: string
    triggered_by*: seq[BaseChange]
    triggered_by_type*: string

  Change*[O] = ref object of BaseChange
    item*: O

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
  if changes.len > 0:
    let callbacks = self.changed_callbacks.dup
    for gid, callback in callbacks.pairs:
      callback(changes, gid)

proc link_child[K, V, L](self: ZenTable[K, V], child: Pair[K, V], obj: L, field_name = "") =
  let field_name = field_name
  proc link[S, K, V, T, O](self: S, pair: Pair[K, V], child: Zen[T, O]) =
    child.link_gid = child.track proc(changes: seq[Change[O]]) =
      let change = Change[Pair[K, V]](item: pair, changes: {Modified}, field_name: field_name)
      change.triggered_by = cast[seq[BaseChange]](changes)
      change.triggered_by_type = $O
      self.trigger_callbacks(@[change])

  if not child.value.is_nil:
    self.link(child, child.value)

proc link_child[T, O, L](self: ZenSeq[T], child: O, obj: L, field_name = "") =
  let
    field_name = field_name
    self = self
    obj = obj
  proc link[T, O](child: Zen[T, O]) =
    child.link_gid = child.track proc(changes: seq[Change[O]]) =
      let change = Change[obj.type](item: obj, changes: {Modified}, field_name: field_name)
      change.triggered_by = cast[seq[BaseChange]](changes)
      change.triggered_by_type = $O
      self.trigger_callbacks(@[change])

  if not child.is_nil:
    link(child)

proc unlink(self: Zen) =
  self.untrack(self.link_gid)
  self.link_gid = 0

proc unlink[T: Pair](pair: T) =
  pair.value.untrack(pair.value.link_gid)
  pair.value.link_gid = 0

proc link_and_unlink(self, added, removed: auto) =
  template value(change: Change[Pair]): untyped = change.item.value
  template value(change: not Change[Pair]): untyped = change.item
  template deref(o: ref): untyped = o[]
  template deref(o: not ref): untyped = o

  for change in added:
    when change.value is Zen:
      self.link_child(change.item, change.item)
    elif change.value is object or change.value is ref:
      for name, val in change.value.deref.field_pairs:
        when val is Zen:
          if not val.is_nil:
            self.link_child(val, change.item, name)

  for change in removed:
    when change.value is Zen:
      if not change.value.is_nil:
        change.value.unlink
    elif change.value is object or change.value is ref:
      for name, val in change.value.deref.field_pairs:
        when val is Zen:
          if not val.is_nil:
            val.unlink

proc process_changes[T](self: Zen[T, T], initial: T) =
  if initial != self.tracked:
    self.trigger_callbacks(@[
      Change[T](item: initial, changes: {Removed, Modified}),
      Change[T](item: self.tracked, changes: {Added, Modified}),
    ])

proc process_changes[T: seq | set, O](self: Zen[T, O], initial: T, touch = T.default) =
  let added = (self.tracked - initial).map_it:
    let changes = if it in touch: {Touched} else: {}
    Change[O](item: it, changes: {Added} + changes)
  let removed = (initial - self.tracked).map_it Change[O](item: it, changes: {Removed})
  let changes = added & removed

  var touched: seq[Change[O]]
  for item in touch:
    if item in initial:
      touched.add Change[O](item: item, changes: {Touched})

  self.trigger_callbacks(added & removed & touched)
  self.link_and_unlink(added, removed)

proc process_changes[K, V](self: Zen[Table[K, V], Pair[K, V]], initial_table: Table[K, V]) =
  let
    tracked: seq[Pair[K, V]] = self.tracked.pairs.to_seq
    initial: seq[Pair[K, V]] = initial_table.pairs.to_seq

    added = (tracked - initial).map_it:
      var changes = {Added}
      if it.key in initial_table: changes.incl Modified
      Change[Pair[K, V]](item: it, changes: changes)

    removed = (initial - tracked).map_it:
      var changes = {Removed}
      if it.key in self.tracked: changes.incl Modified
      Change[Pair[K, V]](item: it, changes: changes)

  self.trigger_callbacks(added & removed)

  self.link_and_unlink(added, removed)

template mutate_and_touch(touch: untyped, body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values, touch)

template mutate(body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
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

proc change_and_touch[T, O](self: Zen[T, O], items: T, add: bool) =
  mutate_and_touch(touch = items):
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

proc touch*[T: set, O](self: Zen[T, O], value: O) =
  self.change_and_touch({value}, true)

proc touch*[T: seq, O](self: Zen[T, O], value: O) =
  self.change_and_touch(@[value], true)

proc touch*[T, O](self: Zen[T, O], value: T) =
  self.change_and_touch(value, true)

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

proc `==`*(a, b: Zen): bool =
  (a.is_nil and b.is_nil) or
    not a.is_nil and not b.is_nil and
    a.tracked == b.tracked

proc init*(T: type Zen): T = T()

proc init*(_: type Zen, T: type[ref | object | SomeOrdinal | SomeNumber | string]): Zen[T, T] =
  result = Zen[T, T]()

proc init*[T: ref | object | SomeOrdinal | SomeNumber | string](_: type Zen, tracked: T): Zen[T, T] =
  var self = Zen[T, T]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: set[O]): Zen[set[O], O] =
  var self = Zen[set[O], O]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[K, V](_: type Zen, tracked: Table[K, V]): ZenTable[K, V] =
  var self = ZenTable[K, V]()
  mutate:
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: open_array[O]): Zen[seq[O], O] =
  var self = Zen[seq[O], O]()
  mutate:
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: type Zen, T: type seq[O]): Zen[seq[O], O] =
  result = Zen[seq[O], O]()

proc init*[O](_: type Zen, T: type set[O]): Zen[set[O], O] =
  result = Zen[set[O], O]()

proc init*[K, V](_: type Zen, T: type Table[K, V]): Zen[Table[K, V], Pair[K, V]] =
  result = Zen[Table[K, V], Pair[K, V]]()

proc init*(_: type Zen, K, V: type): ZenTable[K, V] =
  ZenTable[K, V]()

proc init*[K, V](t: type Zen, tracked: open_array[(K, V)]): ZenTable[K, V] =
  result = Zen.init(tracked.to_table)

template `%`*(body: untyped): untyped =
  Zen.init(body)

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]], gid: int)): int {.discardable.} =
  inc self.changed_callback_gid
  result = self.changed_callback_gid
  self.changed_callbacks[result] = callback

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]])): int {.discardable.} =
  self.track proc(changes, _: auto) = callback(changes)

template changes*[T, O](self: Zen[T, O], body) =
  self.track proc(changes: seq[Change[O]], gid {.inject.}: int) =
    for change {.inject.} in changes:
      template added: bool = Added in change.changes
      template added(obj: O): bool = change.item == obj and added()
      template removed: bool = Removed in change.changes
      template removed(obj: O): bool = change.item == obj and removed()
      template modified: bool = Modified in change.changes
      template modified(obj: O): bool = change.item == obj and modified()
      template touched: bool = Touched in change.changes
      template touched(obj: O): bool = change.item == obj and touched()

      body

proc untrack*(self: Zen, gid: int) =
  self.changed_callbacks.del(gid)

proc untrack_all*(self: Zen) =
  self.changed_callbacks.clear

iterator items*[T](self: ZenSet[T] | ZenSeq[T]): T =
  for item in self.tracked.items:
    yield item

iterator items*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  for pair in self.tracked.pairs:
    yield pair

iterator pairs*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  for pair in self.tracked.pairs:
    yield pair

when is_main_module:
  import unittest
  var change_count = 0
  proc count_changes(obj: auto): int {.discardable.} =
    obj.changes:
      change_count += 1

  template changes(expected_count: int, body) =
    change_count = 0
    body
    if change_count != expected_count:
      echo ast_to_str(body)
      echo "Expected ", expected_count, " changes. Got ", change_count

  import deques
  template assert_changes[T, O](self: Zen[T, O], expect, body: untyped) =
    var expectations = expect.to_deque
    self.track proc(changes: seq[Change[O]]) =
      for change in changes:
        let expectation = expectations.pop_first()
        if not (expectation[0] in change.changes and expectation[1] == change.item):
          print "unsatisfied expectation", expectation, change
    body
    if expectations.len > 0:
      echo "unsatisfied expectations: ", expectations
      assert false

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
        if Added in c.changes: added.incl(c.item)
        elif Removed in c.changes: removed.incl(c.item)

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
        if Added in c.changes: also_added.incl(c.item)
        elif Removed in c.changes: also_removed.incl(c.item)

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
      added_items.add changes.filter_it(Added in it.changes).map_it it.item
      removed_items.add changes.filter_it(Removed in it.changes).map_it it.item
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
    a[1] = %["nim"]
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
    1.changes: buffers[1][1][0].touch Flag1
    0.changes: buffers[1][1][0] += Flag1
    1.changes: buffers[1][1][0].touch Flag1
    2.changes: buffers[1][1][0].touch {Flag1, Flag2}
    2.changes: buffers[1][1][0].touch {Flag1, Flag2}

    buffers[1][1][0].untrack(id)

    var changed = false
    id = buffers.track proc(changes, _: auto) =
      changed = true
      check changes.len == 2
      check changes[0].changes == {Added, Modified}
      check changes[0].item.value.is_nil
      check changes[1].changes == {Removed, Modified}
    buffers[1] = nil
    check changed
    buffers.untrack(id)

    buffers.count_changes
    1.changes: buffers.del(1)
    check 1 notin buffers

  block:
    var a = ZenTable[int, string].init
    var b = Zen[Table[int, string], Pair[int, string]].init
    var c = ZenTable[string, int].init
    check b is ZenTable[int, string]
    check a == b
    when compiles(a == c):
      assert false, "{a.type} and {b.type} shouldn't be comparable"

  block:
    type TestFlag = enum
      Flag1, Flag2
    var a = Zen.init(seq[int])
    var b = Zen.init(set[TestFlag])
    check:
      a is Zen[seq[int], int]
      b is Zen[set[TestFlag], TestFlag]

  block nested_triggers:
    type
      UnitFlags = enum
        Targeted, Highlighted

      Unit = ref object
        id: int
        parent: Unit
        units: Zen[seq[Unit], Unit]
        flags: ZenSet[UnitFlags]

    proc init(_: type Unit, id = 0): Unit =
      result = Unit(id: id)
      result.units = Zen.init(seq[Unit])
      result.flags = Zen.init(set[UnitFlags])

    var a = Unit.init
    var id = a.units.count_changes
    var b = Unit.init
    1.changes: a.units.add b
    var c = Unit.init
    1.changes: b.units.add c
    a.units.untrack(id)

    var triggered_by: seq[seq[BaseChange]]
    a.units.track proc(changes: auto) =
      triggered_by = @[]
      for change in changes:
        triggered_by.add change.triggered_by

    let d = Unit.init(id = 222)
    c.units.add d
    check triggered_by[0][0].triggered_by[0] of Change[Unit]
    check triggered_by[0][0].triggered_by_type == "Unit"
    let x = Change[Unit](triggered_by[0][0].triggered_by[0])
    check x.item.id == 222
    d.flags += Targeted
    let trigger = triggered_by[0][0].triggered_by[0].triggered_by[0]
    check trigger of Change[UnitFlags]
    let f = Change[UnitFlags](trigger)
    check Added in f.changes
    check f.item == Targeted

  block primitives:
    let a = ZenValue[int].init
    a.assert_changes {Removed: 0, Added: 5, Removed: 5, Added: 10}:
      a.value = 5
      a.value = 10

    let b = %4
    b.assert_changes {Removed: 4, Added: 11}:
      b.value = 11

    let c = %"enu"
    c.assert_changes {Removed: "enu", Added: "ENU"}:
      c.value = "ENU"

  block refs:
    type ARef = ref object
      val: int

    let (r1, r2, r3) = (ARef(val: 1), ARef(val:2), ARef(val:3))

    let a = %r1
    a.assert_changes {Removed: r1, Added: r2, Removed: r2, Added: r3}:
      a.value = r2
      a.value = r3
