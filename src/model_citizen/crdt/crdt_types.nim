import std/[tables, monotimes, sets]
import model_citizen/[types {.all.}]
import ./ycrdt_futhark

type
  CrdtMode* = enum
    FastLocal     ## Apply changes immediately locally, sync in background
    WaitForSync   ## Wait for CRDT convergence before applying changes

  SyncState* = enum
    LocalOnly     ## Only local changes, not yet synced
    Syncing       ## Synchronization in progress  
    Converged     ## All peers have converged on this value
    Conflicted    ## Conflict detected, resolution applied

  CrdtChange*[T] = ref object of BaseChange
    ## Enhanced change object with CRDT sync information
    item*: T                  ## The changed item (for compatibility with Change[T])
    old_value*: T
    new_value*: T
    resolved_value*: T        ## Value after conflict resolution
    sync_state*: SyncState
    is_correction*: bool      ## True if this is a correction from CRDT
    is_merge*: bool          ## True if this resulted from merging concurrent changes
    peer_source*: string     ## Which peer caused this change
    vector_clock*: VectorClock
    
  VectorClock* = ref object
    ## Simple vector clock for causality tracking
    clocks*: Table[string, uint64]
    local_id*: string
    
  CrdtZenValue*[T] = ref object of ZenObject[T, T]
    ## CRDT-enabled ZenValue with dual-mode operation
    local_value*: T               ## Immediate local state (FastLocal mode)
    crdt_value*: T               ## CRDT-synchronized state  
    mode*: CrdtMode
    sync_state*: SyncState
    
    # Y-CRDT integration
    y_doc*: ptr YDoc_typedef     ## Y-CRDT document
    y_map*: ptr Branch           ## Y-CRDT map for this value
    field_key*: string          ## Key used in Y-CRDT map
    
    # Synchronization tracking
    vector_clock*: VectorClock
    pending_corrections*: seq[T]
    last_sync_time*: MonoTime
    sync_callbacks*: Table[ZID, proc(state: SyncState) {.gcsafe.}]
    change_callbacks*: Table[ZID, proc(changes: seq[CrdtChange[T]]) {.gcsafe.}]
    
  CrdtZenSeq*[T] = ref object of ZenObject[seq[T], T]
    ## CRDT-enabled ZenSeq with dual-mode operation
    local_seq*: seq[T]            ## Immediate local state (FastLocal mode)
    crdt_seq*: seq[T]            ## CRDT-synchronized state  
    mode*: CrdtMode
    sync_state*: SyncState
    
    # Y-CRDT integration
    y_doc*: ptr YDoc_typedef     ## Y-CRDT document
    y_array*: ptr Branch         ## Y-CRDT array for this sequence
    field_key*: string          ## Key used in Y-CRDT document
    
    # Synchronization tracking
    vector_clock*: VectorClock
    pending_corrections*: seq[seq[T]]
    last_sync_time*: MonoTime
    sync_callbacks*: Table[ZID, proc(state: SyncState) {.gcsafe.}]
    change_callbacks*: Table[ZID, proc(changes: seq[CrdtChange[T]]) {.gcsafe.}]

# Vector clock operations
proc init*(_: type VectorClock, local_id: string): VectorClock =
  result = VectorClock()
  result.local_id = local_id
  result.clocks = init_table[string, uint64]()
  result.clocks[local_id] = 0

proc tick*(self: VectorClock) =
  ## Increment local clock
  self.clocks[self.local_id] = self.clocks.get_or_default(self.local_id, 0) + 1

proc update*(self: VectorClock, other: VectorClock) =
  ## Update this clock with information from another clock
  for peer_id, peer_time in other.clocks:
    if peer_id != self.local_id:
      self.clocks[peer_id] = max(
        self.clocks.get_or_default(peer_id, 0),
        peer_time
      )

proc total_events*(self: VectorClock): uint64 =
  ## Get total number of events across all peers
  result = 0
  for count in self.clocks.values:
    result += count

proc happened_before*(self: VectorClock, other: VectorClock): bool =
  ## Simple logical ordering: fewer total events happened before more events
  self.total_events() < other.total_events()

proc is_concurrent_with*(self: VectorClock, other: VectorClock): bool =
  ## Events are concurrent only if they have exactly the same total count AND same peer
  self.total_events() == other.total_events() and self.local_id == other.local_id

# Type aliases for common CRDT types
type
  CrdtZenTable*[K, V] = CrdtZenValue[Table[K, V]]
  # CrdtZenSeq has its own full implementation in crdt_zen_seq.nim
  CrdtZenSet*[T] = CrdtZenValue[HashSet[T]]

# Conflict resolution policies
type
  ConflictPolicy* = enum
    LastWriterWins     ## Use timestamp to resolve conflicts
    TakeLocal         ## Always prefer local value
    TakeRemote        ## Always prefer remote value  
    TakeHighest       ## For numeric values, take highest
    TakeLowest        ## For numeric values, take lowest
    Merge             ## Attempt to merge values (type-specific)
    Custom            ## Use custom resolution function
    
  ConflictResolver*[T] = proc(local, remote: T, local_clock, remote_clock: VectorClock): T {.gcsafe.}