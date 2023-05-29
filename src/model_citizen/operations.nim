template deref(o: ref): untyped = o[]
template deref(o: not ref): untyped = o

proc ref_id[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

proc ref_count[O](self: ZenContext, changes: seq[Change[O]]) =
  log_defaults

  for change in changes:
    if not ?change.item:
      continue
    let id = change.item.ref_id
    if Added in change.changes:
      if id notin self.ref_pool:
        debug "saving ref", id
        self.ref_pool[id] = CountedRef()
      inc self.ref_pool[id].count
      self.ref_pool[id].obj = change.item
    if Removed in change.changes:
      assert id in self.ref_pool
      dec self.ref_pool[id].count
      if self.ref_pool[id].count == 0:
        self.freeable_refs[id] = get_mono_time() + init_duration(seconds = 10)


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


proc trigger_callbacks[T, O](self: Zen[T, O], changes: seq[Change[O]]) =
  if changes.len > 0:
    let callbacks = self.changed_callbacks.dup
    for zid, callback in callbacks.pairs:
      if zid in self.changed_callbacks and zid notin self.paused_zids:
        callback(changes)

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

  if ?child.value:
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

  if ?child:
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
            if ?val:
              self.link_child(val, change.item, name)
    else:
      when change.value is Zen:
        if ?change.value:
          change.value.unlink
      elif change.value is object or change.value is ref:
        for n, field in change.value.deref.field_pairs:
          when field is Zen:
            if ?field:
              echo "unlinking field ", n, " from ", self.id, " ", self.ctx.name
              field.unlink

proc link_or_unlink[T, O](self: Zen[T, O],
  changes: seq[Change[O]], link: bool) =

  if TrackChildren in self.flags:
    for change in changes:
      self.link_or_unlink(change, link)

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
      if ?removed.item.value:
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

proc find_ref[T](self: ZenContext, value: var T): bool =
  if ?value:
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
    debug "freeing ref", id
    self.freeable_refs.del(id)

proc free*[T: ref RootObj](self: ZenContext, value: T) =
  let id = value.ref_id
  assert id in self.freeable_refs
  assert self.ref_pool[id].count == 0
  self.ref_pool.del(id)
  self.freeable_refs.del(id)

proc untrack_all*[T, O](self: Zen[T, O]) =
  assert self.valid
  self.trigger_callbacks(@[Change.init(O, {Closed})])
  for zid, _ in self.changed_callbacks:
    if int(zid) == 46:
      echo \"!! 2 deleting close proc 46 {self.id} {self.ctx.name}"
    self.ctx.close_procs.del(zid)

  for zid in self.bound_zids:
    self.ctx.untrack(zid)

  self.changed_callbacks.clear

proc untrack*(ctx: ZenContext, zid: ZID) =
  if zid notin ctx.close_procs:
    echo \"!! missing close proc {zid} {ctx.name} {Zen.thread_ctx.name}"
    #return

  if zid notin ctx.close_procs:
    raise_assert &"no close proc for zid {zid}"

  assert zid in ctx.close_procs
  ctx.close_procs[zid]()
  if int(zid) == 46:
    echo \"!! 3 deleting close proc {zid} {ctx.name} {Zen.thread_ctx.name}"
  ctx.close_procs.del(zid)
