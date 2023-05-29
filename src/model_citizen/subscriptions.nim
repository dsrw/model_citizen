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

proc flush_buffers(self: ZenContext) =
  for sub in self.subscribers:
    if sub.kind == Local:
      let buffer = sub.chan_buffer
      sub.chan_buffer = @[]
      for msg in buffer:
        sub.send_or_buffer(msg, true)

proc send(self: ZenContext, sub: Subscription, msg: sink Message,
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

proc add_subscriber(self: ZenContext, sub: Subscription, push_all: bool,
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

proc publish_destroy[T, O](self: Zen[T, O], op_ctx: OperationContext) =
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

proc publish_changes[T, O](self: Zen[T, O], changes: seq[Change[O]],
    op_ctx: OperationContext) =

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
