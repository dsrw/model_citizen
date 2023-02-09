include prelude

proc register_type*(_: type Zen, typ: type) =
  log_defaults
  let key = typ.type_id

  with_lock:
    assert key notin type_registry[], "Type already registered"

  let clone = func(self: ref RootObj): ref RootObj =
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
      elif src.has_custom_pragma(local):
        dest = dest.type.default

    result = clone

  let restore = func(self: ref RootObj, ctx: ZenContext, clone_from: ref RootObj): ref RootObj =
    var self = typ(self)
    for field in self[].fields:
      when field is Zen:
        if not field.is_nil and field.id in ctx:
          field = type(field)(ctx[field.id])
    result = self

  with_lock:
    type_registry[][key] = RegisteredType(clone: clone, restore: restore)

proc lookup_type(obj: ref RootObj, registered_type: var RegisteredType): bool =
  let key = obj.type_id
  if key in local_type_registry:
    registered_type = local_type_registry[key]
    result = true
  else:
    with_lock:
      if key in type_registry[]:
        registered_type = type_registry[][key]
        local_type_registry[key] = registered_type
        result = true
  if not result:
    debug "type not registered", type_name = obj.base_type

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

proc recv*(self: ZenContext, messages = int.high) {.gcsafe.}

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
  assert self.ctx == Zen.thread_ctx
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
    debug "linking zen", child = ($child.type, $child.id), self = ($self.type, $self.id)


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
    debug "linking zen", child = ($child.type, $child.id), self = ($self.type, $self.id), zid = child.link_zid, child_addr = cast[int](unsafe_addr child[]).to_hex

  if not child.is_nil:
    link(child)

proc unlink(self: Zen) =
  debug "unlinking", id = self.id, zid = self.link_zid
  self.untrack(self.link_zid)
  self.link_zid = 0

proc unlink[T: Pair](pair: T) =
  debug "unlinking", id = pair.value.id, zid = pair.value.link_zid
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
        for field in change.value.deref.fields:
          when field is Zen:
            if not field.is_nil:
              field.unlink

proc link_or_unlink[T, O](self: Zen[T, O],
  changes: seq[Change[O]], link: bool) =

  if self.track_children:
    for change in changes:
      self.link_or_unlink(change, link)

proc ref_id[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

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

proc recv*(self: ZenContext, messages = int.high) {.gcsafe.} =
  var msg: Message
  var count = 0
  self.free_refs
  while count < messages and self.chan.peek > 0:
    self.chan.recv(msg)
    when defined(zen_trace):
      let src = self.name & "-" & msg.src
      if src in self.last_received_id:
        if msg.id != self.last_received_id[src] + 1:
          raise_assert &"src={src} msg.id={msg.id} last={self.last_received_id[src]}. Should be msg.id - 1"
      self.last_received_id[src] = msg.id
    inc count
    debug "receiving", msg

    if msg.kind == Create:
      if msg.obj.is_nil:

        when defined(zen_trace):
          error "create has nil proc", trace = msg.trace
        else:
          error "create has nil proc"

      assert not msg.obj.is_nil
      let wrapper = Wrapper[proc(ctx: ZenContext, publish: bool) {.gcsafe.}](msg.obj)
      wrapper.item(self, publish = false)
    elif msg.kind == Destroy:
      let obj = self.objects[msg.object_id]
      assert obj.valid
      obj.destroyed = true
      self.objects.del(msg.object_id)
    elif msg.kind != Blank:
      let obj = self.objects[msg.object_id]
      obj.change_receiver(obj, msg, publish = false)
    else:
      raise_assert "Can't recv a blank message"

proc remaining*(self: Chan): range[0.0..1.0] =
  private_access Chan
  private_access ChannelObj
  let size = self.d[].size
  result = 1.0 - self.peek / size

proc pressure*(self: ZenContext): range[0.0..1.0] =
  1.0 - (@[self.chan.remaining] & self.subscribers.map_it(it.chan.remaining)).min

proc chan_full*(self: Chan): bool =
  self.remaining < 0.1

proc send*(self: ZenContext, sub: Subscription, msg: sink Isolated[Message]) =
  when defined(zen_trace):
    var a = msg.extract
    a.src = self.name
    if sub.ctx_name notin self.last_msg_id:
      self.last_msg_id[sub.ctx_name] = 1
    else:
      self.last_msg_id[sub.ctx_name] += 1
    a.id = self.last_msg_id[sub.ctx_name]

    sub.chan.send(unsafe_isolate a)
  else:
    sub.chan.send(msg)

proc publish_destroy[T, O](self: Zen[T, O]) =
  for sub in self.ctx.subscribers:
    when defined(zen_trace):
      self.ctx.send:(sub, isolate Message(
        kind: Destroy, object_id: self.id, trace: get_stack_trace()))
    else:
      self.ctx.send(sub, isolate Message(kind: Destroy, object_id: self.id))

proc publish_changes[T, O](self: Zen[T, O], changes: seq[Change[O]]) =
  let id = self.id
  for sub in self.ctx.subscribers:
    for change in changes:
      if [Added, Removed, Created, Touched].any_it(it in change.changes):
        if Removed in change.changes and Modified in change.changes:
          # An assign will trigger both an assign and an unassign on the other side.
          # we only want to send a Removed message when an item is removed from a
          # collection.
          continue
        assert id in self.ctx.objects
        let obj = self.ctx.objects[id]
        var msg = obj.build_message(obj, change)
        msg.object_id = id
        when defined(zen_trace):
          msg.trace = get_stack_trace()
        self.ctx.send sub, unsafe_isolate(msg)

proc process_changes[T](self: Zen[T, T], initial: sink T, touch = false,
    publish_changes: bool) =

  if initial != self.tracked:
    var add_flags = {Added, Modified}
    var del_flags = {Removed, Modified}
    if touch:
      add_flags.incl Touched
      del_flags.incl Touched

    let changes = @[
      Change.init(initial, del_flags),
      Change.init(self.tracked, add_flags)
    ]
    when T isnot Zen and T is ref:
      self.ctx.ref_count(changes)

    if publish_changes:
      self.publish_changes(changes)
    self.trigger_callbacks(changes)

  elif touch:
    let changes = @[Change.init(self.tracked, {Touched})]
    when T isnot Zen and T is ref:
      self.ctx.ref_count(changes)

    if publish_changes:
      self.publish_changes(changes)
    self.trigger_callbacks(changes)

proc process_changes[T: seq | set, O](self: Zen[T, O],
    initial: sink T, touch = T.default, publish_changes: bool) =

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

  if publish_changes:
    self.publish_changes(changes)
  self.trigger_callbacks(changes)

proc process_changes[K, V](self: Zen[Table[K, V],
  Pair[K, V]], initial_table: sink Table[K, V], publish_changes: bool) =

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

  if publish_changes:
    self.publish_changes(changes)
  self.trigger_callbacks(changes)


template mutate_and_touch(touch, publish, body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values, touch, publish_changes = publish)

template mutate(publish: bool, body: untyped) =
  when self.tracked is Zen:
    let initial_values = self.tracked[]
  elif self.tracked is ref:
    let initial_values = self.tracked
  else:
    let initial_values = self.tracked.dup
  body
  self.process_changes(initial_values, publish_changes = publish)

proc change[T, O](self: Zen[T, O], items: T, add: bool, publish: bool) =
  mutate(publish):
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc change_and_touch[T, O](self: Zen[T, O], items: T, add: bool,
    publish: bool) =

  mutate_and_touch(touch = items, publish):
    if add:
      self.tracked = self.tracked & items
    else:
      self.tracked = self.tracked - items

proc clear*[T, O](self: Zen[T, O]) =
  assert self.valid
  mutate(true):
    self.tracked = T.default

proc `value=`*[T, O](self: Zen[T, O], value: T, publish = true) =
  assert self.valid

  if self.tracked != value:
    mutate(publish):
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
    publish: bool) =

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

    if publish:
      self.publish_changes changes
    self.trigger_callbacks changes

  elif key in self.tracked and touch:
    let changes = @[Change.init(Pair[K, V] (key, value), {Touched})]

    if publish:
      self.publish_changes changes
    self.trigger_callbacks changes

  elif key notin self.tracked:
    let added = Change.init((key, value), {Added})
    when value is Zen:
      self.link_or_unlink(added, true)
    self.tracked[key] = value
    let changes = @[added]
    when V isnot Zen and V is ref:
      self.ctx.ref_count changes

    if publish:
      self.publish_changes changes
    self.trigger_callbacks changes

proc `[]=`*[K, V](self: ZenTable[K, V], key: K, value: V, publish = true) =
  self.put(key, value, touch = false, publish = publish)

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T, publish = true) =
  assert self.valid
  mutate(publish):
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O, publish = true) =
  when O is Zen:
    assert self.valid(value)
  else:
    assert self.valid
  self.tracked.add value
  let added = @[Change.init(value, {Added})]
  self.link_or_unlink(added, true)
  when O isnot Zen and O is ref:
    self.ctx.ref_count(added)

  if publish:
    self.publish_changes(added)
  self.trigger_callbacks(added)

template remove(self, key, item_exp, fun, publish) =
  let obj = item_exp
  self.tracked.fun key
  let removed = @[Change.init(obj, {Removed})]
  self.link_or_unlink(removed, false)
  when obj isnot Zen and obj is ref:
    self.ctx.ref_count(added)

  if publish:
    self.publish_changes(removed)
  self.trigger_callbacks(removed)

proc del*[T, O](self: Zen[T, O], value: O, publish = true) =
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, del, publish)

proc del*[K, V](self: ZenTable[K, V], key: K, publish = true) =
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), del, publish)

proc del*[T: seq, O](self: Zen[T, O], index: SomeOrdinal, publish = true) =
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], del, publish)

proc delete*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, delete, publish = true)

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), delete,
        publish = true)

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], delete, publish = true)

proc touch[K, V](self: ZenTable[K, V], pair: Pair[K, V], publish: bool) =
  assert self.valid
  self.put(pair.key, pair.value, touch = true, publish = publish)

proc touch*[T, O](self: ZenTable[T, O], key: T, value: O, publish = true) =
  assert self.valid
  self.put(key, value, touch = true, publish = publish)

proc touch*[T: set, O](self: Zen[T, O], value: O, publish = true) =
  assert self.valid
  self.change_and_touch({value}, true, publish = publish)

proc touch*[T: seq, O](self: Zen[T, O], value: O, publish = true) =
  assert self.valid
  self.change_and_touch(@[value], true, publish = publish)

proc touch*[T, O](self: Zen[T, O], value: T, publish = true) =
  assert self.valid
  self.change_and_touch(value, true, publish = publish)

proc touch*[T](self: ZenValue[T], value: T, publish = true) =
  assert self.valid
  mutate_and_touch(touch = true, publish):
    self.tracked = value

proc len*(self: Zen): int =
  assert self.valid
  self.tracked.len

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, true, publish = true)

proc `+=`*[O](self: ZenSet[O], value: O) =
  assert self.valid
  self.change({value}, true, publish = true)

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.add(value)

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, false, publish = true)

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change({value}, false, publish = true)

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change(@[value], false, publish = true)

proc `&=`*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.value = self.value & value

proc `==`*(a, b: Zen): bool =
  a.is_nil == b.is_nil and a.destroyed == b.destroyed and
    a.tracked == b.tracked and a.id == b.id

proc assign[O](self: ZenSeq[O], value: O, publish: bool) =
  self.add(value, publish = publish)

proc assign[O](self: ZenSet[O], value: O, publish: bool) =
  self.change({value}, add = true, publish = publish)

proc assign[K, V](self: ZenTable[K, V], pair: Pair[K, V], publish: bool) =
  self.`[]=`(pair.key, pair.value, publish = publish)

proc assign[T, O](self: Zen[T, O], value: O, publish: bool) =
  self.`value=`(value, publish)

proc unassign[O](self: ZenSeq[O], value: O, publish: bool) =
  self.change(@[value], false, publish = publish)

proc unassign[O](self: ZenSet[O], value: O, publish: bool) =
  self.change({value}, false, publish = publish)

proc unassign[K, V](self: ZenTable[K, V], pair: Pair[K, V], publish: bool) =
  self.del(pair.key, publish = publish)

proc unassign[T, O](self: Zen[T, O], value: O, publish: bool) =
  discard

proc defaults[T, O](self: Zen[T, O], ctx: ZenContext, id: string,
    publish: bool): Zen[T, O] {.gcsafe.} =

  log_defaults

  self.id = if id == "":
    last_id += 1
    $last_id.load
  else:
    id

  ctx.objects[self.id] = self

  self.publish_create = proc(sub: Subscription, broadcast: bool) =
    let value = self.tracked.deep_copy
    let id = self.id
    let track_children = self.track_children

    template send_msg(src_ctx, sub) =
      var msg = Message(kind: Create,
        obj: Wrapper[proc(ctx: ZenContext, publish: bool)](item:
            proc(ctx: ZenContext, publish: bool) =

          discard Zen.init(value, ctx = ctx, id = id,
              track_children = track_children, publish = publish)
        ),
        object_id: id)
      when defined(zen_trace):
        msg.trace = get_stack_trace()

      src_ctx.send(sub, unsafe_isolate msg)

    if sub != Subscription.default:
      ctx.send_msg(sub)
    if broadcast:
      for sub in self.ctx.subscribers:
        ctx.send_msg(sub)

  self.build_message = proc(self: ref ZenBase, change: BaseChange): Message =
    assert Added in change.changes or Removed in change.changes or
      Touched in change.changes
    let change = Change[O](change)
    when change.item is Zen:
      var wrapper = Wrapper[void](object_id: (ref ZenBase)(change.item).id)
    elif change.item is Pair[any, Zen]:
      # TODO: Properly sync ref keys
      var wrapper = Wrapper[change.item.key.type](
        item: change.item.key, object_id: change.item.value.id)
    else:
      var wrapper = Wrapper[O]()
      block registered:
        when change.item is ref RootObj:
          if change.item.is_nil:
            wrapper.item = nil
          else:
            var registered_type: RegisteredType
            if change.item.lookup_type(registered_type):
              wrapper.item = O(registered_type.clone(change.item))
              break registered
            else:
              debug "type not registered", type_name = change.item.base_type

        wrapper.item = change.item.deep_copy

    result.obj = wrapper
    result.kind = if Touched in change.changes:
      Touch
    elif Added in change.changes:
      Assign
    elif Removed in change.changes:
      Unassign
    else:
      raise_assert "Can't build message for changes " & $change.changes

  self.change_receiver = proc(self: ref ZenBase, msg: Message, publish: bool) =
    assert self of Zen[T, O]
    let self = Zen[T, O](self)
    when O is Zen:
      let object_id = Wrapper[void](msg.obj).object_id
      assert object_id in self.ctx.objects
      let item = O(self.ctx.objects[object_id])
    elif O is Pair[any, Zen]:
      type K = O.get(0)
      type V = O.get(1)
      let wrapper = Wrapper[K](msg.obj)
      if wrapper.object_id notin self.ctx.objects:
        when defined(zen_trace):
          echo msg.trace
        raise_assert "object not in context " & wrapper.object_id &
            " " & $Zen[T, O]

      let value = V(self.ctx.objects[wrapper.object_id])
      let item = (key: wrapper.item, value: value)
    else:
      var item = Wrapper[O](msg.obj).item
      when item is ref RootObj:
        if not item.is_nil:
          var registered_type: RegisteredType
          if item.lookup_type(registered_type):
            if not self.ctx.find_ref(item):
              item = type(item)(registered_type.restore(item, self.ctx))
              debug "item restored (not found)", item = item.type.name,
                  ref_id = item.ref_id
            else:
              debug "item found (not restored)", item = item.type.name,
                  ref_id = item.ref_id

    if msg.kind == Assign:
      self.assign(item, publish = publish)
    elif msg.kind == Unassign:
      self.unassign(item, publish = publish)
    elif msg.kind == Touch:
     self.touch(item, publish = publish)
    else:
      raise_assert "Can't handle message " & $msg.kind

  assert self.ctx == nil
  self.ctx = ctx

  if publish:
    self.publish_create(broadcast = true)
  self

proc init*(T: type Zen, track_children = true, ctx = ctx(), id = ""): T =
  T(track_children: track_children).defaults(ctx, id, publish = true)

proc init*(_: type Zen,
  T: type[ref | object | SomeOrdinal | SomeNumber | string],
  track_children = true, ctx = ctx(), id = ""): Zen[T, T] =

  result = Zen[T, T](track_children: track_children).defaults(ctx, id,
      publish = true)

proc init*[T: ref | object | SomeOrdinal | SomeNumber | string | ptr](_: type Zen,
    tracked: T, track_children = true, ctx = ctx(), id = "",
    publish = true): Zen[T, T] =

  var self = Zen[T, T](track_children: track_children).defaults(ctx, id, publish)
  mutate(publish):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: set[O], track_children = true,
    ctx = ctx(), id = "", publish = true): Zen[set[O], O] =

  var self = Zen[set[O], O](track_children: track_children).defaults(
      ctx, id, publish)

  mutate(publish):
    self.tracked = tracked
  result = self

proc init*[K, V](_: type Zen, tracked: Table[K, V], track_children = true,
    ctx = ctx(), id = "", publish = true): ZenTable[K, V] =

  var self = ZenTable[K, V](track_children: track_children).defaults(
      ctx, id, publish)

  mutate(publish):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: open_array[O], track_children = true,
    ctx = ctx(), id = "", publish = true): Zen[seq[O], O] =

  var self = Zen[seq[O], O](track_children: track_children).defaults(
      ctx, id, publish)

  mutate(publish):
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: type Zen, T: type seq[O], track_children = true, ctx = ctx(),
  id = ""): Zen[seq[O], O] =

  result = Zen[seq[O], O](track_children: track_children).defaults(
      ctx, id, publish = true)

proc init*[O](_: type Zen, T: type set[O], track_children = true, ctx = ctx(),
  id = ""): Zen[set[O], O] =

  result = Zen[set[O], O](track_children: track_children).defaults(
      ctx, id, publish = true)

proc init*[K, V](_: type Zen, T: type Table[K, V], track_children = true,
  ctx = ctx(), id = ""): Zen[Table[K, V], Pair[K, V]] =

  result = Zen[Table[K, V], Pair[K, V]](track_children: track_children)
    .defaults(ctx, id, publish = true)

proc init*(_: type Zen, K, V: type, track_children = true, ctx = ctx(),
  id = ""): ZenTable[K, V] =

  result = ZenTable[K, V](track_children: track_children).defaults(
      ctx, id, publish = true)

proc init*[K, V](t: type Zen, tracked: open_array[(K, V)],
  track_children = true, ctx = ctx(), id = ""): ZenTable[K, V] =
  result = Zen.init(tracked.to_table, track_children = track_children,
    ctx = ctx, id = id)

proc init*[T, O](self: var Zen[T, O], ctx = ctx(), id = "") =
  self = Zen[T, O].init(ctx = ctx, id = id)

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
    callback: proc(changes: seq[Change[O]], zid: ZID) {.gcsafe.}): ZID {.discardable.} =

  assert self.valid
  var zid: ZID
  zid = self.track proc(changes: seq[Change[O]]) {.gcsafe.} = callback(changes, zid)
  result = zid

proc subscribe*(self: ZenContext, ctx: ZenContext) =
  ctx.subscribers.add Subscription(chan: self.chan, ctx_name: self.name)
  for id, zen in ctx.objects:
    zen.publish_create Subscription(chan: self.chan, ctx_name: self.name)
  self.recv

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
  self.publish_destroy

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
