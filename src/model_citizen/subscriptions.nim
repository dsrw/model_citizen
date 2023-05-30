import std / [importutils, tables, sets, sequtils, algorithm, intsets, locks]
import pkg / threading / channels {.all.}
import pkg / [flatty, supersnappy]
import pkg / netty except Message
import model_citizen / [utils, logging, typeids, type_registry]
import types / defs {.all.}

private_access ZenContext
private_access ZenBase

var flatty_ctx {.threadvar.}: ZenContext

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
  private_access ZenContext
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

proc remaining*(self: Chan): int =
  private_access Chan
  private_access ChannelObj
  let size = self.d[].size
  result = size - self.peek

proc full*(self: Chan): bool =
  self.remaining == 0

proc send_or_buffer(sub: Subscription, msg: sink Message, buffer: bool) =
  if buffer and (sub.chan_buffer.len > 0 or sub.chan.full):
    sub.chan_buffer.add msg
  else:
    sub.chan.send(msg)

proc flush_buffers*(self: ZenContext) =
  for sub in self.subscribers:
    if sub.kind == Local:
      let buffer = sub.chan_buffer
      sub.chan_buffer = @[]
      for msg in buffer:
        sub.send_or_buffer(msg, true)

proc send*(self: ZenContext, sub: Subscription, msg: sink Message,
    op_ctx = OperationContext(), flags = default_flags) =

  log_defaults("model_citizen networking")
  when defined(zen_trace):
    if sub.ctx_name notin self.last_msg_id:
      self.last_msg_id[sub.ctx_name] = 1
    else:
      self.last_msg_id[sub.ctx_name] += 1
    msg.id = self.last_msg_id[sub.ctx_name]
  debug "sending message", msg

  msg.source = op_ctx.source
  if msg.source == "":
    msg.source = self.name

  var msg = msg
  if sub.kind == Local and SyncLocal in flags:
    sub.send_or_buffer(msg, self.buffer)
  elif sub.kind == Local and SyncAllNoOverwrite in flags:
    msg.obj = ""
    sub.send_or_buffer(msg, self.buffer)
  elif sub.kind == Remote and SyncRemote in flags:
    self.reactor.send(sub.connection, msg.to_flatty.compress)
  elif sub.kind == Remote and SyncAllNoOverwrite in flags:
    msg.obj = ""
    self.reactor.send(sub.connection, msg.to_flatty.compress)

proc publish_destroy*[T, O](self: Zen[T, O], op_ctx: OperationContext) =
  private_access ZenContext
  log_defaults("model_citizen publishing")
  debug "publishing destroy", zen_id = self.id
  for sub in self.ctx.subscribers:
    if sub.ctx_name notin op_ctx.source:
      when defined(zen_trace):
        self.ctx.send(sub, Message(kind: Destroy, object_id: self.id,
            trace: get_stack_trace()), op_ctx, self.flags)

      else:
        self.ctx.send(sub, Message(kind: Destroy, object_id: self.id),
            op_ctx, self.flags)

  if ?self.ctx.reactor:
    self.ctx.reactor.tick
    self.ctx.dead_connections &= self.ctx.reactor.dead_connections
    self.ctx.remote_messages &= self.ctx.reactor.messages

proc publish_changes*[T, O](self: Zen[T, O], changes: seq[Change[O]],
    op_ctx: OperationContext) =

  private_access ZenContext
  private_access ZenBase

  log_defaults("model_citizen publishing")
  debug "publish_changes", ctx = self.ctx, op_ctx
  let id = self.id
  for sub in self.ctx.subscribers:
    if sub.ctx_name in op_ctx.source:
      continue
    for change in changes:
      if [Added, Removed, Created, Touched].any_it(it in change.changes):
        if Removed in change.changes and Modified in change.changes:
          # An assign will trigger both an assign and an unassign on the other
          # side. We only want to send a Removed message when an item is
          # removed from a collection.
          debug "skipping changes"
          continue
        assert id in self.ctx.objects
        let obj = self.ctx.objects[id]
        let trace = when defined(zen_trace):
          get_stack_trace()
        else:
          ""
        var msg = obj.build_message(obj, change, id, trace)
        self.ctx.send(sub, msg, op_ctx, self.flags)
    if ?self.ctx.reactor:
      self.ctx.reactor.tick
      self.ctx.dead_connections &= self.ctx.reactor.dead_connections
      self.ctx.remote_messages &= self.ctx.reactor.messages

proc add_subscriber*(self: ZenContext, sub: Subscription, push_all: bool,
    remote_objects: HashSet[string]) =

  debug "adding subscriber", sub
  self.subscribers.add sub
  for id in self.objects.keys.to_seq.reversed:
    if id notin remote_objects or push_all:
      debug "sending object on subscribe", from_ctx = self.name,
          to_ctx = sub.ctx_name, zen_id = id

      let zen = self.objects[id]
      zen.publish_create sub
    else:
      debug "not sending object because remote ctx already has it",
          from_ctx = self.name, to_ctx = sub.ctx_name, zen_id = id
