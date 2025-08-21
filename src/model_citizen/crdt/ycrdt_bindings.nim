## Y-CRDT C-FFI bindings for Nim
## Based on yffi: https://github.com/y-crdt/y-crdt/tree/main/yffi

# Y-CRDT bindings - minimal imports for FFI

# Dynamic library loading - configured for platform-specific libraries
when defined(windows):
  const ycrdt_lib = "lib/yrs.dll"
elif defined(macosx):
  const ycrdt_lib = "lib/libyrs.dylib"
else:
  const ycrdt_lib = "lib/libyrs.so"

{.pragma: ycrdt, cdecl, dynlib: ycrdt_lib.}

# Core Y-CRDT types - opaque pointers matching C definitions
type
  YDoc* = pointer
  YTransaction* = pointer
  Branch* = pointer  # This is the actual shared data type
  YText* = Branch    # All shared types are actually Branch pointers
  YArray* = Branch
  YMap* = Branch
  YXmlElement* = Branch
  YXmlText* = Branch
  YValue* = pointer
  YOutput* = pointer
  
  YInput* = object
    tag*: int8
    len*: uint32
    value*: pointer  # Simplified for now - pointer to union content
  
  # Binary data representation
  YBinary* = object
    data*: ptr uint8
    len*: uint32
  
  # Change tracking
  YEventKind* = enum
    Y_EVENT_TEXT_CHANGE = 0
    Y_EVENT_ARRAY_CHANGE = 1
    Y_EVENT_MAP_CHANGE = 2
    Y_EVENT_XML_CHANGE = 3
  
  YEvent* = object
    kind*: YEventKind
    target*: YValue
    
  # Basic value types  
  YValueKind* = enum
    Y_VAL_UNDEFINED = 0
    Y_VAL_NULL = 1
    Y_VAL_BOOLEAN = 2
    Y_VAL_FLOAT64 = 3
    Y_VAL_INT64 = 4
    Y_VAL_STRING = 5
    Y_VAL_BYTES = 6
    Y_VAL_ARRAY = 7
    Y_VAL_MAP = 8
    Y_VAL_DOC = 9

# Document operations
proc ydoc_new*(): YDoc {.importc: "ydoc_new", ycrdt.}
proc ydoc_destroy*(doc: YDoc) {.importc: "ydoc_destroy", ycrdt.}

# Root type access (Branch types)
proc ytext*(doc: YDoc, name: cstring): Branch {.importc: "ytext", ycrdt.}
proc yarray*(doc: YDoc, name: cstring): Branch {.importc: "yarray", ycrdt.}
proc ymap*(doc: YDoc, name: cstring): Branch {.importc: "ymap", ycrdt.}

# Transaction operations
proc ydoc_read_transaction*(doc: YDoc): YTransaction {.importc: "ydoc_read_transaction", ycrdt.}
proc ydoc_write_transaction*(doc: YDoc): YTransaction {.importc: "ydoc_write_transaction", ycrdt.}
proc ytransaction_commit*(txn: YTransaction) {.importc: "ytransaction_commit", ycrdt.}
proc ytransaction_free*(txn: YTransaction) {.importc: "ytransaction_free", ycrdt.}

# Text operations (for basic string values)
proc ytext_insert*(text: YText, txn: YTransaction, index: uint32, chunk: cstring) {.importc: "ytext_insert", ycrdt.}
proc ytext_delete*(text: YText, txn: YTransaction, index: uint32, len: uint32) {.importc: "ytext_delete", ycrdt.}
proc ytext_to_string*(text: YText, txn: YTransaction): cstring {.importc: "ytext_to_string", ycrdt.}
proc ytext_len*(text: YText, txn: YTransaction): uint32 {.importc: "ytext_len", ycrdt.}

# Map operations (for key-value storage) 
proc ymap_insert*(map: Branch, txn: YTransaction, key: cstring, value: ptr YInput) {.importc: "ymap_insert", ycrdt.}
proc ymap_get*(map: Branch, txn: YTransaction, key: cstring): YOutput {.importc: "ymap_get", ycrdt.}
proc ymap_remove*(map: Branch, txn: YTransaction, key: cstring): YOutput {.importc: "ymap_remove", ycrdt.}

# Value creation and extraction
proc yinput_string*(value: cstring): YInput {.importc: "yinput_string", ycrdt.}
proc yinput_long*(value: int64): YInput {.importc: "yinput_long", ycrdt.}
proc yinput_float*(value: float64): YInput {.importc: "yinput_float", ycrdt.}
proc yinput_bool*(value: uint8): YInput {.importc: "yinput_bool", ycrdt.}
# Note: YInput is a value type, no destroy needed

proc youtput_kind*(output: YOutput): YValueKind {.importc: "youtput_kind", ycrdt.}
proc youtput_to_string*(output: YOutput): cstring {.importc: "youtput_to_string", ycrdt.}
proc youtput_to_int64*(output: YOutput): int64 {.importc: "youtput_to_int64", ycrdt.}
proc youtput_to_float64*(output: YOutput): float64 {.importc: "youtput_to_float64", ycrdt.}
proc youtput_to_bool*(output: YOutput): uint8 {.importc: "youtput_to_bool", ycrdt.}
proc youtput_destroy*(output: YOutput) {.importc: "youtput_destroy", ycrdt.}

# State synchronization
proc ydoc_encode_state_as_update*(doc: YDoc, binary: ptr YBinary) {.importc: "ydoc_encode_state_as_update", ycrdt.}
proc ydoc_apply_update*(doc: YDoc, update: YBinary) {.importc: "ydoc_apply_update", ycrdt.}
proc ydoc_encode_state_vector*(doc: YDoc, binary: ptr YBinary) {.importc: "ydoc_encode_state_vector", ycrdt.}
proc ydoc_diff*(doc: YDoc, state_vector: YBinary, binary: ptr YBinary) {.importc: "ydoc_diff", ycrdt.}

# Binary data management
proc ybinary_destroy*(binary: ptr YBinary) {.importc: "ybinary_destroy", ycrdt.}

# Helper procedures for Nim integration
proc to_string*(output: YOutput): string =
  if output != nil:
    let cstr = youtput_to_string(output)
    if cstr != nil:
      result = $cstr
    youtput_destroy(output)

# Template for safe Y-CRDT map insertion with proper pointer handling
template ymap_insert_safe*(map: Branch, txn: YTransaction, key: cstring, value: untyped) =
  when typeof(value) is string:
    var input = yinput_string(value.cstring)
  elif typeof(value) is int64:
    var input = yinput_long(value)
  elif typeof(value) is float64:
    var input = yinput_float(value)
  elif typeof(value) is bool:
    var input = yinput_bool(if value: 1'u8 else: 0'u8)
  elif typeof(value) is int:
    var input = yinput_long(value.int64)
  elif typeof(value) is float:
    var input = yinput_float(value.float64)
  else:
    {.error: "Unsupported type for Y-CRDT input".}
  
  ymap_insert(map, txn, key, addr input)

# Keep the old function for backward compatibility but make it safer
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
    let cstr = youtput_to_string(output)
    result = if cstr != nil: $cstr else: ""
  elif T is int64:
    result = youtput_to_int64(output)
  elif T is float64:
    result = youtput_to_float64(output)
  elif T is bool:
    result = youtput_to_bool(output) != 0
  elif T is int:
    result = youtput_to_int64(output).int
  elif T is float:
    result = youtput_to_float64(output).float
  else:
    {.error: "Unsupported type for Y-CRDT extraction".}