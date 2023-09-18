import std / [locks, intsets, macros, typetraits, strutils]
import std / macrocache except value
import model_citizen / core
import model_citizen / [types {.all.}, zens / private]
import ./ private / global_state

template deref*(o: ref): untyped = o[]
template deref*(o: not ref): untyped = o

const created_procs = CacheSeq"created_procs"

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
      if key in global_type_registry[]:
        registered_type = global_type_registry[][key]
        local_type_registry[key] = registered_type
        result = true

proc lookup_type*(obj: ref RootObj, registered_type: var RegisteredType): bool =
  result = lookup_type(obj.type_id, registered_type)

  if not result:
    debug "type not registered", type_name = obj.base_type

proc register_type(typ: type) =
  log_defaults
  let key = typ.type_id

  with_lock:
    ensure key notin global_type_registry[], "Type already registered"

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
    global_type_registry[][key] = RegisteredType(stringify: stringify,
        parse: parse, tid: key)

proc value_type[T, O](self: Zen[T, O]): type O = O

proc build_zen_accessor(self, field: NimNode): NimNode =
  result = quote do:
    `self`.`field`

proc is_zen(node: NimNode): bool =
  if node.kind == nnk_sym and node.str_val == "ZenBase":
    return true

  let info = node.get_type_impl

  if info.kind == nnk_ref_ty:
    return is_zen(info[0])
  elif info.kind == nnk_object_ty and info[1].kind == nnk_of_inherit:
    return is_zen(info[1][0])
  elif info.kind == nnk_bracket_expr and not node.eq_ident(info[0]):
    return is_zen(info[0])

proc export_routine(self: NimNode) =
  self[0] = new_nim_node(nnk_postfix).add(ident("*")).add(self[0])

proc get_value_type(self: NimNode): NimNode =
  if self.kind == nnk_sym:
    let def = self.get_impl
    if def.len >= 3 and def[2].kind == nnk_bracket_expr:
      if def[2][0].kind == nnk_sym and def[2][0].str_val == "ZenValue":
        return def[2][1]

  elif self.kind == nnk_bracket_expr:
    if self[0].str_val.starts_with("Zen"):
      return self[1]

  error "get_value_type doesn't know how to handle type:\n\n" &
      self.tree_repr & "\n\nThis is probably a model_citizen bug.", self

macro build_accessors(T: type, public: bool): untyped =
  result = new_stmt_list()
  var type_sym = T
  var base_type = T
  var names: seq[string]

  while type_sym.kind != nnk_empty and type_sym != bind_sym("RootObj") and
      type_sym != bind_sym("RootRef"):

    base_type = type_sym
    let type_impl = type_sym.get_impl

    for def in type_impl[2][0][2]:
      ensure def.kind == nnk_ident_defs

      var def_count = def.len - 1
      if def[^1].kind == nnk_empty:
        dec def_count
      var field_defs = def[0..<def_count]
      var type_def = def[def_count]

      for ident in field_defs:
        var ident = ident
        if ident.kind == nnk_postfix:
          ident = ident[1]

        if ident.kind != nnk_ident:
          continue

        let name = ident.str_val
        if name.to_lower.ends_with("value") and is_zen(type_def):
          let getter_name = if name.ends_with("_value"):
            name[0..^7]
          else:
            name[0..^6]
          names.add getter_name

          let
            sym = ident(name)
            getter = ident(getter_name)
            setter = ident(getter_name & "=")
            id = ident(type_sym.repr & " " & name)
            value_type = get_value_type(type_def)

          var create_accessors = true

          for proc_id in created_procs:
            if proc_id.str_val == id.str_val:
              create_accessors = false
              break

          if create_accessors:
            created_procs.incl(id)

            var accessors = quote do:
              proc `getter`(self: `type_sym`): `value_type` = value(self.`sym`)
              proc `setter`(self: `type_sym`, value: `value_type`) =
                self.`sym`.value = value

            if public.bool_val:
              accessors[0].export_routine
              accessors[1].export_routine
            result.add accessors

    type_sym = if type_impl[2][0][1].kind == nnk_of_inherit:
      type_impl[2][0][1][0]
    else:
      new_empty_node()

template build_accessors*(_: type Zen, T: type[ref object],
    public: bool = true): untyped =

  build_accessors(T, public)

macro register*(_: type Zen, typ: type, public = true): untyped =
  result = new_stmt_list()
  result.add quote do:
    register_type(`typ`)
    Zen.build_accessors(`typ`, `public`)

proc ref_id*[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

proc ref_count*[O](self: ZenContext, changes: seq[Change[O]], zen_id: string) =
  privileged
  log_defaults

  for change in changes:
    if not ?change.item:
      continue
    let id = change.item.ref_id
    if Added in change.changes:
      if id notin self.ref_pool:
        debug "saving ref", id
        self.ref_pool[id] = CountedRef()
      self.ref_pool[id].references.incl(zen_id)
      self.ref_pool[id].obj = change.item
    if Removed in change.changes:
      ensure id in self.ref_pool
      self.ref_pool[id].references.excl(zen_id)
      if self.ref_pool[id].references.card == 0:
        self.freeable_refs[id] = get_mono_time() + init_duration(seconds = 10)

proc find_ref*[T](self: ZenContext, value: var T): bool =
  privileged

  if ?value:
    let id = value.ref_id
    if id in self.ref_pool:
      value = T(self.ref_pool[id].obj)
      result = true

when defined(dump_zen_objects):
  import std / [os, algorithm]

proc free_refs*(self: ZenContext) =
  privileged

  when defined(dump_zen_objects):
    let now = get_mono_time()
    if now > self.dump_at:
      write_file(self.id, self.objects.keys.to_seq.sorted.join("\n"))
      var counts = ""
      for kind in MessageKind:
        counts &= $kind & ": " & $self.counts[kind] & "\n"
      write_file("counts", counts)
      self.dump_at = now + init_duration(seconds = 10)

  var to_remove: seq[string]
  for id, free_at in self.freeable_refs:
    if self.ref_pool[id].references.card == 0 and free_at < get_mono_time():
      self.ref_pool.del(id)
      to_remove.add(id)
    elif self.ref_pool[id].references.card > 0:
      to_remove.add(id)
  for id in to_remove:
    debug "freeing ref", id
    self.freeable_refs.del(id)

proc free*[T: ref RootObj](self: ZenContext, value: T) =
  privileged

  let id = value.ref_id
  debug "freeing ref", id

  if id notin self.freeable_refs:
    if id in self.ref_pool:
      let count = self.ref_pool[id].references.card
      let references = self.ref_pool[id].references.to_seq.join(", ")
      fail \"ref `{id}` has {count} references from {references}. Can't free."
    else:
      fail \"unable to find ref_id `{id}` in freeable refs. Double free?"

  ensure self.ref_pool[id].references.card == 0
  self.ref_pool.del(id)
  self.freeable_refs.del(id)

when is_main_module:
  import ./ subscriptions
  type
    Unit = ref object of RootObj
      id*: string
      name*: string

  Zen.register(Unit)
