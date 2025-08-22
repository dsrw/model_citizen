## Unified CRDT functionality integrated into regular Zen types
## This replaces the separate CrdtZenValue approach with direct integration

import std/[tables, monotimes, sets]
import model_citizen/[types {.all.}, core]
import model_citizen/zens/private  # For privileged access
import ./[crdt_types]

# Template for privileged access to CRDT internals
template privileged_crdt =
  privileged
  private_access ZenBase
  private_access ZenContext

# Simplified API for testing unified approach

proc has_crdt_state*[T, O](zen: Zen[T, O]): bool =
  ## Check if this Zen object has CRDT state enabled
  when T is T and O is T:  # This is a ZenValue[T]
    zen.sync_mode != SyncMode.Yolo
  else:
    false

# Unified CRDT operations that work directly on ZenValue with CrdtState
proc set_crdt_value*[T, O](zen: Zen[T, O], new_value: T, op_ctx = OperationContext()) =
  ## Set value with CRDT synchronization (unified API)
  privileged_crdt
  when T is T and O is T:  # This is a ZenValue[T]
    if zen.sync_mode != SyncMode.Yolo:
      # For now, fall back to regular zen behavior until CRDT implementation is complete
      # This allows the unified API to work while we build out the full CRDT backend
      if zen.tracked != new_value:
        zen.tracked = new_value
        # TODO: Add CRDT sync logic here once backend is complete

# TODO: Implement full CRDT backend sync operations