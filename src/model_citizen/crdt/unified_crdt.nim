## Unified CRDT functionality integrated into regular Zen types
## This replaces the separate CrdtZenValue approach with direct integration

import std/[tables, monotimes, sets]
import model_citizen/[types {.all.}, core]
import model_citizen/zens/private  # For privileged access
import model_citizen/components/private/tracking  # For mutate template
import ./[crdt_types, ycrdt_futhark, document_coordinator]

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

# Helper to get or create Y-CRDT document for a ZenValue
proc get_crdt_document[T, O](zen: Zen[T, O]): ptr YDoc_typedef =
  when T is T and O is T:  # This is a ZenValue[T]
    result = get_shared_document(zen.ctx.id, "ZenValue", zen.id)

# Unified CRDT operations that work directly on ZenValue
proc set_crdt_value*[T, O](zen: Zen[T, O], new_value: T, op_ctx = OperationContext()) =
  ## Set value with CRDT synchronization (unified API)
  privileged_crdt
  when T is T and O is T:  # This is a ZenValue[T]
    if zen.sync_mode != SyncMode.Yolo:
      # Get or create Y-CRDT document for this ZenValue
      let doc = get_crdt_document(zen)
      if doc == nil:
        # Fallback to regular behavior if Y-CRDT fails
        if zen.tracked != new_value:
          let self = zen
          mutate(op_ctx):
            self.tracked = new_value
        return
      
      # Create Y-CRDT map for storing the value
      let map = ymap(doc, "value".cstring)
      if map == nil:
        # Fallback if map creation fails
        if zen.tracked != new_value:
          let self = zen
          mutate(op_ctx):
            self.tracked = new_value
        return
      
      # Start transaction
      let txn = ydoc_write_transaction_simple(doc)
      if txn == nil:
        # Fallback if transaction fails
        if zen.tracked != new_value:
          let self = zen
          mutate(op_ctx):
            self.tracked = new_value
        return
      
      try:
        # Convert new_value to YInput and insert into Y-CRDT map
        when T is string:
          var input = yinput_string(new_value.cstring)
          ymap_insert(map, txn, "data".cstring, addr input)
        elif T is int:
          var input = yinput_long(new_value.int64)
          ymap_insert(map, txn, "data".cstring, addr input)
        elif T is float:
          var input = yinput_float(new_value.float64)
          ymap_insert(map, txn, "data".cstring, addr input)
        elif T is bool:
          var input = yinput_bool(if new_value: 1'u8 else: 0'u8)
          ymap_insert(map, txn, "data".cstring, addr input)
        else:
          # For complex types, use string serialization as fallback
          when compiles($new_value):
            var input = yinput_string(($new_value).cstring)
            ymap_insert(map, txn, "data".cstring, addr input)
          else:
            # If type doesn't support string conversion, fallback to regular Zen
            if zen.tracked != new_value:
              let self = zen
              mutate(op_ctx):
                self.tracked = new_value
            ytransaction_commit(txn)
            return
        
        # Commit the transaction
        ytransaction_commit(txn)
        
        # Update local tracked value based on sync mode using regular Zen mutation
        case zen.sync_mode:
        of FastLocal:
          # Update immediately for responsiveness using proper mutation
          if zen.tracked != new_value:
            let self = zen
            mutate(op_ctx):
              self.tracked = new_value
        of WaitForSync:
          # For WaitForSync, we should read back from CRDT to ensure consistency
          # For now, update immediately - TODO: implement proper sync waiting
          if zen.tracked != new_value:
            let self = zen
            mutate(op_ctx):
              self.tracked = new_value
        of Yolo:
          # Should not reach here
          discard
          
      except CatchableError:
        # Clean up transaction and fallback to regular behavior
        ytransaction_commit(txn)
        if zen.tracked != new_value:
          let self = zen
          mutate(op_ctx):
            self.tracked = new_value

proc get_crdt_value*[T, O](zen: Zen[T, O]): T =
  ## Get value from CRDT synchronization (unified API)  
  privileged_crdt
  when T is T and O is T:  # This is a ZenValue[T]
    if zen.sync_mode != SyncMode.Yolo:
      # For now, return the tracked value
      # TODO: Implement reading from Y-CRDT document
      return zen.tracked
    else:
      return zen.tracked
  else:
    return zen.tracked