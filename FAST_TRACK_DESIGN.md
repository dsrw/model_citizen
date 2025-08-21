# Fast-Track CRDT Implementation Design

## Dual-Mode Architecture

Perfect for multiplayer gaming! Two modes that can be toggled per-object:

### Mode 1: FastLocal (Default for Games)
```nim
# Changes apply immediately locally
player.position = new_pos  # Instant update, sync in background
# UI updates immediately, corrections come later if needed
```

### Mode 2: WaitForSync (For Critical Data)
```nim  
# Changes wait for CRDT consensus
player.score = new_score   # Waits for all peers to agree
# Slower but guaranteed consistent
```

## Technical Architecture

### Core Types
```nim
type
  CrdtMode* = enum
    FastLocal,    # Apply immediately, sync later  
    WaitForSync   # Wait for convergence

  SyncState* = enum
    LocalOnly,    # Only local changes
    Syncing,      # In progress
    Converged,    # All peers agree
    Conflicted    # Needs resolution

  CrdtZenValue*[T] = ref object of ZenBase
    # Dual values for dual-mode operation
    local_value: T           # Immediate local state
    crdt_value: T           # CRDT-converged state
    mode: CrdtMode
    sync_state: SyncState
    
    # Y-CRDT integration  
    y_doc: ptr YDoc         # Y-CRDT document
    y_value: ptr YValue     # Y-CRDT shared value
    
    # Conflict handling
    pending_corrections: seq[T]
    last_sync_time: MonoTime
```

### API Design - Zero Breaking Changes!

```nim
# Existing API works exactly the same
var player_pos = ZenValue[Vector3].init(ctx, id = "player_pos")
player_pos.value = Vector3(x: 10, y: 5, z: 0)  # FastLocal by default

# New APIs for control
player_pos.set_sync_mode(WaitForSync)  # When consistency matters
player_pos.set_sync_mode(FastLocal)    # When speed matters

# Enhanced tracking with sync info
player_pos.track proc(changes: seq[CrdtChange[Vector3]]) =
  for change in changes:
    if change.sync_state == Converged:
      echo "Position confirmed by all players"
    elif change.sync_state == Conflicted:
      echo "Position conflict detected, using: ", change.resolved_value
```

## Week 1 Implementation Plan

### Day 1-2: Y-CRDT Nim Bindings

**Task**: Create minimal Nim wrapper for Y-CRDT C-FFI

```nim
# src/model_citizen/crdt/ycrdt_bindings.nim
{.pragma: ycrdt, cdecl, dynlib: "libyrs.so".}

type
  YDoc* = object
  YValue* = object
  YTransaction* = object

proc y_doc_new*(): ptr YDoc {.importc: "ydoc_new", ycrdt.}
proc y_doc_get_or_insert_text*(doc: ptr YDoc, name: cstring): ptr YValue {.importc, ycrdt.}
proc y_value_to_string*(value: ptr YValue): cstring {.importc, ycrdt.}
# ... more bindings as needed
```

### Day 3-4: Dual-Mode Foundation

**Task**: Create `CrdtZenValue` with mode switching

```nim
# src/model_citizen/crdt/crdt_zen_value.nim
proc init*[T](_: type CrdtZenValue[T], ctx: ZenContext, 
              id: string = "", mode = FastLocal): CrdtZenValue[T] =
  result = CrdtZenValue[T]()
  result.init_zen_base(ctx, id)
  result.mode = mode
  result.sync_state = LocalOnly
  result.y_doc = y_doc_new()
  # Initialize Y-CRDT structures
```

### Day 5-7: Basic Operations

**Task**: Implement get/set with CRDT sync

```nim
proc `value=`*[T](self: CrdtZenValue[T], new_value: T) =
  # Always update local immediately (game responsiveness)
  self.local_value = new_value
  
  if self.mode == FastLocal:
    # Trigger callbacks immediately with local data
    self.trigger_local_change(new_value)
    # Sync to CRDT in background
    self.sync_to_crdt_async(new_value)
  else:
    # WaitForSync mode - wait for CRDT consensus
    self.sync_to_crdt_blocking(new_value)

proc value*[T](self: CrdtZenValue[T]): T =
  case self.mode:
  of FastLocal: self.local_value    # Always fast
  of WaitForSync: self.crdt_value   # Always consistent
```

## Week 2: Game Features

### Day 1-3: Fast Sync + Corrections

```nim
proc check_for_corrections*[T](self: CrdtZenValue[T]) =
  # Compare local vs CRDT state
  if self.local_value != self.crdt_value:
    self.sync_state = Conflicted
    # Trigger correction callback
    let correction = CrdtChange[T](
      old_value: self.local_value,
      new_value: self.crdt_value, 
      sync_state: Conflicted,
      is_correction: true
    )
    self.trigger_callbacks(@[correction])
```

### Day 4-7: Integration + Testing

- Wire into existing `ZenContext.boop()` for background sync
- Add sync metrics and monitoring  
- Create conflict resolution policies
- Test with Enu multiplayer scenarios

## Performance Targets

**FastLocal Mode** (Gaming):
- Local updates: < 1ms
- Network sync: Background, ~10-50ms
- Corrections: Rare, ~100ms when they occur

**WaitForSync Mode** (Critical):
- Consensus updates: ~50-200ms depending on network
- Guaranteed consistency across all peers

## Integration Strategy

### Zero-Disruption Migration
1. Keep existing `ZenValue` exactly as-is
2. Add `CrdtZenValue` as new type  
3. Enu can migrate objects one-by-one
4. No breaking changes to reactive callbacks

### Enu-Specific Optimizations
```nim
# Fast mode for player movement  
player.position.set_sync_mode(FastLocal)

# Consistent mode for game state
game.score.set_sync_mode(WaitForSync)  
game.winner.set_sync_mode(WaitForSync)

# Hybrid: fast local, eventual consistency
player.health.set_sync_mode(FastLocal)
player.health.set_correction_policy(TakeAverage)  # Custom conflict resolution
```

## Next Steps

1. **This Week**: Set up Y-CRDT bindings and basic structure
2. **Week 2**: Implement dual-mode `CrdtZenValue`  
3. **Week 3**: Integrate with Enu for real-world testing
4. **Week 4+**: Expand to `CrdtZenTable`, `CrdtZenSeq` based on needs

This gets you a production-ready CRDT system optimized for gaming in ~2-3 weeks, with the reactive model you love and the consistency guarantees you need!