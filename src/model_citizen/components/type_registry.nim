import std / [locks, intsets, macros, typetraits, strutils]
import std / macrocache except value
import model_citizen / core
import model_citizen / types / [private, defs {.all.}]
import ./ private / global_state

template deref*(o: ref): untyped = o[]
template deref*(o: not ref): untyped = o

const created_procs = CacheSeq"created_procs"
const change_fields = CacheTable"change_fields"

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
    assert key notin global_type_registry[], "Type already registered"

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

proc build_change_handler(self, field, body: NimNode): NimNode =
  result = quote do:
    `self`.`field`.changes:
      `body`

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

proc contains(self: CacheSeq, value: NimNode): bool =
  for val in self:
    if val == value:
      return true

proc contains(self: CacheTable, key: string): bool =
  for k, v in self.pairs:
    if k == key:
      return true

macro build_accessors(T: type, obj: object, public: bool): untyped =
  result = new_stmt_list()
  var type_sym = obj
  var names: seq[string]
  var self_type = T
  var base_type = T

  while type_sym.kind != nnk_empty:
    let type_impl = type_sym.get_type_impl

    # get the object type for refs
    if type_impl.kind == nnk_ref_ty:
      type_sym = type_impl[0]
      self_type = type_impl
      continue

    for def in type_impl[2]:
      assert def.kind == nnk_ident_defs
      let name = def[0].str_val
      if (not def[0].is_exported) and is_zen(def[1]):
        base_type = self_type
        names.add name
        let sym = ident(name)
        let setter = ident(name & "=")

        let value_type = def[1]
        echo "type_sym: ", type_sym.tree_repr
        echo "type_impl: ", type_impl.tree_repr

        let id = ident(self_type.repr & " " & name)
        var create_accessors = true
        for proc_id in created_procs:
          echo "id: ", id.str_val, " proc_id: ", proc_id.str_val
          if proc_id.str_val == id.str_val:
            create_accessors = false
            break
        if create_accessors:
          created_procs.incl(id)
          result.add quote("@") do:
            type V = value(`@value_type`.default).type
            when `@public`:
              proc `@sym`*(self: `@self_type`): V = value(self.`@sym`)
              proc `@setter`*(self: `@self_type`, value: V) =
                self.`@sym`.value = value
            else:
              proc `@sym`(self: `@self_type`): V = value(self.`@sym`)
              proc `@setter`(self: `@self_type`, value: V) =
                self.`@sym`.value = value

    type_sym = if type_impl[1].kind == nnk_of_inherit:
      type_impl[1][0]
    else:
      new_empty_node()

  if names.len > 0:
    let base_type_id = base_type.repr
    if base_type_id notin change_fields:
      change_fields[base_type_id] = new_lit(names.join(","))
      result.add quote do:
        macro changes(self: `base_type`, field: untyped, body: untyped): untyped =
          field.expect_kind(nnk_ident)
          let field_name = field.str_val
          let names = change_fields[`base_type_id`].str_val.split(",")
          if field_name notin names:
            macros.error("Invalid zen field `" & field_name & "` Options are: " &
                $names, field)

          result = build_change_handler(self, field, body)
    else:
      let old_names = change_fields[base_type_id].str_val.split(",")
      for name in old_names:
        if name notin names:
          names.add name
      change_fields[base_type_id].str_val = names.join(",")

  echo "*****"
  echo result.repr

template build_accessors*(_: type Zen, T: type[ref object], public: bool = true): untyped =
  build_accessors(T, T.default[], public)

macro register*(_: type Zen, typ: type, public = true): untyped =
  result = new_stmt_list()
  result.add quote do:
    register_type(`typ`)
    Zen.build_accessors(`typ`, `public`)

proc ref_id*[T: ref RootObj](value: T): string {.inline.} =
  $value.type_id & ":" & $value.id

proc ref_count*[O](self: ZenContext, changes: seq[Change[O]]) =
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
      inc self.ref_pool[id].count
      self.ref_pool[id].obj = change.item
    if Removed in change.changes:
      assert id in self.ref_pool
      dec self.ref_pool[id].count
      if self.ref_pool[id].count == 0:
        self.freeable_refs[id] = get_mono_time() + init_duration(seconds = 10)

proc find_ref*[T](self: ZenContext, value: var T): bool =
  privileged

  if ?value:
    let id = value.ref_id
    if id in self.ref_pool:
      value = T(self.ref_pool[id].obj)
      result = true

proc free_refs*(self: ZenContext) =
  privileged

  var to_remove: seq[string]
  for id, free_at in self.freeable_refs:
    assert self.ref_pool[id].count >= 0
    if self.ref_pool[id].count == 0 and free_at < get_mono_time():
      self.ref_pool.del(id)
      to_remove.add(id)
    elif self.ref_pool[id].count > 0:
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
      let count = self.ref_pool[id].count
      raise_assert \"ref `{id}` has {count} references. Can't free."
    else:
      raise_assert \"unable to find ref_id `{id}` in freeable refs. Double free?"

  assert self.ref_pool[id].count == 0
  self.ref_pool.del(id)
  self.freeable_refs.del(id)

when is_main_module:
  import ./ subscriptions
  type
    Unit = ref object of RootObj
      id*: string
      name*: string

  Zen.register(Unit)
