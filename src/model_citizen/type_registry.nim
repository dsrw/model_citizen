import model_citizen / types / defs {.all.}
import std / [locks, tables, intsets, importutils, monotimes, times]
import pkg / flatty
import model_citizen / [typeids, logging, utils]

var local_type_registry* {.threadvar.}: Table[int, RegisteredType]
var processed_types* {.threadvar.}: IntSet
var raw_type_registry*: Table[int, RegisteredType]
var type_registry* = addr raw_type_registry
var type_registry_lock*: Lock
type_registry_lock.init_lock

template with_lock*(body: untyped) =
  {.gcsafe.}:
    locks.with_lock(type_registry_lock):
      body

template deref*(o: ref): untyped = o[]
template deref*(o: not ref): untyped = o

proc lookup_type*(key: int, registered_type: var RegisteredType): bool =
  if key in local_type_registry:
    registered_type = local_type_registry[key]
    result = true
  elif key in processed_types:
    # we don't want to lookup a type in the global registry if we've already
    # tried, since it needs a lock
    result = false
  else:
    processed_types.incl(key)
    with_lock:
      if key in type_registry[]:
        registered_type = type_registry[][key]
        local_type_registry[key] = registered_type
        result = true

proc lookup_type*(obj: ref RootObj, registered_type: var RegisteredType): bool =
  result = lookup_type(obj.type_id, registered_type)

  if not result:
    debug "type not registered", type_name = obj.base_type

proc register_type*(_: type Zen, typ: type) =
  log_defaults
  let key = typ.type_id

  with_lock:
    assert key notin type_registry[], "Type already registered"

  let stringify = func(self: ref RootObj): string =
    let self = typ(self)
    var clone = new typ
    clone[] = self[]
    for src, dest in fields(self[], clone[]):
      when src is Zen:
        if ?src:
          var field = type(src)()
          field.id = src.id
          dest = field
      elif src is ref:
        dest = nil
      elif (src is proc):
        dest = nil
      elif src.has_custom_pragma(zen_ignore):
        dest = dest.type.default
    {.no_side_effect.}:
      result = flatty.to_flatty(clone[])

  let parse = func(ctx: ZenContext, clone_from: string): ref RootObj =
    var self = typ()
    {.no_side_effect.}:
      self[] = from_flatty(clone_from, self[].type, ctx)
    for field in self[].fields:
      when field is Zen:
        if ?field and field.id in ctx:
          field = type(field)(ctx[field.id])
    result = self

  with_lock:
    type_registry[][key] = RegisteredType(stringify: stringify, parse: parse,
        tid: key)

proc ref_id*[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

proc ref_count*[O](self: ZenContext, changes: seq[Change[O]]) =
  private_access ZenContext
  log_defaults

  for change in changes:
    if not ?change.item:
      continue
    let id = change.item.ref_id
    if Added in change.changes:
      if id notin self.ref_pool:
        debug "saving ref", id
        self.ref_pool[id] = CountedRef()
      inc self.ref_pool[id].count
      self.ref_pool[id].obj = change.item
    if Removed in change.changes:
      assert id in self.ref_pool
      dec self.ref_pool[id].count
      if self.ref_pool[id].count == 0:
        self.freeable_refs[id] = get_mono_time() + init_duration(seconds = 10)
