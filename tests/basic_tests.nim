import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
    unittest, deques, importutils, monotimes]
import pkg/print
import model_citizen
from model_citizen {.all.} import ref_id, CountedRef

proc main =
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

  template recv =
    Zen.thread_ctx = ctx2
    ctx2.recv
    Zen.thread_ctx = ctx1

  template assert_changes[T, O](self: Zen[T, O], expect, body: untyped) =
    var expectations = expect.to_deque
    self.track proc(changes: seq[Change[O]]) {.gcsafe.} =
      for change in changes:
        let expectation = expectations.pop_first()
        if not (expectation[0] in change.changes and
          expectation[1] == change.item):
          error "unsatisfied expectation", expectation
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

    var added {.threadvar.}: set[TestFlags]
    var removed {.threadvar.}: set[TestFlags]

    let zid = s.track proc(changes, zid: auto) {.gcsafe.} =
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
    s.track proc(changes, zid: auto) {.gcsafe.} =
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
      added_items {.threadvar.}: seq[string]
      removed_items {.threadvar.}: seq[string]

    var id = s.track proc(changes: auto) {.gcsafe.} =
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

  test "table literals":
    var a = Zen.init(Table[int, ZenSeq[string]])
    a.track proc(changes, _: auto) {.gcsafe.} =
      discard
    a[1] = %["nim"]
    a[5] = %["vin", "rw"]
    a.clear

  test "touch table":
    var a = ZenTable[string, string].init
    let zid = a.count_changes

    1.changes: a["hello"] = "world"
    0.changes: a["hello"] = "world"
    1.changes: a.touch("hello", "world")
    a.untrack_all

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
    id = buffers.track proc(changes, _: auto) {.gcsafe.} =
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
    var a = ZenTable[int, string].init(id = "1")
    var b = Zen[Table[int, string], Pair[int, string]].init(id = "1")
    var c = ZenTable[string, int].init(id = "2")
    check b is ZenTable[int, string]
    check a == b
    when compiles(a == c):
      check false, &"{a.type} and {b.type} shouldn't be comparable"

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

      Unit = ref object of RootRef
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

    var triggered_by {.threadvar.}: seq[seq[BaseChange]]
    a.units.track proc(changes: auto) {.gcsafe.} =
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
    type ARef = ref object of RootObj
      id: int

    let (r1, r2, r3) = (ARef(id: 1), ARef(id:2), ARef(id:3))

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

    s.track proc(changes: auto) {.gcsafe.} =
      changed = true
      check changes[0].changes == {Closed}
    s.untrack_all
    check changed == true

    changed = false
    let zid = s.track proc(changes: auto) {.gcsafe.} =
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

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    var s1 = ZenValue[string].init(ctx = ctx1)
    recv
    var s2 = ZenValue[string](ctx2[s1])
    check s2.ctx != nil
    s1.value = "sync me"

    recv

    check s2.value == s1.value

    s1 &= " and me"

    recv

    check s2.value == s1.value and s2.value == "sync me and me"

    type
      Thing = ref object of RootObj
        id: string

      Tree = ref object
        zen: ZenValue[string]
        things: ZenSeq[Thing]
        values: ZenSeq[ZenValue[string]]

      Container = ref object
        thing1: ZenValue[Thing]
        thing2: ZenValue[Thing]

    Zen.register_type(Thing)

    var msg = "hello world"
    var another_msg = "another"
    var src = Tree().init_zen_fields(ctx = ctx1)
    recv
    var dest = Tree.init_from(src, ctx = ctx2)

    src.zen.value = "hello world"
    recv
    check src.zen.value == "hello world"
    check dest.zen.value == "hello world"

    let thing = Thing(id: "Vin")
    src.things += thing
    recv
    check dest.things.len == 1
    check dest.things[0] != nil
    check dest.things[0].id == "Vin"

    src.things -= thing
    check src.things.len == 0

    recv
    check dest.things.len == 0

    var container = Container().init_zen_fields(ctx = ctx1)

    var t = Thing(id: "Scott")
    ctx2.recv
    var remote_container = Container.init_from(container, ctx = ctx2)
    container.thing1.value = t
    container.thing2.value = t

    check container.thing1.value == container.thing2.value
    recv

    check remote_container.thing1.value.id == container.thing1.value.id
    check remote_container.thing1.value == remote_container.thing2.value
    var s3 = ZenValue[string].init(ctx = ctx1)
    src.values += s3
    s3.value = "hi"
    recv
    check dest.values[^1].value == "hi"

    var ctx3 = ZenContext.init(name = "ctx3")
    Zen.thread_ctx = ctx3
    ctx3.subscribe(ctx2)
    ctx3.subscribe(ctx1)
    Zen.thread_ctx = ctx1
    check ctx3.len == ctx1.len
    src.values += Zen.init("", ctx = ctx1)
    check ctx1.len != ctx2.len and ctx1.len != ctx3.len
    recv
    check ctx1.len == ctx2.len and ctx1.len != ctx3.len
    Zen.thread_ctx = ctx3
    ctx3.recv
    Zen.thread_ctx = ctx1
    check ctx1.len == ctx2.len and ctx1.len == ctx3.len

  test "delete":
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    var a = Zen.init("", ctx = ctx1)
    check ctx1.len == 1
    recv
    check ctx1.len == 1
    check ctx2.len == 1

    a.destroy
    check ctx1.len == 0
    recv
    check ctx1.len == 0
    check ctx2.len == 0

  test "sync nested":
    type
      Unit = ref object of RootObj
        units: ZenSeq[Unit]
        code: ZenValue[string]
        id: int

    Zen.register_type(Unit)

    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    Zen.thread_ctx = ctx1

    var u1 = Unit(id: 1)
    var u2 = Unit(id: 2)
    u1.init_zen_fields
    u2.init_zen_fields

    recv

    var ru1 = Unit.init_from(u1, ctx = ctx2)

    u1.units += u2
    recv

    check ru1.units[0].code.ctx == ctx2


  test "zentable of tables":
    type
      Shared = ref object of RootObj
        id: string
        edits: ZenTable[int, Table[string, string]]

    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    Zen.thread_ctx = ctx1

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    Zen.register_type(Shared)

    var container: ZenValue[Shared]
    container.init

    var shared = Shared(id: "1")
    shared.init_zen_fields

    container.value = shared
    container.value.edits[1] = init_table[string, string]()

    recv

    var dest = type(container)(ctx2[container])
    check 1 in container.value.edits

  test "zentable of zentables":
    type
      Block = ref object of RootObj
        id: string
        chunks: ZenTable[int, ZenTable[string, string]]

    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    Zen.thread_ctx = ctx1

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    var container: ZenValue[Block]
    container.init

    var shared = Block(id: "2")
    shared.init_zen_fields

    recv
    var shared2 = Block.init_from(shared, ctx = ctx2)

    shared.chunks[1] = ZenTable[string, string].init
    shared.chunks[1]["hello"] = "world"
    Zen.thread_ctx = ctx2
    ctx2.recv

    check addr(shared.chunks[]) != addr(shared2.chunks[])
    check shared2.chunks[1]["hello"] == "world"

    shared2.chunks[1]["hello"] = "goodbye"
    Zen.thread_ctx = ctx1
    ctx1.recv

    check shared.chunks[1]["hello"] == "goodbye"

  test "free refs":
    type
      RefType = ref object of RootObj
        id: string

    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    Zen.thread_ctx = ctx1

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    Zen.register_type(RefType)

    var src = ZenSeq[RefType].init

    var obj = RefType(id: "1")

    src += obj

    recv
    var dest = ZenSeq[RefType](ctx2[src])

    private_access ZenContext
    private_access CountedRef

    check obj.ref_id in ctx1.ref_pool
    check obj.ref_id in ctx2.ref_pool
    check obj.ref_id notin ctx2.freeable_refs

    let orig_dest_obj = RefType(ctx2.ref_pool[obj.ref_id].obj)
    src -= obj
    recv
    check obj.ref_id in ctx2.ref_pool
    check obj.ref_id in ctx2.freeable_refs
    check ctx2.ref_pool[obj.ref_id].count == 0

    src += obj
    recv
    check obj.ref_id in ctx2.ref_pool
    check obj.ref_id in ctx2.freeable_refs
    check ctx2.ref_pool[obj.ref_id].count == 1
    check dest[0] == orig_dest_obj
    src -= obj
    recv

    # after a timeout the unreferenced object will be removed
    # from the dest ref_pool and freeable_refs, and if we add
    # it back to src a new object will be created in dest
    ctx2.freeable_refs[obj.ref_id] = MonoTime.low
    recv
    check obj.ref_id notin ctx2.ref_pool
    check obj.ref_id notin ctx2.freeable_refs
    check dest.len == 0

    src += obj
    recv
    check dest[0].id == orig_dest_obj.id
    check dest[0] != orig_dest_obj

  test "sync pointer":
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")

    Zen.thread_ctx = ctx1

    ctx1.subscribe(ctx2)
    ctx2.subscribe(ctx1)

    let msg = "hello world"
    var src = ZenValue[ptr string].init
    recv
    var dest = ZenValue[ptr string](ctx2[src])
    src.value = addr msg
    check src.value[] == msg
    recv
    check dest.value[] == msg

main()
