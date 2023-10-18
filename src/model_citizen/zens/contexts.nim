import std / [net, tables, times, options]
import pkg / chronicles

import model_citizen / [core, types {.all.}, utils / misc,
    zens / validations, components / private / global_state]

import ./ private

export ZenContext

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

proc init*(_: type ZenContext,
    id = "thread-" & $get_thread_id(), listen_address = "",
    blocking_recv = false, chan_size = 100, buffer = false,
    max_recv_duration = Duration.default,
    min_recv_duration = Duration.default): ZenContext =

  privileged
  log_scope:
    topics = "model_citizen"

  debug "ZenContext initialized", id
  result = ZenContext(id: id, blocking_recv: blocking_recv,
      max_recv_duration: max_recv_duration,
      min_recv_duration: min_recv_duration, buffer: buffer)

  result.chan = new_chan[Message](elements = chan_size)
  if ?listen_address:
    var listen_address = listen_address
    let parts = listen_address.split(":")
    assert parts.len in [1, 2], "listen_address must be in the format " &
        "`hostname` or `hostname:port`"

    var port = 9632
    if parts.len == 2:
      listen_address = parts[0]
      port = parts[1].parse_int

    debug "listening"
    result.reactor = new_reactor(listen_address, port)

proc thread_ctx*(t: type Zen): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(id = "thread-" & $get_thread_id() )
  active_ctx

proc thread_ctx*(_: type ZenBase): ZenContext =
  Zen.thread_ctx

proc `thread_ctx=`*(_: type Zen, ctx: ZenContext) =
  active_ctx = ctx

proc `$`*(self: ZenContext): string =
  \"ZenContext {self.id}"

proc `[]`*[T, O](self: ZenContext, src: Zen[T, O]): Zen[T, O] =
  result = Zen[T, O](self.objects[src.id])

proc `[]`*(self: ZenContext, id: string): ref ZenBase =
  result = self.objects[id]

proc clear*(self: ZenContext) =
  debug "Clearing ZenContext"
  self.objects.clear
  self.objects_need_packing = false

proc close*(self: ZenContext) =
  if ?self.reactor:
    private_access Reactor
    self.reactor.socket.close()
  self.reactor = nil