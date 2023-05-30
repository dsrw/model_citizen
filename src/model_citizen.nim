import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
    strformat, atomics, strutils, locks, monotimes, os, importutils,
    macrocache, algorithm, net, intsets]
import std / times except local
import pkg / [threading / channels, pretty, flatty, supersnappy]
import pkg / netty except Message
from pkg / threading / channels {.all.} import ChannelObj
import model_citizen / [typeids, utils, logging]

export macros, flatty, dup, sets

import model_citizen / types / defs {.all.}

import model_citizen / types / [contexts, zens]
import model_citizen / [subscriptions, operations, logging, type_registry]

export zens, contexts, subscriptions, operations
export active_chronicles_stream, active_chronicles_scope,
      log_all_dynamic_properties, flush_record, Record

macro system_init*(_: type Zen): untyped =
  result = new_stmt_list()
  for initializer in initializers:
    result.add initializer

const type_id = CacheCounter"type_id"

proc ctx(): ZenContext = Zen.thread_ctx

func tid*(T: type): int =
  const id = type_id.value
  static:
    inc type_id
  id

log_defaults

proc clear*(self: ZenContext) =
  debug "Clearing ZenContext"
  self.objects.clear


private_access ZenContext

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
  private_access ZenBase

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
  private_access ZenObject
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

private_access ZenBase
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
  private_access ZenObject[T, O]
  private_access ZenBase
  private_access ZenContext

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

  private_access ZenContext
  private_access ZenObject[T, O]
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
