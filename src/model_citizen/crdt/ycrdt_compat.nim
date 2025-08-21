## Y-CRDT compatibility layer for the futhark binding
## Provides clean type aliases and helper functions

import ./ycrdt_futhark

# Re-export the exact types from the futhark binding for direct use
export YDoc_typedef, Branch, YInput, YOutput, YTransaction

# Type aliases for cleaner code - use pointer types from the binding
type
  YDoc* = ptr YDoc_typedef
  YOutput* = ptr YOutput  # Pointer to YOutput struct (functions return ptr YOutput)
  YText* = ptr Branch    # All shared types are Branch pointers
  YArray* = ptr Branch
  YMap* = ptr Branch
  YXmlElement* = ptr Branch
  YXmlText* = ptr Branch
  
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

proc extract_value*[T](output: YOutput, target_type: type T): T =
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
template ymap_insert_safe*(map: YMap, txn: YTransaction, key: cstring, value: untyped) =
  var input = create_yinput(value)
  ymap_insert(map, txn, key, addr input)

# String conversion helper
proc to_string*(output: YOutput): string =
  if output != nil:
    let cstr = youtput_read_string(output)
    if cstr != nil:
      result = $cstr
    youtput_destroy(output)