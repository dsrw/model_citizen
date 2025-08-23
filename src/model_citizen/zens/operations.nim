import std/[typetraits, macros, macrocache, tables]
import model_citizen/[core, components/private/tracking, types {.all.}]
import ./[contexts, validations, private]

# Import unified CRDT support  
import model_citizen/crdt/unified_crdt

proc untrack_all*[T, O](self: Zen[T, O]) =
  private_access ZenObject[T, O]
  private_access ZenBase
  private_access ZenContext
  assert self.valid
  self.trigger_callbacks(@[Change.init(O, {Closed})])
  for zid, _ in self.changed_callbacks.pairs:
    self.ctx.close_procs.del(zid)

  for zid in self.bound_zids:
    if zid in self.ctx.close_procs:
      tables.`[]`(self.ctx.close_procs, zid)()
      self.ctx.close_procs.del(zid)

  self.changed_callbacks.clear

proc untrack*(ctx: ZenContext, zid: ZID) =
  private_access ZenContext

  # :(
  if zid in ctx.close_procs:
    tables.`[]`(ctx.close_procs, zid)()
    debug "deleting close proc", zid
    ctx.close_procs.del(zid)
  else:
    debug "No close proc for zid", zid = zid

proc contains*[T, O](self: Zen[T, O], child: O): bool =
  privileged
  assert self.valid
  child in self.tracked

proc contains*[K, V](self: ZenTable[K, V], key: K): bool =
  privileged
  assert self.valid
  key in self.tracked

proc contains*[T, O](self: Zen[T, O], children: set[O] | seq[O] | HashSet[O]): bool =
  assert self.valid
  result = true
  for child in children:
    if child notin self:
      return false

proc clear*[T, O](self: Zen[T, O]) =
  assert self.valid
  mutate(OperationContext(source: self.ctx.id)):
    self.tracked = T.default

proc `value=`*[T, O](self: Zen[T, O], value: T, op_ctx = OperationContext()) =
  privileged
  assert self.valid
  self.ctx.setup_op_ctx
  
  # Regular Zen behavior for all types (CRDT logic is handled by specific ZenValue setter)
  if self.tracked != value:
    mutate(op_ctx):
      self.tracked = value

# Specific setter for ZenValue to handle CRDT sync modes
proc `value=`*[T](self: ZenValue[T], value: T, op_ctx = OperationContext()) =
  privileged
  assert self.valid
  self.ctx.setup_op_ctx
  
  # Check if this ZenValue has CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Delegate to unified CRDT implementation
    self.set_crdt_value(value, op_ctx)
    return
  
  # Regular Zen behavior for sync_mode = Yolo
  if self.tracked != value:
    mutate(op_ctx):
      self.tracked = value

proc `value=`*[T](self: Zen[HashSet[T], T], value: set[T], op_ctx = OperationContext()) =
  privileged
  assert self.valid
  self.ctx.setup_op_ctx
  let hash_set_value = value.to_hash_set
  if self.tracked != hash_set_value:
    mutate(op_ctx):
      self.tracked = hash_set_value

proc value*[T, O](self: Zen[T, O]): T =
  privileged
  assert self.valid
  
  # Regular Zen behavior - unified API uses same value getter for now
  self.tracked

# Specific getter for ZenValue to handle CRDT sync modes
proc value*[T](self: ZenValue[T]): T =
  privileged
  assert self.valid
  
  # Check if this ZenValue has CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Try to get value from CRDT backend first
    return self.get_crdt_value()
  
  # Regular Zen behavior for sync_mode = Yolo
  self.tracked

proc `[]`*[K, V](self: Zen[Table[K, V], Pair[K, V]], index: K): V =
  privileged
  assert self.valid
  self.tracked[index]

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal | BackwardsIndex): T =
  privileged
  assert self.valid
  
  # Check if this ZenSeq has CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Use CRDT for sequence access
    when defined(with_ycrdt):
      try:
        let sequence = get_crdt_sequence(self)
        if sequence.len > index.int:
          return sequence[index.int]
        else:
          fail("Index out of bounds in CRDT sequence")
      except:
        # Fall back to regular behavior on error
        discard
    # else fall through to regular behavior
  
  # Regular Zen behavior for sync_mode = Yolo or fallback
  self.tracked[index]

proc `[]=`*[K, V](
    self: ZenTable[K, V], key: K, value: V, op_ctx = OperationContext()
) =
  self.ctx.setup_op_ctx
  self.put(key, value, touch = false, op_ctx)

proc `[]=`*[T](
    self: ZenSeq[T], index: SomeOrdinal, value: T, op_ctx = OperationContext()
) =
  self.ctx.setup_op_ctx
  assert self.valid
  
  # Check if this ZenSeq has CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Use CRDT for sequence modification
    when defined(with_ycrdt):
      try:
        # TODO: Y-CRDT doesn't have direct index assignment for arrays
        # For now, we'll fall back to regular behavior
        # Future enhancement could implement via delete + insert
        discard
      except:
        discard
    # else fall through to regular behavior
  
  # Regular Zen behavior for sync_mode = Yolo or fallback
  mutate(op_ctx):
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  privileged
  self.ctx.setup_op_ctx
  when O is Zen:
    assert self.valid(value)
  else:
    assert self.valid
  
  # Check if this is a ZenSeq with CRDT sync_mode enabled
  when T is seq[O] and O is O:  # This is a ZenSeq[O]
    if self.effective_sync_mode != SyncMode.Yolo:
      # Use CRDT for sequence addition
      when defined(with_ycrdt):
        try:
          set_crdt_sequence_add(self, value, op_ctx)
          # CRDT operation succeeded, return early
          return
        except:
          # Fall back to regular behavior on error
          discard
      # else fall through to regular behavior
  
  # Regular Zen behavior for non-CRDT or sync_mode = Yolo
  self.tracked.add value
  let added = @[Change.init(value, {Added})]
  self.link_or_unlink(added, true)
  when O isnot Zen and O is ref:
    self.ctx.ref_count(added, self.id)

  self.publish_changes(added, op_ctx)
  self.trigger_callbacks(added)

proc del*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  privileged
  self.ctx.setup_op_ctx
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, del, op_ctx)

proc del*[K, V](self: ZenTable[K, V], key: K, op_ctx = OperationContext()) =
  privileged
  self.ctx.setup_op_ctx
  assert self.valid
  if key in self.tracked:
    remove(
      self, key, Pair[K, V](key: key, value: self.tracked[key]), del, op_ctx
    )

proc del*[T: seq, O](
    self: Zen[T, O], index: SomeOrdinal, op_ctx = OperationContext()
) =
  privileged

  self.ctx.setup_op_ctx
  assert self.valid
  
  # Check if this is a ZenSeq with CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Use CRDT for sequence deletion
    when defined(with_ycrdt):
      try:
        set_crdt_sequence_delete(self, index.int, op_ctx)
        # CRDT operation succeeded, return early
        return
      except:
        # Fall back to regular behavior on error
        discard
    # else fall through to regular behavior
  
  # Regular Zen behavior for non-CRDT or sync_mode = Yolo
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], del, op_ctx)

proc delete*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  if value in self.tracked:
    remove(
      self,
      value,
      value,
      delete,
      op_ctx = OperationContext(source: [self.ctx.id].to_hash_set),
    )

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  assert self.valid
  if key in self.tracked:
    remove(
      self,
      key,
      Pair[K, V](key: key, value: self.tracked[key]),
      delete,
      op_ctx = OperationContext(),
    )

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  assert self.valid
  
  # Check if this is a ZenSeq with CRDT sync_mode enabled
  if self.effective_sync_mode != SyncMode.Yolo:
    # Use CRDT for sequence deletion
    when defined(with_ycrdt):
      try:
        set_crdt_sequence_delete(self, index.int, OperationContext())
        # CRDT operation succeeded, return early
        return
      except:
        # Fall back to regular behavior on error
        discard
    # else fall through to regular behavior
  
  # Regular Zen behavior for non-CRDT or sync_mode = Yolo
  if index < self.tracked.len:
    remove(
      self, index, self.tracked[index], delete, op_ctx = OperationContext()
    )

proc touch*[K, V](
    self: ZenTable[K, V], pair: Pair[K, V], op_ctx: OperationContext
) =
  assert self.valid
  self.put(pair.key, pair.value, touch = true, op_ctx = op_ctx)

proc touch*[T, O](
    self: ZenTable[T, O], key: T, value: O, op_ctx = OperationContext()
) =
  assert self.valid
  self.put(key, value, touch = true, op_ctx = op_ctx)

proc touch*[T: HashSet, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch([value].to_hash_set, true, op_ctx = op_ctx)

proc touch*[T](self: Zen[HashSet[T], T], value: set[T], op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch(value.to_hash_set, true, op_ctx = op_ctx)

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
  privileged
  assert self.valid
  self.tracked.len

proc `+`*[O](self, other: ZenSet[O]): HashSet[O] =
  privileged
  self.tracked + other.tracked

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, true, op_ctx = OperationContext())

proc `+=`*[O](self: ZenSet[O], value: O) =
  assert self.valid
  
  # TODO: CRDT integration temporarily disabled
  # Check if this ZenSet has CRDT sync_mode enabled
  # if self.sync_mode != SyncMode.Yolo:
  #   # For now, delegate to regular behavior - full ZenSet CRDT support coming soon
  #   discard
  #   # TODO: Implement ZenSet CRDT support with unified_crdt
  
  # Regular Zen behavior for sync_mode = Yolo
  self.change([value].to_hash_set, true, op_ctx = OperationContext())

proc `+=`*[T](self: Zen[HashSet[T], T], value: set[T]) =
  assert self.valid
  
  # TODO: CRDT integration temporarily disabled
  # Check if this ZenSet has CRDT sync_mode enabled
  # if self.sync_mode != SyncMode.Yolo:
  #   # For now, delegate to regular behavior - full ZenSet CRDT support coming soon
  #   discard
  #   # TODO: Implement ZenSet CRDT support with unified_crdt
  
  # Regular Zen behavior for sync_mode = Yolo
  self.change(value.to_hash_set, true, op_ctx = OperationContext())

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.add(value)

proc `+=`*[T, O](self: ZenTable[T, O], other: Table[T, O]) =
  assert self.valid
  self.put_all(other, touch = false, op_ctx = OperationContext())

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, false, op_ctx = OperationContext())

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change({value}, false, op_ctx = OperationContext())

proc `-=`*[T: HashSet, O](self: Zen[T, O], value: O) =
  assert self.valid
  
  # Check if this is a ZenSet with CRDT sync_mode enabled
  when T is HashSet[O] and O is O:  # This is a ZenSet[O]
    if self.effective_sync_mode != SyncMode.Yolo:
      # For now, delegate to regular behavior - full ZenSet CRDT support coming soon
      discard
      # TODO: Implement ZenSet CRDT support with unified_crdt
  
  # Regular Zen behavior for non-CRDT or sync_mode = Yolo
  self.change([value].to_hash_set, false, op_ctx = OperationContext())

proc `-=`*[T](self: Zen[HashSet[T], T], value: set[T]) =
  assert self.valid
  
  # TODO: CRDT integration temporarily disabled
  # Check if this ZenSet has CRDT sync_mode enabled
  # if self.sync_mode != SyncMode.Yolo:
  #   # For now, delegate to regular behavior - full ZenSet CRDT support coming soon
  #   discard
  #   # TODO: Implement ZenSet CRDT support with unified_crdt
  
  # Regular Zen behavior for sync_mode = Yolo
  self.change(value.to_hash_set, false, op_ctx = OperationContext())

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change(@[value], false, op_ctx = OperationContext())

proc `&=`*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.value = self.value & value

proc `==`*(a, b: Zen): bool =
  privileged
  a.is_nil == b.is_nil and a.destroyed == b.destroyed and a.tracked == b.tracked and
    a.id == b.id

proc pause_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
  if zids.len == 0:
    for zid in self.changed_callbacks.keys:
      self.paused_zids.incl(zid)
  else:
    for zid in zids:
      self.paused_zids.incl(zid)

proc resume_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
  if zids.len == 0:
    self.paused_zids = {}
  else:
    for zid in zids:
      self.paused_zids.excl(zid)

template pause_impl(self: Zen, zids: untyped, body: untyped) =
  private_access ZenBase

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
  private_access ZenObject
  mixin valid
  assert self.valid
  pause_impl(self, self.changed_callbacks.keys, body)

proc destroy*[T, O](self: Zen[T, O], publish = true) =
  log_defaults
  debug "destroying", unit = self.id, stack = get_stack_trace()
  assert self.valid
  self.untrack_all
  self.destroyed = true
  self.ctx.objects[self.id] = nil
  self.ctx.objects_need_packing = true

  if publish:
    self.publish_destroy OperationContext(source: self.ctx.id)

proc `~=`*[T, O](a: Zen[T, O], b: T) =
  `value=`(a, b)

proc `~=`*[T](a: Zen[HashSet[T], T], b: set[T]) =
  `value=`(a, b)

proc `~==`*[T, O](a: Zen[T, O], b: T): bool =
  value(a) == b

proc `~==`*[T](a: Zen[HashSet[T], T], b: set[T]): bool =
  value(a) == b.to_hash_set

proc `==`*[T](hs: HashSet[T], s: set[T]): bool =
  hs == s.to_hash_set

proc `==`*[T](s: set[T], hs: HashSet[T]): bool =
  s.to_hash_set == hs

proc `~==~`*[T, O](a: Zen[T, O], b: Zen[T, O]): bool =
  value(a) == value(b)

proc `?~`*[T](self: ZenValue[T]): bool =
  ? ~self

iterator items*[T](self: Zen[HashSet[T], T]): T =
  privileged
  assert self.valid
  for item in sets.items(self.tracked):
    yield item

iterator items*[T](self: ZenSeq[T]): T =
  privileged
  assert self.valid
  for item in self.tracked.items:
    yield item

iterator items*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  privileged
  assert self.valid
  for key, value in self.tracked.pairs:
    yield Pair[K, V](key: key, value: value)

iterator pairs*[K, V](self: ZenTable[K, V]): (K, V) =
  privileged
  assert self.valid
  for pair in self.tracked.pairs:
    yield pair
