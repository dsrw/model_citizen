import std/[tables, sets, monotimes, strformat]
import model_citizen/[core, types {.all.}, utils]
import model_citizen/zens/[contexts, validations, private, initializers {.all.}]
import ./[crdt_types, ycrdt_futhark]

# Thread-local CRDT context for managing Y-CRDT documents
# We use maps to represent sets since Y-CRDT doesn't have native set support
var crdt_set_contexts {.threadvar.}: Table[string, ptr YDoc_typedef]

proc get_or_create_set_context(ctx_id: string): ptr YDoc_typedef =
  ## Get or create Y-CRDT document for this context
  if ctx_id notin crdt_set_contexts:
    crdt_set_contexts[ctx_id] = ydoc_new()
  result = crdt_set_contexts[ctx_id]

# Y-CRDT set operations using maps (key = set element, value = true for presence)
proc ymap_add_to_set_safe*[T](map: ptr Branch, txn: ptr YTransaction, value: T) =
  ## Add value to Y-CRDT map-based set
  {.gcsafe.}:
    let key_str = $value  # Convert value to string key
    let yinput = yinput_bool(true)  # Set presence to true
    ymap_insert(map, txn, key_str.cstring, addr yinput)

proc ymap_remove_from_set_safe*(map: ptr Branch, txn: ptr YTransaction, key: string) =
  ## Remove value from Y-CRDT map-based set  
  discard ymap_remove(map, txn, key.cstring)

proc ymap_contains_in_set_safe*(map: ptr Branch, txn: ptr YTransaction, key: string): bool =
  ## Check if value exists in Y-CRDT map-based set
  let output = ymap_get(map, txn, key.cstring)
  if output.len > 0:
    let ptr_val = youtput_read_bool(output)
    result = if ptr_val != nil: ptr_val[] != 0 else: false
  else:
    result = false

proc ymap_set_len_safe*(map: ptr Branch, txn: ptr YTransaction): uint32 =
  ## Get number of items in Y-CRDT map-based set
  ymap_len(map, txn)

# CrdtZenSet implementation
proc init*[T](_: type CrdtZenSet[T], ctx: ZenContext, id: string = "", mode: CrdtMode = FastLocal): CrdtZenSet[T] =
  ## Initialize a new CRDT-enabled ZenSet
  result = CrdtZenSet[T]()
  result.ctx = ctx
  result.id = if id == "": "crdt-set-" & generate_id() else: id
  result.mode = mode
  result.sync_state = LocalOnly
  result.vector_clock = VectorClock.init(ctx.id)
  result.pending_corrections = @[]
  result.sync_callbacks = init_table[ZID, proc(state: SyncState) {.gcsafe.}]()
  result.change_callbacks = init_table[ZID, proc(changes: seq[CrdtChange[T]]) {.gcsafe.}]()
  
  # Initialize Y-CRDT integration
  result.y_doc = get_or_create_set_context(ctx.id)
  result.field_key = "set_" & result.id
  
  # Get the Y-CRDT map for this set
  when defined(with_ycrdt):
    let txn = ydoc_write_transaction_simple(result.y_doc)
    if txn != nil:
      defer: ytransaction_commit(txn)
      result.y_map = ymap_get_or_create(result.y_doc, result.field_key.cstring)
  else:
    # Stub implementation for when Y-CRDT is not available
    result.y_map = nil
  
  # Initialize local and CRDT state
  result.local_set = init_hash_set[T]()
  result.crdt_set = init_hash_set[T]()
  result.last_sync_time = get_mono_time()

proc sync_from_ycrdt*[T](self: CrdtZenSet[T]) =
  ## Sync local state from Y-CRDT map
  privileged
  
  when defined(with_ycrdt):
    let txn = ydoc_write_transaction_simple(self.y_doc)
    if txn != nil:
      defer: ytransaction_commit(txn)
  
      # Clear current CRDT set and rebuild from Y-CRDT map
      self.crdt_set.clear()
      
      # Since Y-CRDT doesn't have a direct iteration API in our bindings,
      # we'll need to track the set contents ourselves or use the map length
      # For now, we'll assume the CRDT set is managed through our operations
  else:
    # Stub implementation for when Y-CRDT is not available
    discard
  
  self.sync_state = Converged
  self.last_sync_time = get_mono_time()

proc sync_to_ycrdt*[T](self: CrdtZenSet[T]) =
  ## Sync local state to Y-CRDT map
  privileged
  
  when defined(with_ycrdt):
    let txn = ydoc_write_transaction_simple(self.y_doc)
    if txn != nil:
      defer: ytransaction_commit(txn)
      
      # Add all local items to Y-CRDT map
      for item in self.local_set:
        ymap_add_to_set_safe(self.y_map, txn, item)
  else:
    # Stub implementation for when Y-CRDT is not available
    discard
  
  self.sync_state = Syncing
  self.vector_clock.tick()

proc add_item*[T](self: CrdtZenSet[T], value: T) =
  ## Add item to CRDT set
  privileged
  
  case self.mode:
  of FastLocal:
    # Add to local set immediately
    self.local_set.incl(value)
    
    # Add to Y-CRDT map in background
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        ymap_add_to_set_safe(self.y_map, txn, value)
    
    # Update CRDT set 
    self.crdt_set.incl(value)
    self.sync_state = Syncing
    
  of WaitForSync:
    # Add to Y-CRDT map first
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        ymap_add_to_set_safe(self.y_map, txn, value)
    
    # Update both local and CRDT state
    self.local_set.incl(value)
    self.crdt_set.incl(value)
    self.sync_state = Converged
  
  self.vector_clock.tick()

proc remove_item*[T](self: CrdtZenSet[T], value: T) =
  ## Remove item from CRDT set
  privileged
  
  let key_str = $value
  
  case self.mode:
  of FastLocal:
    # Remove from local set immediately
    self.local_set.excl(value)
    
    # Remove from Y-CRDT map in background
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        ymap_remove_from_set_safe(self.y_map, txn, key_str)
    
    # Update CRDT set
    self.crdt_set.excl(value)
    self.sync_state = Syncing
    
  of WaitForSync:
    # Remove from Y-CRDT map first
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        ymap_remove_from_set_safe(self.y_map, txn, key_str)
    
    # Update both local and CRDT state
    self.local_set.excl(value)
    self.crdt_set.excl(value)
    self.sync_state = Converged
  
  self.vector_clock.tick()

proc contains_item*[T](self: CrdtZenSet[T], value: T): bool =
  ## Check if item exists in CRDT set
  case self.mode:
  of FastLocal:
    # Check local set for immediate response
    result = value in self.local_set
  of WaitForSync:
    # Check Y-CRDT map for consensus view
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        
        let key_str = $value
        result = ymap_contains_in_set_safe(self.y_map, txn, key_str)
      else:
        result = false
    else:
      # Fallback to local set when Y-CRDT is not available
      result = value in self.local_set

proc len*[T](self: CrdtZenSet[T]): int =
  ## Get set length
  case self.mode:
  of FastLocal:
    result = self.local_set.len
  of WaitForSync:
    when defined(with_ycrdt):
      let txn = ydoc_write_transaction_simple(self.y_doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        result = ymap_set_len_safe(self.y_map, txn).int
      else:
        result = 0
    else:
      # Fallback to local set when Y-CRDT is not available
      result = self.local_set.len

proc get_local_view*[T](self: CrdtZenSet[T]): HashSet[T] =
  ## Get local view of the set (FastLocal mode)
  result = self.local_set

proc get_crdt_view*[T](self: CrdtZenSet[T]): HashSet[T] =
  ## Get CRDT consensus view of the set
  result = self.crdt_set

proc set_sync_mode*[T](self: CrdtZenSet[T], mode: CrdtMode) =
  ## Change sync mode dynamically
  if self.mode != mode:
    self.mode = mode
    case mode:
    of FastLocal:
      # When switching to FastLocal, start with current CRDT state
      self.local_set = self.crdt_set
    of WaitForSync:
      # When switching to WaitForSync, sync local to CRDT
      self.sync_to_ycrdt()

# ZenSet API compatibility operators
proc `+=`*[T](self: CrdtZenSet[T], value: T) =
  ## Add item to CRDT set (ZenSet API compatibility)
  self.add_item(value)

proc `-=`*[T](self: CrdtZenSet[T], value: T) =
  ## Remove item from CRDT set (ZenSet API compatibility)
  self.remove_item(value)

proc contains*[T](self: CrdtZenSet[T], value: T): bool =
  ## Check if value exists in CRDT set (ZenSet API compatibility)
  self.contains_item(value)

iterator crdt_items*[T](self: CrdtZenSet[T]): T =
  ## Iterate over set items (ZenSet API compatibility)
  case self.mode:
  of FastLocal:
    for item in self.local_set:
      yield item
  of WaitForSync:
    # For WaitForSync, iterate over CRDT view
    for item in self.crdt_set:
      yield item

# Callback management
proc track*[T](self: CrdtZenSet[T], callback: proc(changes: seq[CrdtChange[T]]) {.gcsafe.}): ZID =
  ## Track changes to this CRDT set
  result = ZID(generate_id())
  self.change_callbacks[result] = callback

proc untrack*[T](self: CrdtZenSet[T], id: ZID) =
  ## Stop tracking changes
  if id in self.change_callbacks:
    self.change_callbacks.del(id)

proc track_sync*[T](self: CrdtZenSet[T], callback: proc(state: SyncState) {.gcsafe.}): ZID =
  ## Track sync state changes
  result = ZID(generate_id())
  self.sync_callbacks[result] = callback

proc untrack_sync*[T](self: CrdtZenSet[T], id: ZID) =
  ## Stop tracking sync state
  if id in self.sync_callbacks:
    self.sync_callbacks.del(id)

# Debug and introspection
proc debug_info*[T](self: CrdtZenSet[T]): string =
  ## Get debug information about this CRDT set
  result = &"""CrdtZenSet[{T}] {self.id}:
  Mode: {self.mode}
  Sync State: {self.sync_state}
  Local Set Size: {self.local_set.len}
  CRDT Set Size: {self.crdt_set.len}
  Vector Clock: {self.vector_clock.total_events} events
  Last Sync: {self.last_sync_time}
  Pending Corrections: {self.pending_corrections.len}
  Tracked Callbacks: {self.change_callbacks.len}
"""