import std/[times, json, tables]
import model_citizen/[core, types {.all.}, utils]
import model_citizen/zens/[contexts, validations, private, initializers {.all.}]
import ./[crdt_types, ycrdt_bindings]

# Template for privileged access to CRDT internals
template privileged_crdt =
  privileged
  private_access CrdtZenValue[T]
  private_access ZenBase
  private_access ZenContext

# Initialization
proc init*[T](_: type CrdtZenValue[T], 
              ctx: ZenContext, 
              id: string = "", 
              mode: CrdtMode = FastLocal,
              conflict_policy: ConflictPolicy = LastWriterWins,
              flags = default_flags,
              op_ctx = OperationContext()): CrdtZenValue[T] =
  
  result = CrdtZenValue[T]()
  
  # Initialize basic Zen infrastructure (adapted from existing patterns)
  result.id = if id != "": id else: "CrdtZenValue-" & generate_id()
  result.ctx = ctx
  result.flags = flags
  result.destroyed = false
  # Note: changed_callbacks is initialized by parent type
  
  # CRDT-specific initialization
  result.mode = mode
  result.sync_state = LocalOnly
  result.vector_clock = VectorClock.init(ctx.id)
  result.field_key = "value"  # Simple key for basic values
  result.pending_corrections = @[]
  result.last_sync_time = get_mono_time()
  result.sync_callbacks = init_table[ZID, proc(state: SyncState) {.gcsafe.}]()
  
  # Initialize Y-CRDT structures (stub for now - will work without Y-CRDT library)
  when defined(with_ycrdt):
    result.y_doc = ydoc_new()
    result.y_map = ymap(result.y_doc, result.id.cstring)
  
  # Set up initial value
  when T is SomeNumber or T is string or T is bool:
    result.local_value = T.default
    result.crdt_value = T.default
  else:
    when compiles(T.default):
      result.local_value = T.default
      result.crdt_value = T.default
      
  # Register with context
  ctx.objects[result.id] = result

# Validation
proc valid*[T](self: CrdtZenValue[T]): bool =
  not self.is_nil and not self.destroyed and ?self.ctx

# Core value operations with dual-mode support
proc `value=`*[T](self: CrdtZenValue[T], new_value: T, op_ctx = OperationContext()) =
  privileged_crdt
  assert self.valid
  self.ctx.setup_op_ctx
  
  let old_local = self.local_value
  self.local_value = new_value
  self.vector_clock.tick()
  
  case self.mode:
  of FastLocal:
    # Apply immediately for responsiveness
    self.sync_state = if self.local_value == self.crdt_value: Converged else: Syncing
    
    # Trigger immediate callback with local data
    let change = CrdtChange[T](
      old_value: old_local,
      new_value: new_value,
      resolved_value: new_value,
      sync_state: self.sync_state,
      is_correction: false,
      is_merge: false,
      peer_source: self.ctx.id,
      vector_clock: self.vector_clock
    )
    self.trigger_callbacks(@[change])
    
    # Start background sync to CRDT
    self.sync_to_crdt_async(new_value)
    
  of WaitForSync:
    # Wait for CRDT consensus before triggering callbacks
    self.sync_state = Syncing
    self.sync_to_crdt_blocking(new_value)

proc value*[T](self: CrdtZenValue[T]): T =
  privileged_crdt
  assert self.valid
  
  case self.mode:
  of FastLocal: 
    self.local_value    # Always return immediate local state
  of WaitForSync: 
    self.crdt_value     # Always return consensus state

# Sync mode management
proc set_sync_mode*[T](self: CrdtZenValue[T], mode: CrdtMode) =
  privileged_crdt
  assert self.valid
  
  if self.mode != mode:
    self.mode = mode
    
    # If switching to WaitForSync and there's a local/CRDT mismatch,
    # trigger a sync to resolve the state
    if mode == WaitForSync and self.local_value != self.crdt_value:
      self.check_for_corrections()

# CRDT synchronization operations
proc sync_to_crdt_async*[T](self: CrdtZenValue[T], new_value: T) =
  ## Background sync - non-blocking for FastLocal mode
  privileged_crdt
  
  when defined(with_ycrdt):
    # Create Y-CRDT transaction  
    let txn = ydoc_write_transaction(self.y_doc)
    if txn != nil:
      defer: ytransaction_commit(txn)
      
      # Store value in Y-CRDT map
      let y_input = create_yinput(new_value)
      
      ymap_insert(self.y_map, txn, self.field_key.cstring, y_input)
  else:
    # Stub implementation - just update CRDT value
    discard
  
  # Update CRDT value and check for convergence
  self.crdt_value = new_value
  if self.local_value == self.crdt_value:
    self.sync_state = Converged
    self.notify_sync_callbacks(Converged)

proc sync_to_crdt_blocking*[T](self: CrdtZenValue[T], new_value: T) =
  ## Blocking sync - waits for consensus in WaitForSync mode
  privileged_crdt
  
  # For now, implement as async + wait
  # In full implementation, this would wait for other peers to acknowledge
  self.sync_to_crdt_async(new_value)
  
  # Simulate consensus delay for WaitForSync mode
  self.sync_state = Converged
  self.local_value = new_value
  
  # Trigger callback now that consensus is reached
  let change = CrdtChange[T](
    old_value: self.crdt_value,
    new_value: new_value, 
    resolved_value: new_value,
    sync_state: Converged,
    is_correction: false,
    is_merge: false,
    peer_source: self.ctx.id,
    vector_clock: self.vector_clock
  )
  self.trigger_callbacks(@[change])

# Conflict detection and resolution
proc check_for_corrections*[T](self: CrdtZenValue[T]) =
  ## Check if local state differs from CRDT state and apply corrections
  privileged_crdt
  
  if self.local_value != self.crdt_value:
    self.sync_state = Conflicted
    
    # Apply conflict resolution policy
    let resolved_value = self.resolve_conflict(self.local_value, self.crdt_value)
    
    # Update local state to resolved value
    let old_value = self.local_value
    self.local_value = resolved_value
    self.crdt_value = resolved_value
    
    # Trigger correction callback
    let correction = CrdtChange[T](
      old_value: old_value,
      new_value: resolved_value,
      resolved_value: resolved_value, 
      sync_state: Conflicted,
      is_correction: true,
      is_merge: true,
      peer_source: "conflict_resolution",
      vector_clock: self.vector_clock
    )
    self.trigger_callbacks(@[correction])
    
    self.sync_state = Converged
    self.notify_sync_callbacks(Converged)

proc resolve_conflict*[T](self: CrdtZenValue[T], local, remote: T): T =
  ## Simple Last-Writer-Wins resolution for now
  ## TODO: Make this configurable with ConflictPolicy
  privileged_crdt
  
  # For now, always prefer the "newer" value based on some heuristic
  # In practice, this would use vector clocks and conflict policies
  when T is SomeNumber:
    result = max(local, remote)  # Take higher value
  elif T is string:
    result = if local.len > remote.len: local else: remote  # Take longer string
  else:
    result = local  # Default to local for unknown types

# Sync callback management
proc track_sync*[T](self: CrdtZenValue[T], 
                   callback: proc(state: SyncState) {.gcsafe.}): ZID {.discardable.} =
  ## Track synchronization state changes
  privileged_crdt
  assert self.valid
  
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  self.sync_callbacks[zid] = callback
  result = zid

proc notify_sync_callbacks*[T](self: CrdtZenValue[T], state: SyncState) =
  privileged_crdt
  
  for callback in self.sync_callbacks.values:
    callback(state)

# Integration with existing Zen infrastructure
proc apply_remote_update*[T](self: CrdtZenValue[T], update_data: string) =
  ## Apply update from remote peer
  privileged_crdt
  
  # Parse Y-CRDT update and apply it
  # This would be called when receiving updates from other contexts
  
  # For now, simulate by checking for changes
  self.check_for_corrections()

# Enhanced change callbacks that include CRDT information  
proc track*[T](self: CrdtZenValue[T], 
              callback: proc(changes: seq[CrdtChange[T]]) {.gcsafe.}): ZID {.discardable.} =
  privileged_crdt
  assert self.valid
  
  # Simple stub implementation for now
  # In full implementation, this would integrate with existing track infrastructure
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  
  # Store callback for later (stub)
  # TODO: Integrate with actual change system
  result = zid

# Trigger callbacks helper
proc trigger_callbacks*[T](self: CrdtZenValue[T], changes: seq[CrdtChange[T]]) =
  privileged_crdt
  # Stub implementation - in full version would call actual callbacks
  discard

# Cleanup
proc destroy*[T](self: CrdtZenValue[T], publish = true) =
  privileged_crdt
  
  # Cleanup Y-CRDT resources
  when defined(with_ycrdt):
    if self.y_doc != nil:
      ydoc_destroy(self.y_doc)
    
  # Basic cleanup
  self.destroyed = true
  self.ctx.objects[self.id] = nil