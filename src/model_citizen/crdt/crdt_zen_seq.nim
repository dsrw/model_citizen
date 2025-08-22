import std/[times, json, tables]
import model_citizen/[core, types {.all.}, utils]
import model_citizen/zens/[contexts, validations, private, initializers {.all.}]
import ./[crdt_types, ycrdt_futhark, document_coordinator]

# Template for privileged access to CRDT internals
template privileged_crdt =
  privileged
  private_access CrdtZenSeq[T]
  private_access ZenBase
  private_access ZenContext

# Initialization
proc init*[T](_: type CrdtZenSeq[T], 
              ctx: ZenContext, 
              id: string = "", 
              mode: CrdtMode = FastLocal,
              conflict_policy: ConflictPolicy = LastWriterWins,
              flags = default_flags,
              op_ctx = OperationContext()): CrdtZenSeq[T] =
  
  result = CrdtZenSeq[T]()
  
  # Initialize basic Zen infrastructure
  result.id = if id != "": id else: "CrdtZenSeq-" & generate_id()
  result.ctx = ctx
  result.flags = flags
  result.destroyed = false
  
  # CRDT-specific initialization
  result.mode = mode
  result.sync_state = LocalOnly
  result.vector_clock = VectorClock.init(ctx.id)
  result.field_key = "seq"  # Key for this sequence in Y-CRDT
  result.pending_corrections = @[]
  result.last_sync_time = get_mono_time()
  result.sync_callbacks = init_table[ZID, proc(state: SyncState) {.gcsafe.}]()
  result.change_callbacks = init_table[ZID, proc(changes: seq[CrdtChange[T]]) {.gcsafe.}]()
  
  # Initialize Y-CRDT structures with shared document coordination
  when defined(with_ycrdt):
    result.y_doc = get_shared_document(ctx.id, "ZenSeq", result.id)
    result.y_array = yarray(result.y_doc, result.id.cstring)
  
  # Set up initial empty sequence
  result.local_seq = @[]
  result.crdt_seq = @[]
  
  # Register with context
  ctx.objects[result.id] = result

# Validation
proc valid*[T](self: CrdtZenSeq[T]): bool =
  not self.is_nil and not self.destroyed and ?self.ctx

# Core sequence operations with dual-mode support
proc `[]=`*[T](self: CrdtZenSeq[T], index: SomeOrdinal, value: T, op_ctx = OperationContext()) =
  privileged_crdt
  assert self.valid
  self.ctx.setup_op_ctx
  
  let old_seq = self.local_seq
  if index < self.local_seq.len:
    self.local_seq[index] = value
  else:
    # Extend sequence if needed
    while self.local_seq.len <= index:
      self.local_seq.add(T.default)
    self.local_seq[index] = value
  
  self.vector_clock.tick()
  
  case self.mode:
  of FastLocal:
    # Apply immediately for responsiveness
    self.sync_state = if self.local_seq == self.crdt_seq: Converged else: Syncing
    
    # Trigger immediate callback with local data
    let change = CrdtChange[T](
      old_value: if index < old_seq.len: old_seq[index] else: T.default,
      new_value: value,
      resolved_value: value,
      sync_state: self.sync_state,
      is_correction: false,
      is_merge: false,
      peer_source: self.ctx.id,
      vector_clock: self.vector_clock
    )
    self.trigger_callbacks(@[change])
    
    # Start background sync to CRDT
    self.sync_to_crdt_async(index.uint32, value)
    
  of WaitForSync:
    # Wait for CRDT consensus before triggering callbacks
    self.sync_state = Syncing
    self.sync_to_crdt_blocking(index.uint32, value)

proc `[]`*[T](self: CrdtZenSeq[T], index: SomeOrdinal | BackwardsIndex): T =
  privileged_crdt
  assert self.valid
  
  case self.mode:
  of FastLocal: 
    if index.int < self.local_seq.len: self.local_seq[index] else: T.default
  of WaitForSync: 
    if index.int < self.crdt_seq.len: self.crdt_seq[index] else: T.default

proc add*[T](self: CrdtZenSeq[T], value: T, op_ctx = OperationContext()) =
  privileged_crdt
  assert self.valid
  self.ctx.setup_op_ctx
  
  let old_len = self.local_seq.len
  self.local_seq.add(value)
  self.vector_clock.tick()
  
  case self.mode:
  of FastLocal:
    # Apply immediately for responsiveness
    self.sync_state = if self.local_seq == self.crdt_seq: Converged else: Syncing
    
    # Trigger immediate callback with local data
    let change = CrdtChange[T](
      old_value: T.default,  # No old value for add
      new_value: value,
      resolved_value: value,
      sync_state: self.sync_state,
      is_correction: false,
      is_merge: false,
      peer_source: self.ctx.id,
      vector_clock: self.vector_clock
    )
    self.trigger_callbacks(@[change])
    
    # Start background sync to CRDT
    self.sync_to_crdt_async(old_len.uint32, value)
    
  of WaitForSync:
    # Wait for CRDT consensus before triggering callbacks
    self.sync_state = Syncing
    self.sync_to_crdt_blocking(old_len.uint32, value)

# CRDT synchronization operations
proc sync_to_crdt_async*[T](self: CrdtZenSeq[T], index: uint32, value: T) =
  ## Background sync - non-blocking for FastLocal mode
  privileged_crdt
  
  when defined(with_ycrdt):
    # Create Y-CRDT transaction  
    let txn = ydoc_write_transaction_simple(self.y_doc)
    if txn != nil:
      defer: ytransaction_commit(txn)
      
      # Insert/update value in Y-CRDT array
      if index < yarray_len(self.y_array):
        # Replace existing item (remove + insert)
        yarray_remove_safe(self.y_array, txn, index, 1)
      yarray_insert_safe(self.y_array, txn, index, value)
  else:
    # Stub implementation - just update CRDT sequence
    discard
  
  # Update CRDT sequence and check for convergence
  let idx = index.int
  while self.crdt_seq.len <= idx:
    self.crdt_seq.add(T.default)
  if idx < self.crdt_seq.len:
    self.crdt_seq[idx] = value
  else:
    self.crdt_seq.add(value)
  
  if self.local_seq == self.crdt_seq:
    self.sync_state = Converged
    self.notify_sync_callbacks(Converged)

proc sync_to_crdt_blocking*[T](self: CrdtZenSeq[T], index: uint32, value: T) =
  ## Blocking sync - waits for consensus in WaitForSync mode
  privileged_crdt
  
  # For now, implement as async + wait
  self.sync_to_crdt_async(index, value)
  
  # Simulate consensus delay for WaitForSync mode
  self.sync_state = Converged
  let idx = index.int
  if idx < self.local_seq.len:
    self.local_seq[idx] = value
  
  # Trigger callback now that consensus is reached
  let change = CrdtChange[T](
    old_value: if idx < self.crdt_seq.len: self.crdt_seq[idx] else: T.default,
    new_value: value, 
    resolved_value: value,
    sync_state: Converged,
    is_correction: false,
    is_merge: false,
    peer_source: self.ctx.id,
    vector_clock: self.vector_clock
  )
  self.trigger_callbacks(@[change])

# Sync callback management
proc track_sync*[T](self: CrdtZenSeq[T], 
                   callback: proc(state: SyncState) {.gcsafe.}): ZID {.discardable.} =
  ## Track synchronization state changes
  privileged_crdt
  assert self.valid
  
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  self.sync_callbacks[zid] = callback
  result = zid

proc notify_sync_callbacks*[T](self: CrdtZenSeq[T], state: SyncState) =
  privileged_crdt
  
  for callback in self.sync_callbacks.values:
    callback(state)

# Enhanced change callbacks that include CRDT information  
proc track*[T](self: CrdtZenSeq[T], 
              callback: proc(changes: seq[CrdtChange[T]]) {.gcsafe.}): ZID {.discardable.} =
  privileged_crdt
  assert self.valid
  
  # Store callback properly
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  self.change_callbacks[zid] = callback
  result = zid

# Trigger callbacks helper
proc trigger_callbacks*[T](self: CrdtZenSeq[T], changes: seq[CrdtChange[T]]) =
  privileged_crdt
  # Call all registered change callbacks
  for callback in self.change_callbacks.values:
    callback(changes)

# Cleanup
proc destroy*[T](self: CrdtZenSeq[T], publish = true) =
  privileged_crdt
  
  # Cleanup Y-CRDT resources - release shared document
  when defined(with_ycrdt):
    release_shared_document(self.ctx.id, "ZenSeq", self.id)
    
  # Basic cleanup
  self.destroyed = true
  self.ctx.objects[self.id] = nil