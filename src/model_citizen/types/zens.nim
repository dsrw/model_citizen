import std / [macros, macrocache, importutils]
import pkg / threading / channels
import pkg / [chronicles]
import pkg / netty except Message
import defs {.all.}
import contexts
import model_citizen / [utils, logging, type_registry]
import model_citizen / operations {.all.}
import contexts
export Zen, ZenValue, ZenTable, ZenSet, ZenSeq

proc ctx: ZenContext = Zen.thread_ctx

template setup_op_ctx(self: ZenContext) =
  let op_ctx = if ?op_ctx:
    op_ctx
  else:
    OperationContext(source: self.name)

proc contains*[T, O](self: Zen[T, O], child: O): bool =
  private_access ZenObject
  assert self.valid
  child in self.tracked

proc contains*[K, V](self: ZenTable[K, V], key: K): bool =
  private_access ZenObject
  assert self.valid
  key in self.tracked

proc contains*[T, O](self: Zen[T, O], children: set[O] | seq[O]): bool =
  assert self.valid
  result = true
  for child in children:
    if child notin self:
      return false

proc len[T, O](self: Zen[T, O]): int =
  private_access ZenObject
  assert self.valid
  self.tracked.len

proc defaults[T, O](self: Zen[T, O], ctx: ZenContext, id: string,
    op_ctx: OperationContext): Zen[T, O] {.gcsafe.}

proc init*(T: type Zen, flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): T =

  ctx.setup_op_ctx
  T(flags: flags).defaults(ctx, id, op_ctx)

proc init*(_: type, T: type[string], flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): Zen[string, string] =

  ctx.setup_op_ctx
  result = Zen[string, string](flags: flags).defaults(ctx, id, op_ctx)

proc init*(_: type Zen,
    T: type[ref | object | SomeOrdinal | SomeNumber],
    flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): Zen[T, T] =

  ctx.setup_op_ctx
  result = Zen[T, T](flags: flags).defaults(ctx, id, op_ctx)

proc init*[T: ref | object | SomeOrdinal | SomeNumber | string | ptr](
    _: type Zen, tracked: T, flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[T, T] =

  ctx.setup_op_ctx
  var self = Zen[T, T](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: set[O], flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): Zen[set[O], O] =

  ctx.setup_op_ctx
  var self = Zen[set[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[K, V](_: type Zen, tracked: Table[K, V], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()
    ): ZenTable[K, V] =

  ctx.setup_op_ctx
  var self = ZenTable[K, V](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked
  result = self

proc init*[O](_: type Zen, tracked: open_array[O], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()
    ): Zen[seq[O], O] =

  ctx.setup_op_ctx
  var self = Zen[seq[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

  mutate(op_ctx):
    self.tracked = tracked.to_seq
  result = self

proc init*[O](_: type Zen, T: type seq[O], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()
    ): Zen[seq[O], O] =

  ctx.setup_op_ctx
  result = Zen[seq[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[O](_: type Zen, T: type set[O], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()
    ): Zen[set[O], O] =

  ctx.setup_op_ctx
  result = Zen[set[O], O](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[K, V](_: type Zen, T: type Table[K, V], flags = default_flags,
    ctx = ctx(), id = "", op_ctx = OperationContext()):
    Zen[Table[K, V], Pair[K, V]] =

  ctx.setup_op_ctx
  result = Zen[Table[K, V], Pair[K, V]](flags: flags)
      .defaults(ctx, id, op_ctx)

proc init*(_: type Zen, K, V: type, flags = default_flags, ctx = ctx(),
    id = "", op_ctx = OperationContext()): ZenTable[K, V] =

  ctx.setup_op_ctx
  result = ZenTable[K, V](flags: flags).defaults(
      ctx, id, op_ctx)

proc init*[K, V](t: type Zen, tracked: open_array[(K, V)],
    flags = default_flags, ctx = ctx(), id = "",
    op_ctx = OperationContext()): ZenTable[K, V] =

  ctx.setup_op_ctx
  result = Zen.init(tracked.to_table, flags = flags,
    ctx = ctx, id = id, op_ctx = op_ctx)

proc init*[T, O](self: var Zen[T, O], ctx = ctx(), id = "",
    op_ctx = OperationContext()) =

  self = Zen[T, O].init(ctx = ctx, id = id, op_ctx = op_ctx)

proc clear*[T, O](self: Zen[T, O]) =
  assert self.valid
  mutate(OperationContext(source: self.ctx.name)):
    self.tracked = T.default

proc `value=`*[T, O](self: Zen[T, O], value: T, op_ctx = OperationContext()) =
  private_access ZenObject[T, O]

  assert self.valid
  self.ctx.setup_op_ctx
  if self.tracked != value:
    mutate(op_ctx):
      self.tracked = value

proc value*[T, O](self: Zen[T, O]): T =
  private_access ZenObject
  assert self.valid
  self.tracked

proc `[]`*[K, V](self: Zen[Table[K, V], Pair[K, V]], index: K): V =
  private_access ZenObject
  assert self.valid
  self.tracked[index]

proc `[]`*[T](self: ZenSeq[T], index: SomeOrdinal | BackwardsIndex): T =
  private_access ZenObject
  assert self.valid
  self.tracked[index]

proc `[]=`*[K, V](self: ZenTable[K, V], key: K, value: V,
    op_ctx = OperationContext()) =

  self.ctx.setup_op_ctx
  self.put(key, value, touch = false, op_ctx)

proc `[]=`*[T](self: ZenSeq[T], index: SomeOrdinal, value: T,
    op_ctx = OperationContext()) =

  self.ctx.setup_op_ctx
  assert self.valid
  mutate(op_ctx):
    self.tracked[index] = value

proc add*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  private_access ZenObject
  self.ctx.setup_op_ctx
  when O is Zen:
    assert self.valid(value)
  else:
    assert self.valid
  self.tracked.add value
  let added = @[Change.init(value, {Added})]
  self.link_or_unlink(added, true)
  when O isnot Zen and O is ref:
    self.ctx.ref_count(added)

  self.publish_changes(added, op_ctx)
  self.trigger_callbacks(added)

template remove(self, key, item_exp, fun, op_ctx) =
  let obj = item_exp
  self.tracked.fun key
  let removed = @[Change.init(obj, {Removed})]
  self.link_or_unlink(removed, false)
  when obj isnot Zen and obj is ref:
    self.ctx.ref_count(removed)

  self.publish_changes(removed, op_ctx)
  self.trigger_callbacks(removed)

proc del*[T, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  self.ctx.setup_op_ctx
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, del, op_ctx)

proc del*[K, V](self: ZenTable[K, V], key: K, op_ctx = OperationContext()) =
  private_access ZenObject
  self.ctx.setup_op_ctx
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), del, op_ctx)

proc del*[T: seq, O](self: Zen[T, O], index: SomeOrdinal,
    op_ctx = OperationContext()) =

  private_access ZenObject

  self.ctx.setup_op_ctx
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], del, op_ctx)

proc delete*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  if value in self.tracked:
    remove(self, value, value, delete,
        op_ctx = OperationContext(source: [self.ctx.name].to_hash_set))

proc delete*[K, V](self: ZenTable[K, V], key: K) =
  assert self.valid
  if key in self.tracked:
    remove(self, key, (key: key, value: self.tracked[key]), delete,
        op_ctx = OperationContext())

proc delete*[T: seq, O](self: Zen[T, O], index: SomeOrdinal) =
  assert self.valid
  if index < self.tracked.len:
    remove(self, index, self.tracked[index], delete,
        op_ctx = OperationContext())

proc touch[K, V](self: ZenTable[K, V], pair: Pair[K, V],
    op_ctx: OperationContext) =

  assert self.valid
  self.put(pair.key, pair.value, touch = true, op_ctx = op_ctx)

proc touch*[T, O](self: ZenTable[T, O], key: T, value: O,
    op_ctx = OperationContext()) =

  assert self.valid
  self.put(key, value, touch = true, op_ctx = op_ctx)

proc touch*[T: set, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch({value}, true, op_ctx = op_ctx)

proc touch*[T: seq, O](self: Zen[T, O], value: O, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch(@[value], true, op_ctx = op_ctx)

proc touch*[T, O](self: Zen[T, O], value: T, op_ctx = OperationContext()) =
  assert self.valid
  self.change_and_touch(value, true, op_ctx = op_ctx)

proc touch*[T](self: ZenValue[T], value: T, op_ctx = OperationContext()) =
  assert self.valid
  mutate_and_touch(touch = true, op_ctx):
    self.tracked = value

proc len*(self: Zen): int =
  private_access ZenObject
  assert self.valid
  self.tracked.len

proc `+=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, true, op_ctx = OperationContext())

proc `+=`*[O](self: ZenSet[O], value: O) =
  assert self.valid
  self.change({value}, true, op_ctx = OperationContext())

proc `+=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.add(value)

proc `-=`*[T, O](self: Zen[T, O], value: T) =
  assert self.valid
  self.change(value, false, op_ctx = OperationContext())

proc `-=`*[T: set, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change({value}, false, op_ctx = OperationContext())

proc `-=`*[T: seq, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.change(@[value], false, op_ctx = OperationContext())

proc `&=`*[T, O](self: Zen[T, O], value: O) =
  assert self.valid
  self.value = self.value & value

proc `==`*(a, b: Zen): bool =
  private_access ZenObject
  a.is_nil == b.is_nil and a.destroyed == b.destroyed and
    a.tracked == b.tracked and a.id == b.id

proc defaults[T, O](self: Zen[T, O], ctx: ZenContext, id: string,
    op_ctx: OperationContext): Zen[T, O] =

  private_access ZenObject[T, O]
  private_access ZenBase
  private_access ZenContext
  log_defaults

  self.id = if id == "":
    $self.type & "-" & generate_id()
  else:
    id

  ctx.objects[self.id] = self

  self.publish_create = proc(sub: Subscription, broadcast: bool,
      op_ctx = OperationContext()) =
    log_defaults "model_citizen publishing"
    debug "publish_create", sub

    {.gcsafe.}:
      let bin = self.tracked.to_flatty
    let id = self.id
    let flags = self.flags

    template send_msg(src_ctx, sub) =
      const zen_type_id = self.type.tid

      static:
        type value_type = self.tracked.type
        type zen_type = self.type

        initializers.add quote do:
          type_initializers[zen_type_id] = proc(bin: string, ctx: ZenContext,
              id: string, flags: set[ZenFlags], op_ctx: OperationContext) =

            if bin != "":
              debug "creating received object", id
              if not ctx.subscribing and id notin ctx:
                var value = bin.from_flatty(`value_type`, ctx)
                discard Zen.init(value, ctx = ctx, id = id,
                    flags = flags, op_ctx)
              elif not ctx.subscribing:
                debug "restoring received object", id
                var value = bin.from_flatty(`value_type`, ctx)
                let item = `zen_type`(ctx[id])
                item.`value=`(value, op_ctx = op_ctx)
              else:
                if id notin ctx:
                  discard `zen_type`.init(ctx = ctx, id = id,
                      flags = flags, op_ctx)

                let initializer = proc() =
                  debug "deferred restore of received object value", id
                  {.gcsafe.}:
                    let value = bin.from_flatty(`value_type`, ctx)
                  let item = `zen_type`(ctx[id])
                  item.`value=`(value, op_ctx = op_ctx)
                ctx.value_initializers.add(initializer)

            elif id notin ctx:
              discard `zen_type`.init(ctx = ctx, id = id, flags = flags, op_ctx)

      var msg = Message(kind: Create, obj: bin, flags: flags,
           type_id: zen_type_id, object_id: id, source: op_ctx.source)

      when defined(zen_trace):
        msg.trace = get_stack_trace()

      src_ctx.send(sub, msg, op_ctx, flags = self.flags & {SyncAllNoOverwrite})

    if sub.kind != Blank:
      ctx.send_msg(sub)
    if broadcast:
      for sub in ctx.subscribers:
        if sub.ctx_name notin op_ctx.source:
          ctx.send_msg(sub)
    if ?ctx.reactor:
      ctx.reactor.tick
      ctx.dead_connections &= ctx.reactor.dead_connections
      ctx.remote_messages &= ctx.reactor.messages

  self.build_message = proc(self: ref ZenBase, change: BaseChange, id,
      trace: string): Message =

    var msg = Message(object_id: id, type_id: Zen[T, O].tid)
    when defined(zen_trace):
      msg.trace = trace
    assert Added in change.changes or Removed in change.changes or
      Touched in change.changes
    let change = Change[O](change)
    when change.item is Zen:
      msg.change_object_id = change.item.id
    elif change.item is Pair[any, Zen]:
      # TODO: Properly sync ref keys
      {.gcsafe.}:
        msg.obj = change.item.key.to_flatty
      msg.change_object_id = change.item.value.id
    else:
      var item = ""
      block registered:
        when change.item is ref RootObj:
          if ?change.item:
            var registered_type: RegisteredType
            if change.item.lookup_type(registered_type):
              msg.ref_id = registered_type.tid
              item = registered_type.stringify(change.item)
              break registered
            else:
              debug "type not registered", type_name = change.item.base_type

        {.gcsafe.}:
          item = change.item.to_flatty
      msg.obj = item

    msg.kind = if Touched in change.changes:
      Touch
    elif Added in change.changes:
      Assign
    elif Removed in change.changes:
      Unassign
    else:
      raise_assert "Can't build message for changes " & $change.changes
    result = msg

  self.change_receiver = proc(self: ref ZenBase, msg: Message,
      op_ctx: OperationContext) =

    assert self of Zen[T, O]
    let self = Zen[T, O](self)

    if msg.kind == Destroy:
      self.destroy(publish = false)
      return

    when O is Zen:
      let object_id = msg.change_object_id
      assert object_id in self.ctx.objects
      let item = O(self.ctx.objects[object_id])
    elif O is Pair[any, Zen]:
      type K = O.get(0)
      type V = O.get(1)
      if msg.object_id notin self.ctx.objects:
        when defined(zen_trace):
          echo msg.trace
        raise_assert "object not in context " & msg.object_id &
            " " & $Zen[T, O]

      let value = V(self.ctx.objects[msg.change_object_id])
      {.gcsafe.}:
        let item = (key: msg.obj.from_flatty(K, self.ctx), value: value)
    else:
      var item: O
      when item is ref RootObj:
        if msg.obj != "":
          if msg.ref_id > 0:
            var registered_type: RegisteredType
            if lookup_type(msg.ref_id, registered_type):
              item = type(item)(registered_type.parse(self.ctx, msg.obj))
              if not self.ctx.find_ref(item):
                debug "item restored (not found)", item = item.type.name,
                    ref_id = item.ref_id
              else:
                debug "item found (not restored)", item = item.type.name,
                    ref_id = item.ref_id
            else:
              raise_assert &"Type for ref_id {msg.ref_id} not registered"
          else:
            {.gcsafe.}:
              item = msg.obj.from_flatty(O, self.ctx)

      else:
        {.gcsafe.}:
          item = msg.obj.from_flatty(O, self.ctx)

    if msg.kind == Assign:
      self.assign(item, op_ctx = op_ctx)
    elif msg.kind == Unassign:
      self.unassign(item, op_ctx = op_ctx)
    elif msg.kind == Touch:
     self.touch(item, op_ctx = op_ctx)
    else:
      raise_assert "Can't handle message " & $msg.kind

  assert self.ctx == nil
  self.ctx = ctx

  self.publish_create(broadcast = true, op_ctx = op_ctx)
  self
