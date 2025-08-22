when defined(generate_ycrdt_binding):
  import std/strformat
  import std/[os, strutils, sequtils]
  import futhark

  proc rename_symbol(
      n: string, k: SymbolKind, p: string, overloading: var bool
  ): string =
    result = n
    if k in [Typedef, Enum, Struct, Anon]:
      result = n.split("_").map_it(it.capitalize_ascii()).join("")

  const
    lib_dir = current_source_path.parent_dir / ".." / ".." / ".." / "lib"
    sys_path =
      "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/"
    output_path =
      current_source_path.parent_dir / "generated" / "ycrdt_binding.nim"

  importc:
    # futhark symbols must be camelCase
    renameCallback rename_symbol
    sysPath sys_path
    path lib_dir
    outputPath output_path
    "libyrs.h"
else:
  import std/os
  import generated/ycrdt_binding
  export ycrdt_binding
  
  # Link the Y-CRDT dynamic library
  const lib_path = current_source_path.parent_dir / ".." / ".." / ".." / "lib"
  {.passL: "-L" & lib_path.}
  {.passL: "-lyrs".}

# Helper procedures for easier Y-CRDT usage
proc ydoc_write_transaction_simple*(doc: ptr YDoc_typedef): ptr YTransaction =
  ## Wrapper for the new API that requires origin parameters
  ydoc_write_transaction(doc, 0, nil)

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

# Y-CRDT Array operations for sequences
proc yarray_insert_safe*[T](array: ptr Branch, txn: ptr YTransaction, index: uint32, value: T) =
  ## Safe wrapper for inserting into Y-CRDT array
  let yinput = create_yinput(value)
  # Y-CRDT uses insert_range with length 1 for single item insertion
  yarray_insert_range(array, txn, index, addr yinput, 1)

proc yarray_remove_safe*(array: ptr Branch, txn: ptr YTransaction, index: uint32, length: uint32 = 1) =
  ## Safe wrapper for removing from Y-CRDT array
  yarray_remove_range(array, txn, index, length)

proc yarray_get_safe*[T](array: ptr Branch, txn: ptr YTransaction, index: uint32): T =
  ## Safe wrapper for getting from Y-CRDT array
  # This is a simplified version - full implementation would need Y-CRDT output parsing
  when T is string:
    result = ""  # Placeholder - would read from Y-CRDT output
  elif T is int:
    result = 0   # Placeholder - would read from Y-CRDT output
  else:
    result = T.default

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

template ymap_insert_safe*(map: ptr Branch, txn: ptr YTransaction, key: cstring, value: untyped) =
  var input = create_yinput(value)
  ymap_insert(map, txn, key, addr input)

proc to_string*(output: ptr YOutput): string =
  if output != nil:
    let cstr = youtput_read_string(output)
    if cstr != nil:
      result = $cstr
    youtput_destroy(output)