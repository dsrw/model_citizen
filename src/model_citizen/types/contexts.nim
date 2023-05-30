import std / [times, importutils]
import pkg / threading / channels
import pkg / netty except Message
import defs {.all.}
import model_citizen / [logging, utils]
export ZenContext

private_access ZenContext

var active_ctx {.threadvar.}: ZenContext

proc init*(_: type ZenContext,
    name = "thread-" & $get_thread_id(), listen_address = "",
    blocking_recv = false, chan_size = 100, buffer = false,
    max_recv_duration = Duration.default,
    min_recv_duration = Duration.default): ZenContext =

  private_access ZenContext
  log_scope:
    topics = "model_citizen"
  debug "ZenContext initialized", name = name
  result = ZenContext(name: name, blocking_recv: blocking_recv,
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



proc thread_ctx*(_: type Zen): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(name = "thread-" & $get_thread_id() )
  active_ctx

proc thread_ctx*(_: type ZenBase): ZenContext =
  Zen.thread_ctx

# proc zen_thread_ctx*(): ZenContext =
#   Zen.thread_ctx

proc `thread_ctx=`*(_: type Zen, ctx: ZenContext) =
  active_ctx = ctx

proc `thread_ctx=`*(_: type ZenBase, ctx: ZenContext) =
  Zen.thread_ctx = ctx

proc `$`*(self: ZenContext): string =
  &"ZenContext {self.name}"

proc contains*(self: ZenContext, zen: ref ZenBase): bool =
  assert zen.valid
  zen.id in self.objects

proc contains*(self: ZenContext, id: string): bool =
  id in self.objects

proc len*(self: ZenContext): int =
  self.objects.len
