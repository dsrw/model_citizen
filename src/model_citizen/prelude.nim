import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
    strformat, atomics, strutils, locks, monotimes, os, importutils,
    macrocache, algorithm, net, intsets]
import std / times except local
import pkg / [threading / channels, print, flatty, netty, supersnappy]
from pkg / threading / channels {.all.} import ChannelObj
import typeids, utils

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
  # This has been fixed in Nim, so it's likely possible to fix in chronicles
  # with `bind`, but this hasn't been done.
  template trace(msg: string, _: varargs[untyped]) = discard
  template notice(msg: string, _: varargs[untyped]) = discard
  template debug(msg: string, _: varargs[untyped]) = discard
  template info(msg: string, _: varargs[untyped]) = discard
  template warn(msg: string, _: varargs[untyped]) = discard
  template error(msg: string, _: varargs[untyped]) = discard
  template fatal(msg: string, _: varargs[untyped]) = discard
  template log_scope(body: untyped) = discard

  template log_defaults(log_topics = "") = discard

type
  ZID* = uint16

  ZenFlags* = enum
    TrackChildren, SyncLocal, SyncRemote, SyncAllNoOverwrite

  ChangeKind* = enum
    Created, Added, Removed, Modified, Touched, Closed

  MessageKind = enum
    Blank, Create, Destroy, Assign, Unassign, Touch, Subscribe

  BaseChange* = ref object of RootObj
    changes*: set[ChangeKind]
    field_name*: string
    triggered_by*: seq[BaseChange]
    triggered_by_type*: string
    type_name*: string

  OperationContext = object
    source: string

  Message = object
    kind: MessageKind
    object_id: string
    change_object_id: string
    type_id: int
    ref_id: int
    obj: string
    source: string
    flags: set[ZenFlags]
    when defined(zen_trace):
      trace: string
      id: int
      debug: string

  CreateInitializer = proc(bin: string, ctx: ZenContext, id: string,
      flags: set[ZenFlags], op_ctx: OperationContext)

  Change*[O] = ref object of BaseChange
    item*: O

  Pair*[K, V] = tuple[key: K, value: V]

  CountedRef = object
    obj: ref RootObj
    count: int

  RegisteredType = object
    tid: int
    stringify: proc(self: ref RootObj): string {.noSideEffect.}
    parse: proc(ctx: ZenContext, clone_from: string):
        ref RootObj {.no_side_effect.}

  SubscriptionKind = enum Blank, Local, Remote

  Subscription = ref object
    ctx_name: string
    case kind: SubscriptionKind
    of Local:
      chan: Chan[Message]
    of Remote:
      connection: Connection
    else:
      discard

  ZenContext* = ref object
    flags: set[ZenFlags]
    chan_size: int
    changed_callback_zid: ZID
    last_id: int
    close_procs: Table[ZID, proc() {.gcsafe.}]
    objects: OrderedTable[string, ref ZenBase]
    ref_pool: Table[string, CountedRef]
    subscribers: seq[Subscription]
    name*: string
    chan: Chan[Message]
    freeable_refs: Table[string, MonoTime]
    last_msg_id: Table[string, int]
    last_received_id: Table[string, int]
    reactor*: Reactor
    remote_messages: seq[netty.Message]
    blocking_recv: bool
    min_recv_duration: Duration
    max_recv_duration: Duration
    subscribing*: bool
    value_initializers*: seq[proc() {.gcsafe.}]

  ZenBase = object of RootObj
    id: string
    destroyed: bool
    link_zid: ZID
    paused_zids: set[ZID]
    flags: set[ZenFlags]
    build_message: proc(self: ref ZenBase, change: BaseChange, id: string,
        trace: string): Message {.gcsafe.}

    publish_create: proc(sub = Subscription(), broadcast = false,
        op_ctx = OperationContext()) {.gcsafe.}

    change_receiver: proc(self: ref ZenBase, msg: Message,
        op_ctx: OperationContext) {.gcsafe.}

    ctx*: ZenContext

  ChangeCallback[O] = proc(changes: seq[Change[O]]) {.gcsafe.}

  ZenObject[T, O] = object of ZenBase
    changed_callbacks: OrderedTable[ZID, ChangeCallback[O]]
    tracked: T

  Zen*[T, O] = ref object of ZenObject[T, O]

  ZenTable*[K, V] = Zen[Table[K, V], Pair[K, V]]
  ZenSeq*[T] = Zen[seq[T], T]
  ZenSet*[T] = Zen[set[T], T]
  ZenValue*[T] = Zen[T, T]

var local_type_registry {.threadvar.}: Table[int, RegisteredType]
var processed_types {.threadvar.}: IntSet
var raw_type_registry: Table[int, RegisteredType]
var type_registry = addr raw_type_registry
var type_registry_lock: Lock
type_registry_lock.init_lock

var active_ctx {.threadvar.}: ZenContext
var flatty_ctx {.threadvar.}: ZenContext

const port = 9632
const default_flags* = {TrackChildren, SyncLocal, SyncRemote}

template zen_ignore* {.pragma.}

template with_lock(body: untyped) =
  {.gcsafe.}:
    locks.with_lock(type_registry_lock):
      body

const initializers = CacheSeq"initializers"
const type_id = CacheCounter"type_id"
var type_initializers: Table[int, CreateInitializer]
var initialized = false

proc ctx(): ZenContext

proc thread_ctx*(_: type Zen): ZenContext = ctx()

proc `thread_ctx=`*(_: type Zen, ctx: ZenContext) =
  active_ctx = ctx

proc `$`*(self: Subscription): string =
  &"{self.kind} subscription for {self.ctx_name}"

proc `$`*(self: ZenContext): string =
  &"ZenContext {self.name}"

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

proc init*(_: type ZenContext,
    name = "thread-" & $get_thread_id(), chan_size = 100,
    listen = false, blocking_recv = false, max_recv_duration =
    Duration.default, min_recv_duration = Duration.default): ZenContext =

  log_scope:
    topics = "model_citizen"

  debug "ZenContext initialized", name = name
  result = ZenContext(name: name, chan_size: chan_size,
      blocking_recv: blocking_recv, max_recv_duration: max_recv_duration,
      min_recv_duration: min_recv_duration)

  result.chan = new_chan[Message](elements = chan_size)
  if listen:
    debug "listening"
    result.reactor = new_reactor("127.0.0.1", port)

proc ctx(): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(name = "thread-" & $get_thread_id() )
  active_ctx

func tid*(T: type): int =
  const id = type_id.value
  static:
    inc type_id
  id

log_defaults
