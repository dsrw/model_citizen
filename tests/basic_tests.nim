import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
  unittest]
import pkg/print
import model_citizen

var change_count = 0
proc count_changes(obj: auto): ZID {.discardable.} =
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
      if not (expectation[0] in change.changes and
        expectation[1] == change.item):

        print "unsatisfied expectation", expectation, change
  body
  if expectations.len > 0:
    echo "unsatisfied expectations: ", expectations
    check false

test "sets":
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

  let zid = s.track proc(changes, zid: auto) =
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
  s.track proc(changes, zid: auto) =
    also_added = {}
    also_removed = {}
    for c in changes:
      if Added in c.changes: also_added.incl(c.item)
      elif Removed in c.changes: also_removed.incl(c.item)

  s.untrack(zid)
  s.value = {Flag2, Flag3}
  check:
    added == {}
    removed == {}
    s.value == {Flag2, Flag3}
    also_added == {Flag2, Flag3}
    also_removed == {Flag1, Flag4}
  s.untrack(zid)
  s.clear()
  check also_removed == {Flag2, Flag3}

test "seqs":
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

test "set_literal":
  type TestFlags = enum
    Flag1, Flag2, Flag3
  var a = %{Flag1, Flag3}

test "tables":
  var a = Zen.init(Table[int, ZenSeq[string]])
  a.track proc(changes, _: auto) =
    discard
  a[1] = %["nim"]
  a[5] = %["vin", "rw"]
  a.clear

test "primitive_table":
  var a = Zen.init(Table[int, int])
  a[1] = 2

test "nested":
  var a = ZenTable[int, ZenSeq[int]].init
  a[1] = %[1, 2]
  a[1] += 3

test "nested_2":
  var a = %{1: %[1]}
  a[1] = %[1, 2]
  a[1] += 3

test "nested_changes":
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
    if not changed:
      changed = true
      check changes.len == 2
      check changes[0].changes == {Removed, Modified}
      check not changes[0].item.value.is_nil
      check changes[1].changes == {Added, Modified}
      check changes[1].item.value.is_nil
  buffers[1] = nil
  check changed
  buffers.untrack(id)

  buffers.count_changes
  1.changes: buffers.del(1)
  check 1 notin buffers

test "comparable aliases":
  var a = ZenTable[int, string].init
  var b = Zen[Table[int, string], Pair[int, string]].init
  var c = ZenTable[string, int].init
  check b is ZenTable[int, string]
  check a == b
  when compiles(a == c):
    check false, "{a.type} and {b.type} shouldn't be comparable"

test "init from type":
  type TestFlag = enum
    Flag1, Flag2
  var a = Zen.init(seq[int])
  var b = Zen.init(set[TestFlag])
  check:
    a is Zen[seq[int], int]
    b is Zen[set[TestFlag], TestFlag]

test "nested_triggers":
  type
    UnitFlags = enum
      Targeted, Highlighted

    Unit = ref object
      id: int
      parent: Unit
      units: Zen[seq[Unit], Unit]
      flags: ZenSet[UnitFlags]

  proc init(_: type Unit, id = 0, track_children = true): Unit =
    result = Unit(id: id)
    result.units = Zen.init(seq[Unit], track_children)
    result.flags = Zen.init(set[UnitFlags], track_children)

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

  # without child tracking:
  a = Unit.init(track_children = false)
  id = a.units.count_changes
  b = Unit.init
  1.changes: a.units.add b
  c = Unit.init
  0.changes: b.units.add c
  a.units.untrack(id)

test "primitives":
  let a = ZenValue[int].init
  a.assert_changes {Removed: 0, Added: 5, Removed: 5, Added: 10, Touched: 10,
                    Removed: 10, Touched: 11, Removed: 11, Added: 12}:
    a.value = 5
    a.value = 10
    a.touch 10
    a.touch 11
    a.touch 12

  let b = %4
  b.assert_changes {Removed: 4, Added: 11}:
    b.value = 11

  let c = %"enu"
  c.assert_changes {Removed: "enu", Added: "ENU"}:
    c.value = "ENU"

test "refs":
  type ARef = ref object
    val: int

  let (r1, r2, r3) = (ARef(val: 1), ARef(val:2), ARef(val:3))

  let a = %r1
  a.assert_changes {Removed: r1, Added: r2, Removed: r2, Added: r3}:
    a.value = r2
    a.value = r3

test "pausing":
  var s = ZenValue[string].init
  let zid = s.count_changes
  2.changes: s.value = "one"
  s.pause zid:
    0.changes: s.value = "two"
  2.changes: s.value = "three"
  let zids = @[zid, 1234]
  s.pause zids:
    0.changes: s.value = "four"
  2.changes: s.value = "five"
  s.pause zid, 1234:
    0.changes: s.value = "six"
  2.changes:
    s.value = "seven"
  s.pause:
    0.changes: s.value = "eight"
  2.changes: s.value = "nine"

  var calls = 0
  s.changes:
    calls += 1
    s.value = "cal"

  s.value = "vin"
  check calls == 2

test "closed":
  var s = ZenValue[string].init
  var changed = false

  s.track proc(changes: auto) =
    changed = true
    check changes[0].changes == {Closed}
  s.untrack_all
  check changed == true

  changed = false
  let zid = s.track proc(changes: auto) =
    changed = true
    check changes[0].changes == {Closed}
  Zen.thread_ctx.untrack(zid)
  check changed == true

test "init_props":
  type
    Model = ref object
      list: ZenSeq[int]
      field: string
      zen_field: ZenValue[string]

  proc init(_: type Model): Model =
    result = Model()
    result.init_zen_fields

  let m = Model.init
  m.zen_field.value = "test"
  check m.zen_field.value == "test"

test "sync":
  var
    ctx1 = ZenContext.init(name = "ctx1")
    ctx2 = ZenContext.init(name = "ctx2")
    s1 = ZenValue[string].init(ctx = ctx1)
    s2 = ZenValue[string].init(ctx = ctx2)

  s1.ctx.subscribe(ctx2)
  s2.ctx.subscribe(ctx1)

  s1.value = "sync me"

  ctx2.recv
  check s2.value == s1.value

  s1 &= " and me"

  ctx2  .recv
  check s2.value == s1.value and s2.value == "sync me and me"

  type
    Thing = ref object
      name: string

    Tree = ref object
      zen: ZenValue[string]
      things: ZenSeq[Thing]
      values: ZenSeq[ZenValue[string]]

  var src = Tree().init_zen_fields(ctx = ctx1)
  ctx2.recv
  var dest = Tree.init_from(src, ctx = ctx2)

  src.zen.value = "hello world"
  ctx2.recv

  check src.zen.value == "hello world"
  check dest.zen.value == "hello world"

  let thing = Thing(name: "Vin")
  src.things += thing
  ctx2.recv

  check dest.things.len == 1
  check dest.things[0].name == "Vin"

  src.things -= thing

  ctx2.recv
  check dest.things.len == 0

  var s3 = ZenValue[string].init(ctx = ctx1)
  src.values += s3
  s3.value = "hi"

  ctx2.recv
  check dest.values[^1].value == "hi"
