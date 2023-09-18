import std / [tables, intsets, locks]
import model_citizen / types {.all.}

var active_ctx* {.threadvar.}: ZenContext

var local_type_registry* {.threadvar.}: Table[int, RegisteredType]
var processed_types* {.threadvar.}: IntSet
var raw_type_registry: Table[int, RegisteredType]
var global_type_registry* = addr raw_type_registry
var type_registry_lock*: Lock
type_registry_lock.init_lock

template with_lock*(body: untyped) =
  {.gcsafe.}:
    locks.with_lock(type_registry_lock):
      body
