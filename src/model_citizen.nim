
include prelude

template setup_op_ctx(self: ZenContext) =
  let op_ctx = if op_ctx == OperationContext.default:
    OperationContext(source: self.name)
  else:
    op_ctx

proc lookup_type(key: int, registered_type: var RegisteredType): bool =
  if key in local_type_registry:
    registered_type = local_type_registry[key]
    result = true
  elif key in processed_types:
    # we don't want to lookup a type in the global registry if we've already
    # tried, since it needs a lock
    result = false
  else:
    processed_types.incl(key)
    with_lock:
      if key in type_registry[]:
        registered_type = type_registry[][key]
        local_type_registry[key] = registered_type
        result = true

proc lookup_type(obj: ref RootObj, registered_type: var RegisteredType): bool =
  result = lookup_type(obj.type_id, registered_type)

  if not result:
    debug "type not registered", type_name = obj.base_type

proc ref_id[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

proc find_ref[T](self: ZenContext, value: var T): bool

type FlatRef = tuple[tid: int, ref_id: string, item: string]

type ZenFlattyInfo = tuple[object_id: string, tid: int]

proc to_flatty*[T: ref RootObj](s: var string, x: T) =
  when x is ref ZenBase:
    s.to_flatty x.is_nil
    if not x.is_nil:
      s.to_flatty ZenFlattyInfo((x.id, x.type.tid))
  else:
    var registered_type: RegisteredType
    when compiles(x.id):
      if not x.is_nil and x.lookup_type(registered_type):
        s.to_flatty true
        let obj: FlatRef = (tid: registered_type.tid, ref_id: x.ref_id,
            item: registered_type.stringify(x))

        flatty.to_flatty(s, obj)
        return
    s.to_flatty false
    s.to_flatty x.is_nil
    if not x.is_nil:
      flatty.to_flatty(s, x)

proc from_flatty*[T: ref RootObj](s: string, i: var int, value: var T) =
  when value is ref ZenBase:
    var is_nil: bool
    s.from_flatty(i, is_nil)
    if not is_nil:
      var info: ZenFlattyInfo
      s.from_flatty(i, info)
      value = value.type()(flatty_ctx.objects[info.object_id])
  else:
    var is_registered: bool
    s.from_flatty(i, is_registered)
    if is_registered:
      var val: FlatRef
      flatty.from_flatty(s, i, val)

      if val.ref_id in flatty_ctx.ref_pool:
        value = value.type()(flatty_ctx.ref_pool[val.ref_id].obj)
      else:
        var registered_type: RegisteredType
        assert lookup_type(val.tid, registered_type)
        value = value.type()(registered_type.parse(flatty_ctx, val.item))
    else:
      var is_nil: bool
      s.from_flatty(i, is_nil)
      if not is_nil:
        value = value.type()()
        value[] = flatty.from_flatty(s, value[].type)

proc to_flatty*(s: var string, x: proc) =
  discard

proc from_flatty*(s: string, i: var int, p: proc) =
  discard

proc to_flatty*(s: var string, p: ptr) =
  discard

proc to_flatty*(s: var string, p: pointer) =
  discard

proc from_flatty*(s: string, i: var int, p: pointer) =
  discard

proc from_flatty*(s: string, i: var int, p: ptr) =
  discard

proc from_flatty*(bin: string, T: type, ctx: ZenContext): T =
  flatty_ctx = ctx
  result = flatty.from_flatty(bin, T)

proc register_type*(_: type Zen, typ: type) =
  log_defaults
  let key = typ.type_id

  with_lock:
    assert key notin type_registry[], "Type already registered"

  let stringify = func(self: ref RootObj): string =
    let self = typ(self)
    var clone = new typ
    clone[] = self[]
    for src, dest in fields(self[], clone[]):
      when src is Zen:
        if not src.is_nil:
          var field = type(src)()
          field.id = src.id
          dest = field
      elif src is ref:
        dest = nil
      elif (src is proc):
        dest = nil
      elif src.has_custom_pragma(zen_ignore):
        dest = dest.type.default
    {.no_side_effect.}:
      result = flatty.to_flatty(clone[])

  let parse = func(ctx: ZenContext, clone_from: string): ref RootObj =
    var self = typ()
    {.no_side_effect.}:
      self[] = from_flatty(clone_from, self[].type, ctx)
    for field in self[].fields:
      when field is Zen:
        if not field.is_nil and field.id in ctx:
          field = type(field)(ctx[field.id])
    result = self

  with_lock:
    type_registry[][key] = RegisteredType(stringify: stringify, parse: parse,
        tid: key)

proc clear*(self: ZenContext) =
  debug "Clearing ZenContext"
  self.objects.clear

proc init[T](_: type Change, item: T,
  changes: set[ChangeKind], field_name = ""): Change[T] =

  result = Change[T](item: item, changes: changes,
    type_name: $Change[T], field_name: field_name)

proc init(_: type Change,
  T: type, changes: set[ChangeKind], field_name = ""): Change[T] =

  Change[T](changes: changes, type_name: $Change[T], field_name: field_name)

proc recv*(self: ZenContext,
    messages = int.high, max_duration = self.max_recv_duration, min_duration =
    self.min_recv_duration, blocking = self.blocking_recv) {.gcsafe.}

proc valid*[T: ref ZenBase](self: T): bool =
  not self.is_nil and not self.destroyed

proc valid*[T: ref ZenBase, V: ref ZenBase](self: T, value: V): bool =
  self.valid and value.valid and self.ctx == value.ctx

proc contains*[T, O](self: Zen[T, O], child: O): bool =
  assert self.valid
  child in self.tracked

proc contains*[K, V](self: ZenTable[K, V], key: K): bool =
  assert self.valid
  key in self.tracked

proc contains*[T, O](self: Zen[T, O], children: set[O] | seq[O]): bool =
  assert self.valid
  result = true
  for child in children:
    if child notin self:
      return false

proc contains*(self: ZenContext, zen: ref ZenBase): bool =
  assert zen.valid
  zen.id in self.objects

proc contains*(self: ZenContext, id: string): bool =
  id in self.objects

proc len*(self: ZenContext): int =
  self.objects.len

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

proc len[T, O](self: Zen[T, O]): int =
  assert self.valid
  self.tracked.len

proc trigger_callbacks[T, O](self: Zen[T, O], changes: seq[Change[O]]) =
  if changes.len > 0:
    let callbacks = self.changed_callbacks.dup
    for zid, callback in callbacks.pairs:
      if zid in self.changed_callbacks and zid notin self.paused_zids:
        callback(changes)

proc pause_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
  if zids.len == 0:
    for zid in self.changed_callbacks.keys:
      self.paused_zids.incl(zid)
  else:
    for zid in zids: self.paused_zids.incl(zid)

proc resume_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
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
  mixin valid
  assert self.valid
  pause_impl(self, zids, body)

template pause*(self: Zen, body: untyped) =
  mixin valid
  assert self.valid
  pause_impl(self, self.changed_callbacks.keys, body)

proc link_child[K, V](self: ZenTable[K, V],
  child, obj: Pair[K, V], field_name = "") =

  proc link[S, K, V, T, O](self: S, pair: Pair[K, V], child: Zen[T, O]) =
    log_defaults
    child.link_zid = child.track proc(changes: seq[Change[O]]) =
      if changes.len == 1 and changes[0].changes == {Closed}:
        # Don't propagate Closed changes
        return
      let change = Change.init(pair, {Modified})
      change.triggered_by = cast[seq[BaseChange]](changes)
      change.triggered_by_type = $O
      self.trigger_callbacks(@[change])
    debug "linking zen", child = ($child.type, $child.id),
        self = ($self.type, $self.id)

  if not child.value.is_nil:
    self.link(child, child.value)

proc link_child[T, O, L](self: ZenSeq[T], child: O, obj: L, field_name = "") =
  let
    field_name = field_name
    self = self
    obj = obj
  proc link[T, O](child: Zen[T, O]) =
    log_defaults
    child.link_zid = child.track proc(changes: seq[Change[O]]) =
      if changes.len == 1 and changes[0].changes == {Closed}:
        # Don't propagate Closed changes
        return

      let change = Change.init(obj, {Modified}, field_name = field_name)
      change.triggered_by = cast[seq[BaseChange]](changes)
      change.triggered_by_type = $O
      self.trigger_callbacks(@[change])
    debug "linking zen", child = ($child.type, $child.id),
        self = ($self.type, $self.id), zid = child.link_zid,
        child_addr = cast[int](unsafe_addr child[]).to_hex

  if not child.is_nil:
    link(child)

proc unlink(self: Zen) =
  log_defaults
  debug "unlinking", id = self.id, zid = self.link_zid
  self.untrack(self.link_zid)
  self.link_zid = 0

proc unlink[T: Pair](pair: T) =
  log_defaults
  debug "unlinking", id = pair.value.id, zid = pair.value.link_zid
  pair.value.untrack(pair.value.link_zid)
  pair.value.link_zid = 0

template deref(o: ref): untyped = o[]
template deref(o: not ref): untyped = o

proc link_or_unlink[T, O](self: Zen[T, O], change: Change[O], link: bool) =
  template value(change: Change[Pair]): untyped = change.item.value
  template value(change: not Change[Pair]): untyped = change.item

  if TrackChildren in self.flags:
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
        for field in change.value.deref.fields:
          when field is Zen:
            if not field.is_nil:
              field.unlink

proc link_or_unlink[T, O](self: Zen[T, O],
  changes: seq[Change[O]], link: bool) =

  if TrackChildren in self.flags:
    for change in changes:
      self.link_or_unlink(change, link)

proc find_ref[T](self: ZenContext, value: var T): bool =
  if not value.is_nil:
    let id = value.ref_id
    if id in self.ref_pool:
      value = T(self.ref_pool[id].obj)
      result = true

proc free_refs(self: ZenContext) =
  var to_remove: seq[string]
  for id, free_at in self.freeable_refs:
    assert self.ref_pool[id].count >= 0
    if self.ref_pool[id].count == 0 and free_at < get_mono_time():
      self.ref_pool.del(id)
      to_remove.add(id)
    elif self.ref_pool[id].count > 0:
      to_remove.add(id)
  for id in to_remove:
    self.freeable_refs.del(id)

proc free*[T: ref RootObj](self: ZenContext, value: T) =
  let id = value.ref_id
  assert id in self.freeable_refs
  assert self.ref_pool[id].count == 0
  self.ref_pool.del(id)
  self.freeable_refs.del(id)

proc ref_count[O](self: ZenContext, changes: seq[Change[O]]) =
  log_defaults

  for change in changes:
    if change.item.is_nil:
      continue
    let id = change.item.ref_id
    if Added in change.changes:
      if id notin self.ref_pool:
        debug "saving", id
        self.ref_pool[id] = CountedRef()
      inc self.ref_pool[id].count
      self.ref_pool[id].obj = change.item
    if Removed in change.changes:
      assert id in self.ref_pool
      dec self.ref_pool[id].count
      if self.ref_pool[id].count == 0:
        self.freeable_refs[id] = get_mono_time() + init_duration(seconds = 10)

proc process_message(self: ZenContext, msg: Message) =
  assert self.name notin msg.source
  when defined(zen_trace):
    let src = self.name & "-" & msg.source
    if src in self.last_received_id:
      if msg.id != self.last_received_id[src] + 1:
        raise_assert &"src={src} msg.id={msg.id} " &
            &"last={self.last_received_id[src]}. Should be msg.id - 1"
    self.last_received_id[src] = msg.id
    debug "receiving", msg

  var source = msg.source & " " & self.name

  if msg.kind == Create:
    assert msg.obj != ""
    {.gcsafe.}:
      let fn = type_initializers[msg.type_id]
      let args = msg.obj.from_flatty(CreatePayload, self)
      fn(args.bin, self, msg.object_id, args.flags,
          OperationContext(source: source))

  elif msg.kind == Destroy:
    let obj = self.objects[msg.object_id]
    assert obj.valid
    obj.destroyed = true
    self.objects.del(msg.object_id)
  elif msg.kind != Blank:
    let obj = self.objects[msg.object_id]
    obj.change_receiver(obj, msg, op_ctx = OperationContext(source: source))

  else:
    raise_assert "Can't recv a blank message"

proc send(self: ZenContext, sub: Subscription, msg: sink Message,
    op_ctx = OperationContext(), flags = default_flags) =

  when defined(zen_trace):
    if sub.ctx_name notin self.last_msg_id:
      self.last_msg_id[sub.ctx_name] = 1
    else:
      self.last_msg_id[sub.ctx_name] += 1
    msg.id = self.last_msg_id[sub.ctx_name]
  debug "sending", msg

  msg.source = op_ctx.source
  if msg.source == "":
    msg.source = self.name

  if sub.kind == Local and SyncLocal in flags:
    sub.chan.send(msg)
  elif sub.kind == Remote and SyncRemote in flags:
    self.reactor.send(sub.connection, msg.to_flatty.compress)

proc add_subscriber(self: ZenContext, sub: Subscription, push_all: bool,
    remote_objects: HashSet[string]) =

  debug "adding subscriber", sub
  self.subscribers.add sub
  for id in self.objects.keys.to_seq.reversed:
    if id notin remote_objects or push_all:
      let zen = self.objects[id]
      zen.publish_create sub

proc subscribe*(self: ZenContext, ctx: ZenContext, bidirectional = true) =
  debug "local subscribe", ctx = self.name
  var remote_objects: HashSet[string]
  for id in self.objects.keys:
    remote_objects.incl id
  ctx.add_subscriber(Subscription(kind: Local, chan: self.chan,
      ctx_name: self.name), push_all = bidirectional, remote_objects)

  self.recv(blocking = false, min_duration = Duration.default)
  if bidirectional:
    ctx.subscribe(self, bidirectional = false)

proc subscribe*(self: ZenContext, address: string, bidirectional = true,
    callback: proc() = nil) = # callback param is a hack to allow testing
    # networked contexts on the same thread. Not meant to be used in non-test
    # code

  debug "remote subscribe", address
  if self.reactor.is_nil:
    self.reactor = new_reactor()
  let connection = self.reactor.connect(address, port)
  self.send(Subscription(kind: Remote, ctx_name: "temp",
      connection: connection), Message(kind: Subscribe))

  var ctx_name = ""
  var received_objects: HashSet[string]
  var finished = false
  var remote_objects: HashSet[string]
  while not finished:
    self.reactor.tick
    for msg in self.reactor.messages:
      if msg.data.starts_with("ACK:"):
        if bidirectional:
          let pieces = msg.data.split(":")
          ctx_name = pieces[1]
          for id in pieces[2..^1]:
            remote_objects.incl id

        finished = true
      else:
        self.remote_messages &= msg
    if callback != nil:
      callback()

  if bidirectional:
    let sub = Subscription(kind: Remote, connection: connection,
        ctx_name: ctx_name)

    self.add_subscriber(sub, push_all = false, remote_objects)

  self.recv(blocking = false)

proc close*(self: ZenContext) =
  if not self.reactor.is_nil:
    private_access Reactor
    self.reactor.socket.close()
  self.reactor = nil

proc recv*(self: ZenContext,
    messages = int.high, max_duration = self.max_recv_duration, min_duration =
    self.min_recv_duration, blocking = self.blocking_recv) {.gcsafe.} =

  var msg: Message
  var count = 0
  self.free_refs
  let timeout = if max_duration == Duration.default:
    MonoTime.high
  else:
    get_mono_time() + max_duration
  let recv_until = if min_duration == Duration.default:
    MonoTime.low
  else:
    get_mono_time() + min_duration

  while true:
    while count < messages and self.chan.peek > 0 and
        get_mono_time() < timeout:

      self.chan.recv(msg)
      self.process_message(msg)
      inc count

    if not self.reactor.is_nil:
      self.reactor.tick()
      let messages = self.remote_messages & self.reactor.messages
      self.remote_messages = @[]

      for raw_msg in messages:
        inc count
        let msg = raw_msg.data.uncompress.from_flatty(Message, self)
        if msg.kind == Subscribe:
          var remote: HashSet[string]
          self.add_subscriber(Subscription(kind: Remote,
              connection: raw_msg.conn, ctx_name: msg.source),
              push_all = true, remote)

          var objects = self.objects.keys.to_seq.join(":")

          self.reactor.send(raw_msg.conn, "ACK:" & self.name & ":" & objects)
          self.reactor.tick
          self.remote_messages &= self.reactor.messages

        else:
          self.process_message(msg)

    if (count > 0 or not blocking) and get_mono_time() > recv_until:
      break

proc remaining*(self: Chan): range[0.0..1.0] =
  private_access Chan
  private_access ChannelObj
  let size = self.d[].size
  result = 1.0 - self.peek / size

proc pressure*(self: ZenContext): range[0.0..1.0] =
  1.0 - (@[self.chan.remaining] & self.subscribers.
      filter_it(it.kind == Local).
      map_it(it.chan.remaining)).min

proc chan_full*(self: Chan): bool =
  self.remaining < 0.1

proc publish_destroy[T, O](self: Zen[T, O], op_ctx: OperationContext) =
  log_defaults
  debug "destroy"
  for sub in self.ctx.subscribers:
    if sub.ctx_name notin op_ctx.source:
      when defined(zen_trace):
        self.ctx.send(sub, Message(kind: Destroy, object_id: self.id,
            trace: get_stack_trace()), op_ctx, self.flags)

      else:
        self.ctx.send(sub, Message(kind: Destroy, object_id: self.id),
            op_ctx, self.flags)

  if not self.ctx.reactor.is_nil:
    self.ctx.reactor.tick
    self.ctx.remote_messages &= self.ctx.reactor.messages

proc publish_changes[T, O](self: Zen[T, O], changes: seq[Change[O]],
    op_ctx: OperationContext) =

  log_defaults
  debug "publish_changes", ctx = self.ctx, op_ctx
  let id = self.id
  for sub in self.ctx.subscribers:
    if sub.ctx_name in op_ctx.source:
      continue
    for change in changes:
      if [Added, Removed, Created, Touched].any_it(it in change.changes):
        if Removed in change.changes and Modified in change.changes:
          # An assign will trigger both an assign and an unassign on the other
          # side. We only want to send a Removed message when an item is
          # removed from a collection.
          debug "skipping changes"
          continue
        assert id in self.ctx.objects
        let obj = self.ctx.objects[id]
        let trace = when defined(zen_trace):
          get_stack_trace()
        else:
          ""
        var msg = obj.build_message(obj, change, id, trace)
        self.ctx.send(sub, msg, op_ctx, self.flags)
    if not self.ctx.reactor.is_nil:
      self.ctx.reactor.tick
      self.ctx.remote_messages &= self.ctx.reactor.messages

proc process_changes[T](self: Zen[T, T], initial: sink T,
    op_ctx: OperationContext, touch = false) =

  if initial != self.tracked:
    var add_flags = {Added, Modified}
    var del_flags = {Removed, Modified}
    if touch:
      add_flags.incl Touched

    let changes = @[
      Change.init(initial, del_flags),
      Change.init(self.tracked, add_flags)
    ]
    when T isnot Zen and T is ref:
      self.ctx.ref_count(changes)

    self.publish_changes(changes, op_ctx)
    self.trigger_callbacks(changes)

  elif touch:
    let changes = @[Change.init(self.tracked, {Touched})]
    when T isnot Zen and T is ref:
      self.ctx.ref_count(changes)

    self.publish_changes(changes, op_ctx)
    self.trigger_callbacks(changes)

proc process_changes[T: seq | set, O](self: Zen[T, O],
    initial: sink T, op_ctx: OperationContext, touch = T.default) =

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
  when O isnot Zen and O is ref:
    self.ctx.ref_count(changes)

  self.publish_changes(changes, op_ctx)
  self.trigger_callbacks(changes)

proc process_changes[K, V](self: Zen[Table[K, V],
  Pair[K, V]], initial_table: sink Table[K, V], op_ctx: OperationContext) =

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
  when V isnot Zen and V is ref:
    self.ctx.ref_count(changes)

  self.publish_changes(changes, op_ctx)
  self.trigger_callbacks(changes)

template mutate_and_touch(touch, op_ctx, body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values, op_ctx, touch)

template mutate(op_ctx: OperationContext, body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values, op_ctx)

proc change[T, O](self: Zen[T, O], items: T, add: bool,
    op_ctx: OperationContext) =

  mutate(op_ctx):
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc change_and_touch[T, O](self: Zen[T, O], items: T, add: bool,
    op_ctx: OperationContext) =

  mutate_and_touch(touch = items, op_ctx):
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*[T, O](self: Zen[T, O]) =
  assert self.valid
  mutate(OperationContext(source: self.ctx.name)):
    self.tracked = T.default

proc `value=`*[T, O](self: Zen[T, O], value: T, op_ctx = OperationContext()) =
  assert self.valid
  self.ctx.setup_op_ctx
  if self.tracked != value:
    mutate(op_ctx):
      self.tracked = value

proc value*[T, O](self: Zen[T, O]): T =
  assert self.valid
  self.tracked

proc `[]`*[K, V](self: Zen[Table[K, V], Pair[K, V]], index: K): V =
  assert self.valid
  self.tracked[index]

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal | BackwardsIndex): T =
  assert self.valid
  self.tracked[index]

proc put[K, V](self: ZenTable[K, V], key: K, value: V, touch: bool,
    op_ctx: OperationContext) =

  assert self.valid

  if key in self.tracked and self.tracked[key] != value:
    let removed = Change.init(
      Pair[K, V] (key, self.tracked[key]), {Removed, Modified})

    var flags = {Added, Modified}
    if touch: flags.incl Touched
    let added = Change.init(Pair[K, V] (key, value), flags)
    when value is Zen:
      if not removed.item.value.is_nil:
        self.link_or_unlink(removed, false)
      self.link_or_unlink(added, true)
    self.tracked[key] = value
    let changes = @[removed, added]
    when V isnot Zen and V is ref:
      self.ctx.ref_count changes

    self.publish_changes changes, op_ctx
    self.trigger_callbacks changes

  elif key in self.tracked and touch:
    let changes = @[Change.init(Pair[K, V] (key, value), {Touched})]

    self.publish_changes changes, op_ctx
    self.trigger_callbacks changes

  elif key notin self.tracked:
    let added = Change.init((key, value), {Added})
    when value is Zen:
      self.link_or_unlink(added, true)
    self.tracked[key] = value
    let changes = @[added]
    when V isnot Zen and V is ref:
      self.ctx.ref_count changes

    self.publish_changes changes, op_ctx
    self.trigger_callbacks changes

proc `[]=`*[K, V](self: ZenTable[K, V], key: K, value: V,
    op_ctx = OperationContext()) =

  self.ctx.setup_op_ctx
  self.put(key, value, touch = false, op_ctx)

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T,
    op_ctx = OperationContext()) =

  self.ctx.setup_op_ctx
  assert self.valid
  mutate(op_ctx):
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  self.ctx.setup_op_ctx
  when O is Zen:
    assert self.valid(value)
  else:
    assert self.valid
  self.tracked.add value
  let added = @[Change.init(value, {Added})]
  self.link_or_unlink(added, true)
  when O isnot Zen and O is ref:
    self.ctx.ref_count(added)

  self.publish_changes(added, op_ctx)
  self.trigger_callbacks(added)

template remove(self, key, item_exp, fun, op_ctx) =
  let obj = item_exp
  self.tracked.fun key
  let removed = @[Change.init(obj, {Removed})]
  self.link_or_unlink(removed, false)
  when obj isnot Zen and obj is ref:
    self.ctx.ref_count(added)

  self.publish_changes(removed, op_ctx)
  self.trigger_callbacks(removed)

proc del*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  self.ctx.setup_op_ctx
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, del, op_ctx)

proc del*[K, V](self: ZenTable[K, V], key: K, op_ctx = OperationContext()) =
  self.ctx.setup_op_ctx
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), del, op_ctx)

proc del*[T: seq, O](self: Zen[T, O], index: SomeOrdinal,
    op_ctx = OperationContext()) =

  self.ctx.setup_op_ctx
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], del, op_ctx)

proc delete*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, delete,
        op_ctx = OperationContext(source: [self.ctx.name].to_hash_set))

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), delete,
        op_ctx = OperationContext())

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], delete,
        op_ctx = OperationContext())

proc touch[K, V](self: ZenTable[K, V], pair: Pair[K, V],
    op_ctx: OperationContext) =

  assert self.valid
  self.put(pair.key, pair.value, touch = true, op_ctx = op_ctx)

proc touch*[T, O](self: ZenTable[T, O], key: T, value: O,
    op_ctx = OperationContext()) =

  assert self.valid
  self.put(key, value, touch = true, op_ctx = op_ctx)

proc touch*[T: set, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch({value}, true, op_ctx = op_ctx)

proc touch*[T: seq, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch(@[value], true, op_ctx = op_ctx)

proc touch*[T, O](self: Zen[T, O], value: T, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch(value, true, op_ctx = op_ctx)

proc touch*[T](self: ZenValue[T], value: T, op_ctx = OperationContext()) =
  assert self.valid
  mutate_and_touch(touch = true, op_ctx):
    self.tracked = value

proc len*(self: Zen): int =
  assert self.valid
  self.tracked.len

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, true, op_ctx = OperationContext())

proc `+=`*[O](self: ZenSet[O], value: O) =
  assert self.valid
  self.change({value}, true, op_ctx = OperationContext())

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.add(value)

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, false, op_ctx = OperationContext())

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change({value}, false, op_ctx = OperationContext())

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change(@[value], false, op_ctx = OperationContext())

proc `&=`*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.value = self.value & value

proc `==`*(a, b: Zen): bool =
  a.is_nil == b.is_nil and a.destroyed == b.destroyed and
    a.tracked == b.tracked and a.id == b.id

proc assign[O](self: ZenSeq[O], value: O, op_ctx: OperationContext) =
  self.add(value, op_ctx = op_ctx)

proc assign[O](self: ZenSeq[O], values: seq[O], op_ctx: OperationContext) =
  for value in values:
    self.add(value, op_ctx = op_ctx)

proc assign[O](self: ZenSet[O], value: O, op_ctx: OperationContext) =
  self.change({value}, add = true, op_ctx = op_ctx)

proc assign[K, V](self: ZenTable[K, V], pair: Pair[K, V],
    op_ctx: OperationContext) =

  self.`[]=`(pair.key, pair.value, op_ctx = op_ctx)

proc assign[T, O](self: Zen[T, O], value: O, op_ctx: OperationContext) =
  self.`value=`(value, op_ctx)

proc unassign[O](self: ZenSeq[O], value: O, op_ctx: OperationContext) =
  self.change(@[value], false, op_ctx = op_ctx)

proc unassign[O](self: ZenSet[O], value: O, op_ctx: OperationContext) =
  self.change({value}, false, op_ctx = op_ctx)

proc unassign[K, V](self: ZenTable[K, V], pair: Pair[K, V],
    op_ctx: OperationContext) =

  self.del(pair.key, op_ctx = op_ctx)

proc unassign[T, O](self: Zen[T, O], value: O, op_ctx: OperationContext) =
  discard

proc defaults[T, O](self: Zen[T, O], ctx: ZenContext, id: string,
    op_ctx: OperationContext): Zen[T, O] {.gcsafe.} =

  log_defaults

  self.id = if id == "":
    $self.type & "-" & generate(
      alphabet = "abcdefghijklmnopqrstuvwxyz0123456789",
      size = 13
    )
  else:
    id

  ctx.objects[self.id] = self

  self.publish_create = proc(sub: Subscription, broadcast: bool,
      op_ctx = OperationContext()) {.gcsafe.} =

    debug "create", sub
    let bin = self.tracked.to_flatty
    let value: CreatePayload = (bin: bin, flags: self.flags,
        op_ctx: op_ctx)

    let id = self.id
    let flags = self.flags

    template send_msg(src_ctx, sub) =
      const zen_type_id = self.type.tid

      static:
        type value_type = self.tracked.type
        type zen_type = self.type

        initializers.add quote do:
          type_initializers[zen_type_id] = proc(bin: string, ctx: ZenContext,
              id: string, flags: set[ZenFlags], op_ctx: OperationContext) =

            if bin != "":
              var value = bin.from_flatty(`value_type`, ctx)
              if id notin ctx:
                discard Zen.init(value, ctx = ctx, id = id,
                    flags = flags, op_ctx)
              else:
                let item = `zen_type`(ctx[id])
                item.`value=`(value, op_ctx = op_ctx)
            else:
              raise_assert "shouldn't be here"

      var msg = Message(kind: Create, obj: value.to_flatty,
          type_id: zen_type_id, object_id: id, source: op_ctx.source)

      when defined(zen_trace):
        msg.trace = get_stack_trace()
        msg.debug = "value: " & $value

      src_ctx.send(sub, msg, op_ctx)

    if sub.kind != Blank:
      ctx.send_msg(sub)
    if broadcast:
      for sub in ctx.subscribers:
        if sub.ctx_name notin op_ctx.source:
          ctx.send_msg(sub)
    if not ctx.reactor.is_nil:
      ctx.reactor.tick
      ctx.remote_messages &= ctx.reactor.messages

  self.build_message = proc(self: ref ZenBase, change: BaseChange, id,
      trace: string): Message =

    var msg = Message(object_id: id, type_id: Zen[T, O].tid)
    assert Added in change.changes or Removed in change.changes or
      Touched in change.changes
    let change = Change[O](change)
    when change.item is Zen:
      msg.change_object_id = change.item.id
    elif change.item is Pair[any, Zen]:
      # TODO: Properly sync ref keys
      msg.obj = change.item.key.to_flatty
      msg.change_object_id = change.item.value.id
    else:
      var item = ""
      block registered:
        when change.item is ref RootObj:
          if not change.item.is_nil:
            var registered_type: RegisteredType
            if change.item.lookup_type(registered_type):
              msg.ref_id = registered_type.tid
              item = registered_type.stringify(change.item)
              break registered
            else:
              debug "type not registered", type_name = change.item.base_type

        item = change.item.to_flatty
      msg.obj = item

    msg.kind = if Touched in change.changes:
      Touch
    elif Added in change.changes:
      Assign
    elif Removed in change.changes:
      Unassign
    else:
      raise_assert "Can't build message for changes " & $change.changes
    result = msg

  self.change_receiver = proc(self: ref ZenBase, msg: Message,
      op_ctx: OperationContext) =

    assert self of Zen[T, O]
    let self = Zen[T, O](self)

    when O is Zen:
      let object_id = msg.change_object_id
      assert object_id in self.ctx.objects
      let item = O(self.ctx.objects[object_id])
    elif O is Pair[any, Zen]:
      type K = O.get(0)
      type V = O.get(1)
      if msg.object_id notin self.ctx.objects:
        when defined(zen_trace):
          echo msg.trace
        raise_assert "object not in context " & msg.object_id &
            " " & $Zen[T, O]

      let value = V(self.ctx.objects[msg.change_object_id])
      let item = (key: msg.obj.from_flatty(K, self.ctx), value: value)
    else:
      var item: O
      when item is ref RootObj:
        if msg.obj != "":
          if msg.ref_id > 0:
            var registered_type: RegisteredType
            if lookup_type(msg.ref_id, registered_type):
              item = type(item)(registered_type.parse(self.ctx, msg.obj))
              if not self.ctx.find_ref(item):
                debug "item restored (not found)", item = item.type.name,
                    ref_id = item.ref_id
              else:
                debug "item found (not restored)", item = item.type.name,
                    ref_id = item.ref_id
            else:
              raise_assert &"Type for ref_id {msg.ref_id} not registered"
          else:
            item = msg.obj.from_flatty(O, self.ctx)

      else:
        item = msg.obj.from_flatty(O, self.ctx)

    if msg.kind == Assign:
      self.assign(item, op_ctx = op_ctx)
    elif msg.kind == Unassign:
      self.unassign(item, op_ctx = op_ctx)
    elif msg.kind == Touch:
     self.touch(item, op_ctx = op_ctx)
    else:
      raise_assert "Can't handle message " & $msg.kind

  assert self.ctx == nil
  self.ctx = ctx

  self.publish_create(broadcast = true, op_ctx = op_ctx)
  self

proc init*(T: type Zen, flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): T =

  ctx.setup_op_ctx
  T(flags: flags).defaults(ctx, id, op_ctx)

proc init*(_: type Zen,
    T: type[ref | object | SomeOrdinal | SomeNumber | string],
    flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): Zen[T, T] =

  ctx.setup_op_ctx
  result = Zen[T, T](flags: flags).defaults(ctx, id, op_ctx)

proc init*[T: ref | object | SomeOrdinal | SomeNumber | string | ptr](
    _: type Zen, tracked: T, flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[T, T] =

  ctx.setup_op_ctx
  var self = Zen[T, T](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: set[O], flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[set[O], O] =

  ctx.setup_op_ctx
  var self = Zen[set[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[K, V](_: type Zen, tracked: Table[K, V], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()): ZenTable[K, V] =

  ctx.setup_op_ctx
  var self = ZenTable[K, V](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: open_array[O], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()): Zen[seq[O], O] =

  ctx.setup_op_ctx
  var self = Zen[seq[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: type Zen, T: type seq[O], flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[seq[O], O] =

  ctx.setup_op_ctx
  result = Zen[seq[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[O](_: type Zen, T: type set[O], flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[set[O], O] =

  ctx.setup_op_ctx
  result = Zen[set[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[K, V](_: type Zen, T: type Table[K, V], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()):
    Zen[Table[K, V], Pair[K, V]] =

  ctx.setup_op_ctx
  result = Zen[Table[K, V], Pair[K, V]](flags: flags)
      .defaults(ctx, id, op_ctx)

proc init*(_: type Zen, K, V: type, flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): ZenTable[K, V] =

  ctx.setup_op_ctx
  result = ZenTable[K, V](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[K, V](t: type Zen, tracked: open_array[(K, V)],
    flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): ZenTable[K, V] =

  ctx.setup_op_ctx
  result = Zen.init(tracked.to_table, flags = flags,
    ctx = ctx, id = id, op_ctx = op_ctx)

proc init*[T, O](self: var Zen[T, O], ctx = ctx(), id = "",
    op_ctx = OperationContext()) =

  self = Zen[T, O].init(ctx = ctx, id = id, op_ctx = op_ctx)

proc `[]`*[T, O](self: ZenContext, src: Zen[T, O]): Zen[T, O] =
  result = Zen[T, O](self.objects[src.id])

proc `[]`*(self: ZenContext, id: string): ref ZenBase =
  result = self.objects[id]

proc init_zen_fields*[T: object or ref](self: T,
  ctx = ctx()): T {.discardable.} =

  result = self
  for field in fields(self.deref):
    when field is Zen:
      field.init(ctx)

proc init_from*[T: object or ref](_: type T,
  src: T, ctx = ctx()): T {.discardable.} =

  result = T()
  for src, dest in fields(src.deref, result.deref):
    when dest is Zen:
      dest = ctx[src]

template `%`*(body: untyped): untyped =
  Zen.init(body)

proc track*[T, O](self: Zen[T, O],
  callback: proc(changes: seq[Change[O]]) {.gcsafe.}): ZID {.discardable.} =

  assert self.valid
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  self.changed_callbacks[zid] = callback
  self.ctx.close_procs[zid] = proc() =
    self.untrack(zid)
  result = zid

proc track*[T, O](self: Zen[T, O],
    callback: proc(changes: seq[Change[O]], zid: ZID) {.gcsafe.}):
    ZID {.discardable.} =

  assert self.valid
  var zid: ZID
  zid = self.track proc(changes: seq[Change[O]]) {.gcsafe.} =
    callback(changes, zid)

  result = zid

template changes*[T, O](self: Zen[T, O], body) =
  self.track proc(changes: seq[Change[O]], zid {.inject.}: ZID) {.gcsafe.} =
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
  assert self.valid
  if zid in self.changed_callbacks:
    let callback = self.changed_callbacks[zid]
    if zid notin self.paused_zids:
      callback(@[Change.init(O, {Closed})])
    self.ctx.close_procs.del(zid)
    self.changed_callbacks.del(zid)

proc untrack_all*[T, O](self: Zen[T, O]) =
  assert self.valid
  self.trigger_callbacks(@[Change.init(O, {Closed})])
  for zid, _ in self.changed_callbacks:
    self.ctx.close_procs.del(zid)
  self.changed_callbacks.clear

proc untrack*(ctx: ZenContext, zid: ZID) =
  if zid in ctx.close_procs:
    ctx.close_procs[zid]()

proc destroy*[T, O](self: Zen[T, O]) =
  assert self.valid
  self.untrack_all
  self.destroyed = true
  self.ctx.objects.del self.id
  self.publish_destroy OperationContext(source: self.ctx.name)

iterator items*[T](self: ZenSet[T] | ZenSeq[T]): T =
  assert self.valid
  for item in self.tracked.items:
    yield item

iterator items*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  assert self.valid
  for pair in self.tracked.pairs:
    yield pair

iterator pairs*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  assert self.valid
  for pair in self.tracked.pairs:
    yield pair
