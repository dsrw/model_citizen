import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation, intsets, strformat]
import pkg / threading / channels
import pkg/print

type
  ZID* = uint16
  ChangeKind* = enum
    Created, Added, Removed, Modified, Touched, Closed

  ZenBase = object of RootObj
    id: int
    link_zid: ZID
    paused_zids: set[ZID]
    track_children: bool
    build_message: proc(self: ref ZenBase, change: BaseChange): Message
    change_receiver: proc(self: ref ZenBase, msg: Message)
    ctx: ZenContext

  ZenObject[T, O] = object of ZenBase
    tracked: T
    changed_callbacks: OrderedTable[ZID, proc(changes: seq[Change[O]], zid: ZID)]

  Zen*[T, O] = ref object of ZenObject[T, O]

  ZenTable*[K, V] = Zen[Table[K, V], Pair[K, V]]
  ZenSeq*[T] = Zen[seq[T], T]
  ZenSet*[T] = Zen[set[T], T]
  ZenValue*[T] = Zen[T, T]

  BaseChange* = ref object of RootObj
    changes*: set[ChangeKind]
    field_name*: string
    triggered_by*: seq[BaseChange]
    triggered_by_type*: string
    type_name*: string

  MessageKind = enum
    Create, Assign, Unassign

  Wrapper[T] = ref object of RootRef
    item: T

  Message = object
    kind: MessageKind
    object_id: int
    obj: ref RootObj

  Change*[O] = ref object of BaseChange
    item*: O

  Pair*[K, V] = tuple[key: K, value: V]

  ZenContext* = ref object
    changed_callback_zid: ZID
    last_id: int
    close_procs: Table[ZID, proc()]
    objects: Table[int, ref ZenBase]
    subscribers: seq[ZenContext]
    name: string
    skip_next_publish: bool
    chan: Chan[Message]

var active_ctx {.threadvar.}: ZenContext

proc init*(_: type ZenContext, name = "default-" & $get_thread_id() ): ZenContext =
  result = ZenContext(name: name)
  result.chan = new_chan[Message]()

proc ctx(): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(name = "default-" & $get_thread_id() )
  active_ctx

proc ctx(self: Zen) = self.ctx

proc init[T](_: type Change, item: T, changes: set[ChangeKind], field_name = ""): Change[T] =
  Change[T](item: item, changes: changes, type_name: $Change[T], field_name: field_name)

proc init(_: type Change, T: type, changes: set[ChangeKind], field_name = ""): Change[T] =
  Change[T](changes: changes, type_name: $Change[T], field_name: field_name)

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
    for zid, callback in callbacks.pairs:
      if zid in self.changed_callbacks and zid notin self.paused_zids:
        callback(changes, zid)

proc pause_changes*(self: Zen, zids: varargs[ZID]) =
  if zids.len == 0:
    for zid in self.changed_callbacks.keys:
      self.paused_zids.incl(zid)
  else:
    for zid in zids: self.paused_zids.incl(zid)

proc resume_changes*(self: Zen, zids: varargs[ZID]) =
  if zids.len == 0:
    self.paused_zids = {}
  else:
    for zid in zids: self.paused_zids.excl(zid)

template pause_impl(self: Zen, zids: untyped, body: untyped) =
  let previous = self.paused_zids
  for zid in zids:
    self.paused_zids.incl(zid)
  try:
    body
  finally:
    self.paused_zids = previous

template pause*(self: Zen, zids: varargs[ZID], body: untyped) =
  pause_impl(self, zids, body)

template pause*(self: Zen, body: untyped) =
  pause_impl(self, self.changed_callbacks.keys, body)

proc link_child[K, V](self: ZenTable[K, V], child, obj: Pair[K, V], field_name = "") =
  let field_name = field_name
  proc link[S, K, V, T, O](self: S, pair: Pair[K, V], child: Zen[T, O]) =
    child.link_zid = child.track proc(changes: seq[Change[O]]) =
      if changes.len == 1 and changes[0].changes == {Closed}:
        # Don't propagate Closed changes
        return
      let change = Change.init(pair, {Modified})
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
    child.link_zid = child.track proc(changes: seq[Change[O]]) =
      if changes.len == 1 and changes[0].changes == {Closed}:
        # Don't propagate Closed changes
        return

      let change = Change.init(obj, {Modified}, field_name = field_name)
      change.triggered_by = cast[seq[BaseChange]](changes)
      change.triggered_by_type = $O
      self.trigger_callbacks(@[change])

  if not child.is_nil:
    link(child)

proc unlink(self: Zen) =
  self.untrack(self.link_zid)
  self.link_zid = 0

proc unlink[T: Pair](pair: T) =
  pair.value.untrack(pair.value.link_zid)
  pair.value.link_zid = 0

template deref(o: ref): untyped = o[]
template deref(o: not ref): untyped = o

proc link_or_unlink[T, O](self: Zen[T, O], change: Change[O], link: bool) =
  template value(change: Change[Pair]): untyped = change.item.value
  template value(change: not Change[Pair]): untyped = change.item

  if self.track_children:
    if link:
      when change.value is Zen:
        self.link_child(change.item, change.item)
      elif change.value is object or change.value is ref:
        for name, val in change.value.deref.field_pairs:
          when val is Zen:
            if not val.is_nil:
              self.link_child(val, change.item, name)
    else:
      when change.value is Zen:
        if not change.value.is_nil:
          change.value.unlink
      elif change.value is object or change.value is ref:
        for name, val in change.value.deref.field_pairs:
          when val is Zen:
            if not val.is_nil:
              val.unlink

proc link_or_unlink[T, O](self: Zen[T, O], changes: seq[Change[O]], link: bool) =
  if self.track_children:
    for change in changes:
      self.link_or_unlink(change, link)

proc recv(self: ZenContext) =
  var msg: Message
  while self.chan.try_recv(msg):
    if msg.kind == Create:
      let wrapper = Wrapper[proc(ctx: ZenContext)](msg.obj)
      wrapper.item(self)
    else:
      let obj = self.objects[msg.object_id]
      obj.change_receiver(obj, msg)

# not threadsafe
proc poll_subscribers(self: ZenContext) =
  for ctx in self.subscribers:
    ctx.recv

proc publish_create[T, O](self: Zen[T, O]) =
  var wrapper = Wrapper[proc(ctx: ZenContext)]()
  let value = self.tracked.deep_copy

  wrapper.item = proc(ctx: ZenContext) =
    ctx.skip_next_publish = true
    discard Zen.init(value, ctx = ctx)

  for ctx in self.ctx.subscribers:
    let msg = Message(kind: Create, obj: wrapper, object_id: self.id)
    ctx.chan.send unsafe_isolate(msg)

  self.ctx.poll_subscribers

proc publish_changes[T, O](self: Zen[T, O], changes: seq[Change[O]]) =
  if self.ctx.skip_next_publish:
    self.ctx.skip_next_publish = false
  else:
    let id = self.id
    for ctx in self.ctx.subscribers:
      for change in changes:
        if [Added, Removed, Created].any_it(it in change.changes):
          assert id in ctx.objects
          let obj = ctx.objects[id]
          var msg = obj.build_message(obj, change)
          msg.object_id = id
          ctx.chan.send unsafe_isolate(msg)
    self.ctx.poll_subscribers

proc process_changes[T](self: Zen[T, T], initial: T, touch = false) =
  if initial != self.tracked:
    var add_flags = {Added, Modified}
    if touch: add_flags.incl Touched
    let changes = @[
      Change.init(initial, {Removed, Modified}),
      Change.init(self.tracked, add_flags)
    ]
    self.trigger_callbacks(changes)
    self.publish_changes(changes)
  elif touch:
    let changes = @[Change.init(self.tracked, {Touched})]
    self.trigger_callbacks(changes)
    self.publish_changes(changes)

proc process_changes[T: seq | set, O](self: Zen[T, O], initial: T, touch = T.default) =
  let added = (self.tracked - initial).map_it:
    let changes = if it in touch: {Touched} else: {}
    Change.init(it, {Added} + changes)
  let removed = (initial - self.tracked).map_it Change.init(it, {Removed})

  var touched: seq[Change[O]]
  for item in touch:
    if item in initial:
      touched.add Change.init(item, {Touched})

  self.link_or_unlink(removed, false)
  self.link_or_unlink(added, true)

  let changes = removed & added & touched
  self.trigger_callbacks(changes)
  self.publish_changes(changes)

proc process_changes[K, V](self: Zen[Table[K, V], Pair[K, V]], initial_table: Table[K, V]) =
  let
    tracked: seq[Pair[K, V]] = self.tracked.pairs.to_seq
    initial: seq[Pair[K, V]] = initial_table.pairs.to_seq

    added = (tracked - initial).map_it:
      var changes = {Added}
      if it.key in initial_table: changes.incl Modified
      Change.init(it, changes)

    removed = (initial - tracked).map_it:
      var changes = {Removed}
      if it.key in self.tracked: changes.incl Modified
      Change.init(it, changes)

  self.link_or_unlink(removed, false)
  self.link_or_unlink(added, true)
  let changes = removed & added
  self.trigger_callbacks(removed & added)
  self.publish_changes(changes)

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
  if self.tracked != value:
    mutate:
      self.tracked = value

proc value*[T, O](self: Zen[T, O]): T = self.tracked

proc `[]`*[K, V](self: Zen[Table[K, V], Pair[K, V]], index: K): V =
  self.tracked[index]

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal | BackwardsIndex): T =
  self.tracked[index]

proc `[]=`*[K, V](self: ZenTable[K, V], key: K, value: V) =
  if key in self.tracked and self.tracked[key] != value:
    let removed = Change.init(Pair[K, V] (key, self.tracked[key]), {Removed, Modified})
    let added = Change.init(Pair[K, V] (key, value), {Added, Modified})
    when value is Zen:
      if not removed.item.value.is_nil:
        self.link_or_unlink(removed, false)
      self.link_or_unlink(added, true)
    self.tracked[key] = value
    self.trigger_callbacks(@[removed, added])
  elif key notin self.tracked:
    let added = Change.init((key, value), {Added})
    when value is Zen:
      self.link_or_unlink(added, true)
    self.tracked[key] = value
    self.trigger_callbacks(@[added])

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T) =
  mutate:
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O) =
  self.tracked.add value
  let added = @[Change.init(value, {Added})]
  self.link_or_unlink(added, true)
  self.trigger_callbacks(added)
  self.publish_changes(added)

template remove(self, key, item_exp, fun) =
  let obj = item_exp
  self.tracked.fun key
  let removed = @[Change.init(obj, {Removed})]
  self.link_or_unlink(removed, false)
  self.trigger_callbacks(removed)
  self.publish_changes(removed)

proc del*[T, O](self: Zen[T, O], value: O) =
  if value in self.tracked:
    remove(self, value, value, del)

proc del*[K, V](self: ZenTable[K, V], key: K) =
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), del)

proc del*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], del)

proc delete*[T, O](self: Zen[T, O], value: O) =
  if value in self.tracked:
    remove(self, value, value, delete)

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), delete)

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], delete)

proc touch*[T: set, O](self: Zen[T, O], value: O) =
  self.change_and_touch({value}, true)

proc touch*[T: seq, O](self: Zen[T, O], value: O) =
  self.change_and_touch(@[value], true)

proc touch*[T, O](self: Zen[T, O], value: T) =
  self.change_and_touch(value, true)

proc touch*[T](self: ZenValue[T], value: T) =
  mutate_and_touch(touch = true):
    self.tracked = value

proc len*(self: Zen): int = self.tracked.len

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  self.change(value, true)

proc `+=`*[O](self: ZenSet[O], value: O) =
  self.change({value}, true)

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  self.add(value)

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  self.change(value, false)

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  self.change({value}, false)

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  self.change(@[value], false)

proc `&=`*[T, O](self: Zen[T, O], value: O) =
  self.value = self.value & value

proc `==`*(a, b: Zen): bool =
  (a.is_nil and b.is_nil) or
    not a.is_nil and not b.is_nil and
    a.tracked == b.tracked

proc assign[O](self: ZenSeq[O], value: O) =
  self.add(value)

proc assign[O](self: ZenSet[O], value: O) =
  self.change({value}, add = true)

proc assign[K, V](self: ZenTable[K, V], pair: Pair[K, V]) =
  self[pair.key] = pair.value

proc assign[T, O](self: Zen[T, O], value: O) =
  self.value = value

proc unassign[O](self: ZenSeq[O], value: O) =
  self -= value

proc unassign[O](self: ZenSet[O], value: O) =
  self -= value

proc unassign[K, V](self: ZenTable[K, V], pair: Pair[K, V]) =
  self.del(pair.key)

proc unassign[T, O](self: Zen[T, O], value: O) =
  discard

proc defaults[T, O](self: Zen[T, O], ctx: ZenContext): Zen[T, O] =
  ctx.last_id.inc
  self.id = ctx.last_id
  ctx.objects[self.id] = self

  self.build_message = proc(self: ref ZenBase, change: BaseChange): Message =
    assert Added in change.changes or Removed in change.changes
    let change = Change[O](change)
    when change.item is ZenBase:
      var wrapper = Wrapper[int]()
      wrapper.item = ZenBase(change.item).id
    else:
      var wrapper = Wrapper[change.item.type]()
      wrapper.item = change.item
    result.obj = wrapper

    result.kind = if Added in change.changes: Assign else: Unassign

  self.change_receiver = proc(self: ref ZenBase, msg: Message) =
    assert self of Zen[T, O]
    let self = Zen[T, O](self)
    when O is ZenBase:
      let object_id = Wrapper[int](msg.obj).item
      let item = self.ctx.objects[object_id]
    else:
      let item = Wrapper[O](msg.obj).item

    self.ctx.skip_next_publish = true
    if msg.kind == Assign:
      self.assign(item)
    elif msg.kind == Unassign:
      self.unassign(item)
    else:
      assert false, "Can't handle message " & $msg.kind

  assert self.ctx == nil
  self.ctx = ctx

  # TODO: fix this. Skip next is usually a bad idea.
  if self.ctx.skip_next_publish:
    self.ctx.skip_next_publish = false
  else:
    self.publish_create
  self

proc init*(T: type Zen, track_children = true, ctx = ctx()): T =
  T(track_children: track_children).defaults(ctx)

proc init*(_: type Zen, T: type[ref | object | SomeOrdinal | SomeNumber | string], track_children = true, ctx = ctx()): Zen[T, T] =
  result = Zen[T, T](track_children: track_children).defaults(active_ctx)

proc init*[T: ref | object | SomeOrdinal | SomeNumber | string](_: type Zen, tracked: T, track_children = true, ctx = ctx()): Zen[T, T] =
  var self = Zen[T, T](track_children: track_children).defaults(ctx)
  mutate:
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: set[O], track_children = true, ctx = ctx()): Zen[set[O], O] =
  var self = Zen[set[O], O](track_children: track_children).defaults(ctx)
  mutate:
    self.tracked = tracked
  result = self

proc init*[K, V](_: type Zen, tracked: Table[K, V], track_children = true, ctx = ctx()): ZenTable[K, V] =
  var self = ZenTable[K, V](track_children: track_children).defaults(ctx)
  mutate:
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: open_array[O], track_children = true, ctx = ctx()): Zen[seq[O], O] =
  var self = Zen[seq[O], O](track_children: track_children).defaults(ctx)
  mutate:
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: type Zen, T: type seq[O], track_children = true, ctx = ctx()): Zen[seq[O], O] =
  result = Zen[seq[O], O](track_children: track_children).defaults(ctx)

proc init*[O](_: type Zen, T: type set[O], track_children = true, ctx = ctx()): Zen[set[O], O] =
  result = Zen[set[O], O](track_children: track_children).defaults(ctx)

proc init*[K, V](_: type Zen, T: type Table[K, V], track_children = true, ctx = ctx()): Zen[Table[K, V], Pair[K, V]] =
  result = Zen[Table[K, V], Pair[K, V]](track_children: track_children).defaults(ctx)

proc init*(_: type Zen, K, V: type, track_children = true, ctx = ctx()): ZenTable[K, V] =
  result = ZenTable[K, V](track_children: track_children).defaults(ctx)

proc `[]`*[T, O](self: ZenContext, src: Zen[T, O]): Zen[T, O] =
  result = Zen[T, O](self.objects[src.id])

proc init*[K, V](t: type Zen, tracked: open_array[(K, V)], track_children = true, ctx = ctx()): ZenTable[K, V] =
  result = Zen.init(tracked.to_table, track_children = track_children, ctx = ctx)

proc init*[T, O](self: var Zen[T, O], ctx = ctx()) =
  self = Zen[T, O].init(ctx = ctx)

proc init_zen_fields*[T: object or ref](self: T, ctx = ctx()): T {. discardable .} =
  result = self
  for _, val in self.deref.field_pairs:
    when val is Zen:
      val.init(ctx)

proc init_from*[T: object or ref](_: type T, src: T, ctx = ctx()): T {. discardable .} =
  result = T()
  for name, dest, src in result.deref.field_pairs(src.deref):
    when dest is Zen:
      dest = ctx[src]

template `%`*(body: untyped): untyped =
  Zen.init(body)

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]], zid: ZID)): ZID {.discardable.} =
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  self.changed_callbacks[zid] = callback
  self.ctx.close_procs[zid] = proc() =
    self.untrack(zid)
  result = zid

proc track*[T, O](self: Zen[T, O], callback: proc(changes: seq[Change[O]])): ZID {.discardable.} =
  self.track proc(changes, _: auto) = callback(changes)

template changes*[T, O](self: Zen[T, O], body) =
  self.track proc(changes: seq[Change[O]], zid {.inject.}: ZID) =
    self.pause(zid):
      for change {.inject.} in changes:
        template added: bool = Added in change.changes
        template added(obj: O): bool = change.item == obj and added()
        template removed: bool = Removed in change.changes
        template removed(obj: O): bool = change.item == obj and removed()
        template modified: bool = Modified in change.changes
        template modified(obj: O): bool = change.item == obj and modified()
        template touched: bool = Touched in change.changes
        template touched(obj: O): bool = change.item == obj and touched()
        template closed: bool = Closed in change.changes

        body

proc untrack*[T, O](self: Zen[T, O], zid: ZID) =
  if zid in self.changed_callbacks:
    let callback = self.changed_callbacks[zid]
    if zid notin self.paused_zids:
      callback(@[Change.init(O, {Closed})], zid)
    self.ctx.close_procs.del(zid)
    self.changed_callbacks.del(zid)

proc untrack_all*[T, O](self: Zen[T, O]) =
  self.trigger_callbacks(@[Change.init(O, {Closed})])
  for zid, _ in self.changed_callbacks:
    self.ctx.close_procs.del(zid)
  self.changed_callbacks.clear

proc untrack*(ctx: ZenContext, zid: ZID) =
  if zid in ctx.close_procs:
    ctx.close_procs[zid]()

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

  block primitives:
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

  block refs:
    type ARef = ref object
      val: int

    let (r1, r2, r3) = (ARef(val: 1), ARef(val:2), ARef(val:3))

    let a = %r1
    a.assert_changes {Removed: r1, Added: r2, Removed: r2, Added: r3}:
      a.value = r2
      a.value = r3

  block pausing:
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
    assert calls == 2

  block closed:
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
    ctx().untrack(zid)
    check changed == true

  block init_props:
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

  block sync:
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")
      s1 = ZenValue[string].init(ctx = ctx1)
      s2 = ZenValue[string].init(ctx = ctx2)

    s1.ctx.subscribers.add(ctx2)
    s2.ctx.subscribers.add(ctx1)

    s1.value = "sync me"

    assert s2.value == s1.value

    s1 &= " and me"
    assert s2.value == s1.value and s2.value == "sync me and me"

    type
      Thing = ref object
        name: string

      Tree = ref object
        zen: ZenValue[string]
        things: ZenSeq[Thing]
        values: ZenSeq[ZenValue[string]]

    var
      src = Tree().init_zen_fields(ctx = ctx1)
      dest = Tree.init_from(src, ctx = ctx2)

    src.zen.value = "hello world"
    assert src.zen.tracked == "hello world"
    assert dest.zen.value == "hello world"

    let thing = Thing(name: "Vin")
    src.things += thing
    assert dest.things.len == 1
    assert dest.things[0].name == "Vin"

    src.things -= thing
    assert dest.things.len == 0

    var s3 = ZenValue[string].init(ctx = ctx1)
    src.values += s3
    s3.value = "hi"

    assert dest.values[^1].value == "hi"

    echo "done"
