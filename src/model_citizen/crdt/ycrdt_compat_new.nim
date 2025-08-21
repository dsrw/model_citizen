## Y-CRDT compatibility layer for the futhark binding
## Provides clean interface using exact futhark generated types

import ./ycrdt_futhark
export ycrdt_futhark

# Use exact futhark generated types - no aliases to avoid recursion
# YDoc* is already defined as YDoc_typedef (struct) in the binding
# Functions return ptr YDoc_typedef, ptr Branch, etc.

# Wrapper procedures that match the old API
proc ydoc_write_transaction_simple*(doc: ptr YDoc_typedef): ptr YTransaction =
  ## Wrapper for the new API that requires origin parameters
  ydoc_write_transaction(doc, 0, nil)

# Helper procedures that match the old API
proc create_yinput*[T](value: T): YInput =
  when T is string:
    result = yinput_string(value.cstring)
  elif T is int64:
    result = yinput_long(value)
  elif T is float64:
    result = yinput_float(value)
  elif T is bool:
    result = yinput_bool(if value: 1'u8 else: 0'u8)
  elif T is int:
    result = yinput_long(value.int64)
  elif T is float:
    result = yinput_float(value.float64)
  else:
    {.error: "Unsupported type for Y-CRDT input".}

proc extract_value*[T](output: ptr YOutput, target_type: type T): T =
  if output == nil:
    return T.default
    
  defer: youtput_destroy(output)
  
  when T is string:
    let cstr = youtput_read_string(output)
    result = if cstr != nil: $cstr else: ""
  elif T is int64:
    let ptr_val = youtput_read_long(output)
    result = if ptr_val != nil: ptr_val[] else: 0'i64
  elif T is float64:
    let ptr_val = youtput_read_float(output)
    result = if ptr_val != nil: ptr_val[] else: 0.0
  elif T is bool:
    let ptr_val = youtput_read_bool(output)
    result = if ptr_val != nil: ptr_val[] != 0 else: false
  elif T is int:
    let ptr_val = youtput_read_long(output)
    result = if ptr_val != nil: ptr_val[].int else: 0
  elif T is float:
    let ptr_val = youtput_read_float(output)
    result = if ptr_val != nil: ptr_val[].float else: 0.0
  else:
    {.error: "Unsupported type for Y-CRDT extraction".}

# Template for safe Y-CRDT map insertion with proper pointer handling
template ymap_insert_safe*(map: ptr Branch, txn: ptr YTransaction, key: cstring, value: untyped) =
  var input = create_yinput(value)
  ymap_insert(map, txn, key, addr input)

# String conversion helper
proc to_string*(output: ptr YOutput): string =
  if output != nil:
    let cstr = youtput_read_string(output)
    if cstr != nil:
      result = $cstr
    youtput_destroy(output)