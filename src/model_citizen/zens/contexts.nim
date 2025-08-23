import std/[tables, times, options, sugar, math]
import pkg/threading/channels {.all.}

import
  model_citizen/[
    core,
    types {.all.},
    utils/misc,
    zens/validations,
    components/private/global_state,
  ]

import ./private

export ZenContext

proc init_metrics*(_: type ZenContext, labels: varargs[string]) =
  for label in labels:
    pressure_gauge.set(0.0, label_values = [label])
    object_pool_gauge.set(0.0, label_values = [label])
    ref_pool_gauge.set(0.0, label_values = [label])
    buffer_gauge.set(0.0, label_values = [label])
    chan_remaining_gauge.set(0.0, label_values = [label])
    sent_message_counter.inc(0, label_values = [label])
    received_message_counter.inc(0, label_values = [label])
    dropped_message_counter.inc(0, label_values = [label])
    boops_counter.inc(0, label_values = [label])

proc pack_objects*(self: ZenContext) =
  if self.objects_need_packing:
    var table: OrderedTable[string, ref ZenBase]
    for key, value in self.objects:
      if ?value:
        table[key] = value
    self.objects = table
    self.objects_need_packing = false

proc contains*(self: ZenContext, id: string): bool =
  id in self.objects and self.objects[id] != nil

proc contains*(self: ZenContext, zen: ref ZenBase): bool =
  assert zen.valid
  zen.id in self

proc len*(self: ZenContext): int =
  self.pack_objects
  self.objects.len

proc init*(
    _: type ZenContext,
    id = "thread-" & $get_thread_id(),
    listen_address = "",
    blocking_recv = false,
    chan_size = 100,
    buffer = false,
    max_recv_duration = Duration.default,
    min_recv_duration = Duration.default,
    label = "default",
    default_sync_mode = SyncMode.FastLocal,
): ZenContext =
  privileged
  log_scope:
    topics = "model_citizen"

  debug "ZenContext initialized", id

  result = ZenContext(
    id: id,
    blocking_recv: blocking_recv,
    max_recv_duration: max_recv_duration,
    min_recv_duration: min_recv_duration,
    buffer: buffer,
    metrics_label: label,
    default_sync_mode: default_sync_mode,
  )

  result.chan = new_chan[Message](elements = chan_size)
  if ?listen_address:
    var listen_address = listen_address
    let parts = listen_address.split(":")
    do_assert parts.len in [1, 2],
      "listen_address must be in the format " & "`hostname` or `hostname:port`"

    var port = 9632
    if parts.len == 2:
      listen_address = parts[0]
      port = parts[1].parse_int

    debug "listening"
    result.reactor = new_reactor(listen_address, port)

proc thread_ctx*(t: type Zen): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(id = "thread-" & $get_thread_id(), default_sync_mode = SyncMode.Yolo)
  active_ctx

proc thread_ctx*(_: type ZenBase): ZenContext =
  Zen.thread_ctx

proc `thread_ctx=`*(_: type Zen, ctx: ZenContext) =
  active_ctx = ctx

proc `$`*(self: ZenContext): string =
  \"ZenContext {self.id}"

proc effective_sync_mode*[T, O](zen: Zen[T, O]): SyncMode =
  ## Resolve the effective sync mode, using context default if needed
  if zen.sync_mode == ContextDefault:
    zen.ctx.default_sync_mode
  else:
    zen.sync_mode

proc `[]`*[T, O](self: ZenContext, src: Zen[T, O]): Zen[T, O] =
  result = Zen[T, O](self.objects[src.id])

proc `[]`*(self: ZenContext, id: string): ref ZenBase =
  result = self.objects[id]

proc len*(self: Chan): int =
  private_access Chan
  private_access ChannelObj
  result = self.d[].slots

proc remaining*(self: Chan): int =
  result = self.len - self.peek

proc full*(self: Chan): bool =
  self.remaining == 0

proc pressure*(self: ZenContext): float =
  privileged

  let values = collect:
    for sub in self.subscribers:
      if sub.kind == Local:
        if sub.chan_buffer.len > 0:
          return 1.0
        (sub.chan.len - sub.chan.remaining).float / sub.chan.len.float

  result = values.sum / float values.len

proc boop_reactor*(self: ZenContext) =
  privileged
  if ?self.reactor:
    self.reactor.tick
    self.dead_connections &= self.reactor.dead_connections
    self.remote_messages &= self.reactor.messages

proc clear*(self: ZenContext) =
  debug "Clearing ZenContext"
  self.objects.clear
  self.objects_need_packing = false
