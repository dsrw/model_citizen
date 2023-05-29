import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
    strformat, atomics, strutils, locks, monotimes, os, importutils,
    macrocache, algorithm, net, intsets]
import std / times except local
import pkg / [threading / channels, pretty, flatty, netty, supersnappy]
from pkg / threading / channels {.all.} import ChannelObj
import model_citizen / [typeids, utils]

export macros, flatty, dup, sets

const chronicles_enabled {.strdefine.} = "off"

when chronicles_enabled == "on":
  import pkg / chronicles
  export active_chronicles_stream, active_chronicles_scope,
      log_all_dynamic_properties, flush_record, Record

else:
  # Don't include chronicles unless it's specifically enabled.
  # Use of chronicles in a module requires that the calling module also import
  # chronicles, due to https://github.com/nim-lang/Nim/issues/11225.
  # This has been fixed in Nim, so it may be possible to fix in chronicles.
  template trace(msg: string, _: varargs[untyped]) = discard
  template notice(msg: string, _: varargs[untyped]) = discard
  template debug(msg: string, _: varargs[untyped]) = discard
  template info(msg: string, _: varargs[untyped]) = discard
  template warn(msg: string, _: varargs[untyped]) = discard
  template error(msg: string, _: varargs[untyped]) = discard
  template fatal(msg: string, _: varargs[untyped]) = discard
  template log_scope(body: untyped) = discard

  template log_defaults(log_topics = "") = discard

template log_defaults(log_topics = "model_citizen") = discard

proc `-`[T](a, b: seq[T]): seq[T] = a.filter proc(it: T): bool =
  it notin b

template `&`[T](a, b: set[T]): set[T] = a + b

include model_citizen / [types]

var local_type_registry {.threadvar.}: Table[int, RegisteredType]
var processed_types {.threadvar.}: IntSet
var raw_type_registry: Table[int, RegisteredType]
var type_registry = addr raw_type_registry
var type_registry_lock: Lock
type_registry_lock.init_lock

template with_lock(body: untyped) =
  {.gcsafe.}:
    locks.with_lock(type_registry_lock):
      body

include model_citizen / types / [zen_context, operation_context]
include model_citizen / [subscriptions, operations]
include model_citizen / types / [zen]

var flatty_ctx {.threadvar.}: ZenContext

template zen_ignore* {.pragma.}

when chronicles_enabled == "on":
  # Must be explicitly called from generic procs due to
  # https://github.com/status-im/nim-chronicles/issues/121
  template log_defaults(log_topics = "model_citizen") =
    log_scope:
      topics = log_topics
      thread_ctx = Zen.thread_ctx

macro system_init*(_: type Zen): untyped =
  result = new_stmt_list()
  for initializer in initializers:
    result.add initializer

func tid*(T: type): int =
  const id = type_id.value
  static:
    inc type_id
  id

log_defaults

type FlatRef = tuple[tid: int, ref_id: string, item: string]

type ZenFlattyInfo = tuple[object_id: string, tid: int]

proc to_flatty*[T: ref RootObj](s: var string, x: T) =
  when x is ref ZenBase:
    s.to_flatty not ?x
    if ?x:
      s.to_flatty ZenFlattyInfo((x.id, x.type.tid))
  else:
    var registered_type: RegisteredType
    when compiles(x.id):
      if ?x and x.lookup_type(registered_type):
        s.to_flatty true
        let obj: FlatRef = (tid: registered_type.tid, ref_id: x.ref_id,
            item: registered_type.stringify(x))

        flatty.to_flatty(s, obj)
        return
    s.to_flatty false
    s.to_flatty not ?x
    if ?x:
      flatty.to_flatty(s, x)

proc from_flatty*[T: ref RootObj](s: string, i: var int, value: var T) =
  when value is ref ZenBase:
    var is_nil: bool
    s.from_flatty(i, is_nil)
    if not is_nil:
      var info: ZenFlattyInfo
      s.from_flatty(i, info)
      value = value.type()(flatty_ctx.objects[info.object_id])
  else:
    var is_registered: bool
    s.from_flatty(i, is_registered)
    if is_registered:
      var val: FlatRef
      flatty.from_flatty(s, i, val)

      if val.ref_id in flatty_ctx.ref_pool:
        value = value.type()(flatty_ctx.ref_pool[val.ref_id].obj)
      else:
        var registered_type: RegisteredType
        assert lookup_type(val.tid, registered_type)
        value = value.type()(registered_type.parse(flatty_ctx, val.item))
    else:
      var is_nil: bool
      s.from_flatty(i, is_nil)
      if not is_nil:
        value = value.type()()
        value[] = flatty.from_flatty(s, value[].type)

proc to_flatty*(s: var string, x: proc) =
  discard

proc from_flatty*(s: string, i: var int, p: proc) =
  discard

proc to_flatty*(s: var string, p: ptr) =
  discard

proc to_flatty*(s: var string, p: pointer) =
  discard

proc from_flatty*(s: string, i: var int, p: pointer) =
  discard

proc from_flatty*(s: string, i: var int, p: ptr) =
  discard

proc from_flatty*(bin: string, T: type, ctx: ZenContext): T =
  flatty_ctx = ctx
  result = flatty.from_flatty(bin, T)

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

proc clear*(self: ZenContext) =
  debug "Clearing ZenContext"
  self.objects.clear



proc recv*(self: ZenContext,
    messages = int.high, max_duration = self.max_recv_duration, min_duration =
    self.min_recv_duration, blocking = self.blocking_recv,
    poll = true) {.gcsafe.}

proc pause_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
  if zids.len == 0:
    for zid in self.changed_callbacks.keys:
      self.paused_zids.incl(zid)
  else:
    for zid in zids: self.paused_zids.incl(zid)

proc resume_changes*(self: Zen, zids: varargs[ZID]) =
  assert self.valid
  if zids.len == 0:
    self.paused_zids = {}
  else:
    for zid in zids: self.paused_zids.excl(zid)

template pause_impl(self: Zen, zids: untyped, body: untyped) =
  let previous = self.paused_zids
  for zid in zids:
    self.paused_zids.incl(zid)
  try:
    body
  finally:
    self.paused_zids = previous

template pause*(self: Zen, zids: varargs[ZID], body: untyped) =
  mixin valid
  assert self.valid
  pause_impl(self, zids, body)

template pause*(self: Zen, body: untyped) =
  mixin valid
  assert self.valid
  pause_impl(self, self.changed_callbacks.keys, body)

proc destroy*[T, O](self: Zen[T, O], publish = true) =
  log_defaults
  debug "destroying", unit = self.id, stack = get_stack_trace()
  echo \"destroying {self.id} publish {publish} {Zen.thread_ctx.name}"
  # write_stack_trace()
  if self.destroyed:
    echo "Already destroyed: ", self.id
  assert self.valid
  self.untrack_all
  self.destroyed = true
  self.ctx.objects.del self.id
  if publish:
    echo "publishing destroy"
    self.publish_destroy OperationContext(source: self.ctx.name)
  echo "done"

proc process_message(self: ZenContext, msg: Message) =
  log_defaults
  assert self.name notin msg.source
  # when defined(zen_trace):
  #   let src = self.name & "-" & msg.source
  #   if src in self.last_received_id:
  #     if msg.id != self.last_received_id[src] + 1:
  #       raise_assert &"src={src} msg.id={msg.id} " &
  #           &"last={self.last_received_id[src]}. Should be msg.id - 1"
  #   self.last_received_id[src] = msg.id
  #   debug "receiving", msg, topics = "networking"

  var source = msg.source & " " & self.name

  if msg.kind == Create:
    {.gcsafe.}:
      let fn = type_initializers[msg.type_id]
      fn(msg.obj, self, msg.object_id, msg.flags,
          OperationContext(source: source))

  elif msg.kind != Blank:
    if msg.object_id notin self.objects:
      error "missing object", object_id = msg.object_id
      print msg
      when defined(zen_trace):
        echo "Echo:"
        echo msg.trace
        echo "Print:"
        print msg.trace
      raise_assert &"object {msg.object_id} not in context. Kind: {msg.kind}"
      #print self.objects.keys.to_seq, self.objects.values.to_seq
    let obj = self.objects[msg.object_id]
    obj.change_receiver(obj, msg, op_ctx = OperationContext(source: source))

  else:
    raise_assert "Can't recv a blank message"

proc process_value_initializers(self: ZenContext) =
  debug "running deferred initializers", ctx = self.name
  for initializer in self.value_initializers:
    initializer()
  self.value_initializers = @[]

proc unsubscribe*(self: ZenContext, sub: Subscription) =
  if sub.kind == Remote:
    self.reactor.disconnect(sub.connection)
  else:
    # ???
    discard
  self.subscribers.delete self.subscribers.find(sub)
  self.unsubscribed.add sub.ctx_name

proc subscribe*(self: ZenContext, ctx: ZenContext, bidirectional = true) =
  debug "local subscribe", ctx = self.name
  var remote_objects: HashSet[string]
  for id in self.objects.keys:
    remote_objects.incl id
  self.subscribing = true
  ctx.add_subscriber(Subscription(kind: Local, chan: self.chan,
      ctx_name: self.name), push_all = bidirectional, remote_objects)

  self.recv(blocking = false, min_duration = Duration.default)
  self.subscribing = false
  self.process_value_initializers

  if bidirectional:
    ctx.subscribe(self, bidirectional = false)

proc subscribe*(self: ZenContext, address: string, bidirectional = true,
    callback: proc() {.gcsafe.} = nil) =
    # callback param is a hack to allow testing networked contexts on the same
    # thread. Not meant to be used in non-test code

  var address = address
  var port = 9632

  debug "remote subscribe", address
  if not ?self.reactor:
    self.reactor = new_reactor()
  self.subscribing = true
  let parts = address.split(":")
  assert parts.len in [1, 2], "subscription address must be in the format " &
      "`hostname` or `hostname:port`"

  if parts.len == 2:
    address = parts[0]
    port = parts[1].parse_int

  let connection = self.reactor.connect(address, port)
  self.send(Subscription(kind: Remote, ctx_name: "temp",
      connection: connection), Message(kind: Subscribe))

  var ctx_name = ""
  var received_objects: HashSet[string]
  var finished = false
  var remote_objects: HashSet[string]
  while not finished:
    self.reactor.tick
    self.dead_connections &= self.reactor.dead_connections
    for conn in self.dead_connections:
      if connection == conn:
        raise ConnectionError.init(&"Unable to connect to {address}:{port}")

    for msg in self.reactor.messages:
      if msg.data.starts_with("ACK:"):
        if bidirectional:
          let pieces = msg.data.split(":")
          ctx_name = pieces[1]
          for id in pieces[2..^1]:
            remote_objects.incl id

        finished = true
      else:
        self.remote_messages &= msg
    if callback != nil:
      callback()

  self.recv(poll = false)
  self.subscribing = false
  self.process_value_initializers

  if bidirectional:
    let sub = Subscription(kind: Remote, connection: connection,
        ctx_name: ctx_name)

    self.add_subscriber(sub, push_all = false, remote_objects)

  self.recv(blocking = false)

proc close*(self: ZenContext) =
  if ?self.reactor:
    private_access Reactor
    self.reactor.socket.close()
  self.reactor = nil

proc recv*(self: ZenContext,
    messages = int.high, max_duration = self.max_recv_duration, min_duration =
    self.min_recv_duration, blocking = self.blocking_recv,
    poll = true) {.gcsafe.} =

  var msg: Message
  self.unsubscribed = @[]
  var count = 0
  self.free_refs
  let timeout = if not ?max_duration:
    MonoTime.high
  else:
    get_mono_time() + max_duration
  let recv_until = if not ?min_duration:
    MonoTime.low
  else:
    get_mono_time() + min_duration

  self.flush_buffers
  while true:
    if poll:
      while count < messages and self.chan.peek > 0 and
          get_mono_time() < timeout:

        self.chan.recv(msg)
        self.process_message(msg)
        inc count

    if ?self.reactor:
      let messages = if poll:
        self.reactor.tick()
        self.dead_connections &= self.reactor.dead_connections
        self.remote_messages & self.reactor.messages
      else:
        self.remote_messages
      self.remote_messages = @[]

      for conn in self.dead_connections:
        let subs = self.subscribers
        for sub in subs:
          if sub.kind == Remote and sub.connection == conn:
            self.unsubscribe(sub)

      self.dead_connections = @[]

      for raw_msg in messages:
        inc count
        let msg = raw_msg.data.uncompress.from_flatty(Message, self)
        if msg.kind == Subscribe:
          var remote: HashSet[string]
          self.add_subscriber(Subscription(kind: Remote,
              connection: raw_msg.conn, ctx_name: msg.source),
              push_all = true, remote)

          var objects = self.objects.keys.to_seq.join(":")

          self.reactor.send(raw_msg.conn, "ACK:" & self.name & ":" & objects)
          self.reactor.tick
          self.dead_connections &= self.reactor.dead_connections
          self.remote_messages &= self.reactor.messages

        else:
          self.process_message(msg)

    if poll == false or ((count > 0 or not blocking) and get_mono_time() > recv_until):
      break







proc `[]`*[T, O](self: ZenContext, src: Zen[T, O]): Zen[T, O] =
  result = Zen[T, O](self.objects[src.id])

proc `[]`*(self: ZenContext, id: string): ref ZenBase =
  result = self.objects[id]

proc init_zen_fields*[T: object or ref](self: T,
  ctx = ctx()): T {.discardable.} =

  result = self
  for field in fields(self.deref):
    when field is Zen:
      field.init(ctx)

proc init_from*[T: object or ref](_: type T,
  src: T, ctx = ctx()): T {.discardable.} =

  result = T()
  for src, dest in fields(src.deref, result.deref):
    when dest is Zen:
      dest = ctx[src]

template `%`*(body: untyped): untyped =
  Zen.init(body)

proc untrack*[T, O](self: Zen[T, O], zid: ZID) =
  log_defaults
  assert self.valid

  assert zid in self.changed_callbacks

  let callback = self.changed_callbacks[zid]
  if zid notin self.paused_zids:
    callback(@[Change.init(O, {Closed})])
  self.ctx.close_procs.del(zid)
  if int(zid) == 46:
    echo \"!! 1 deleting close proc {zid} {self.id} {self.ctx.name}"
    write_stack_trace()
  debug "removing close proc", zid
  self.changed_callbacks.del(zid)

proc track*[T, O](self: Zen[T, O],
    callback: proc(changes: seq[Change[O]]) {.gcsafe.}): ZID {.discardable.} =

  log_defaults
  assert self.valid
  inc self.ctx.changed_callback_zid
  let zid = self.ctx.changed_callback_zid
  if int(zid) == 46:
    echo \"!! 46 created {self.id} {self.ctx.name}"
  self.changed_callbacks[zid] = callback
  debug "adding close proc", zid
  self.ctx.close_procs[zid] = proc() =
    self.untrack(zid)
  result = zid

proc track*[T, O](self: Zen[T, O],
    callback: proc(changes: seq[Change[O]], zid: ZID) {.gcsafe.}):
    ZID {.discardable.} =

  assert self.valid
  var zid: ZID
  zid = self.track proc(changes: seq[Change[O]]) {.gcsafe.} =
    callback(changes, zid)

  result = zid

proc untrack_on_destroy*(self: ref ZenBase, zid: ZID) =
  if int(zid) == 46:
    echo \"binding 46 {self.id} {Zen.thread_ctx.name}"
  self.bound_zids.incl(zid)

template changes*[T, O](self: Zen[T, O], body) =
  self.track proc(changes: seq[Change[O]], zid {.inject.}: ZID) {.gcsafe.} =
    self.pause(zid):
      for change {.inject.} in changes:
        template added: bool = Added in change.changes
        template added(obj: O): bool = change.item == obj and added()
        template removed: bool = Removed in change.changes
        template removed(obj: O): bool = change.item == obj and removed()
        template modified: bool = Modified in change.changes
        template modified(obj: O): bool = change.item == obj and modified()
        template touched: bool = Touched in change.changes
        template touched(obj: O): bool = change.item == obj and touched()
        template closed: bool = Closed in change.changes

        body



iterator items*[T](self: ZenSet[T] | ZenSeq[T]): T =
  assert self.valid
  for item in self.tracked.items:
    yield item

iterator items*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  assert self.valid
  for pair in self.tracked.pairs:
    yield pair

iterator pairs*[K, V](self: ZenTable[K, V]): Pair[K, V] =
  assert self.valid
  for pair in self.tracked.pairs:
    yield pair
