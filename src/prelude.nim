import std / [tables, sequtils, sugar, macros, typetraits, sets, isolation,
  strformat, atomics, strutils, locks, monotimes, os, importutils]
import std / times except local
import pkg / [threading / channels, print]
import typeids
from pkg / threading / channels {.all.} import ChannelObj
const chronicles_enabled {.strdefine.} = "off"

when chronicles_enabled == "on":
  import pkg / chronicles
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

  template log_defaults = discard

type
  ZID* = uint16

  ChangeKind* = enum
    Created, Added, Removed, Modified, Touched, Closed

  MessageKind = enum
    Blank, Create, Destroy, Assign, Unassign, Touch

  BaseChange* = ref object of RootObj
    changes*: set[ChangeKind]
    field_name*: string
    triggered_by*: seq[BaseChange]
    triggered_by_type*: string
    type_name*: string

  Wrapper[T] = ref object of RootObj
    item: T
    object_id: string

  Message = object
    kind: MessageKind
    object_id: string
    obj: ref RootObj
    when defined(zen_trace):
      trace: string
      id: int
      src: string

  Change*[O] = ref object of BaseChange
    item*: O

  Pair*[K, V] = tuple[key: K, value: V]

  CountedRef = object
    obj: ref RootObj
    count: int

  RegisteredType = object
    clone: proc(self: ref RootObj): ref RootObj {.noSideEffect.}
    restore: proc(self: ref RootObj, ctx: ZenContext,
        clone_from: ref RootObj = nil): ref RootObj {.no_side_effect.}

  Subscription = object
    chan: Chan[Message]
    ctx_name: string

  ZenContext* = ref object
    chan_size: int
    changed_callback_zid: ZID
    last_id: int
    close_procs: Table[ZID, proc() {.gcsafe.}]
    objects: Table[string, ref ZenBase]
    ref_pool: Table[string, CountedRef]
    subscribers: seq[Subscription]
    name*: string
    chan: Chan[Message]
    freeable_refs: Table[string, MonoTime]
    last_msg_id: Table[string, int]
    last_received_id: Table[string, int]

  ZenBase = object of RootObj
    id: string
    destroyed: bool
    link_zid: ZID
    paused_zids: set[ZID]
    track_children: bool
    build_message: proc(self: ref ZenBase, change: BaseChange): Message {.gcsafe.}
    publish_create: proc(sub = Subscription.default, broadcast = false) {.gcsafe.}
    change_receiver: proc(self: ref ZenBase, msg: Message, publish: bool) {.gcsafe.}
    ctx*: ZenContext

  ZenObject[T, O] = object of ZenBase
    tracked: T
    changed_callbacks:
      OrderedTable[ZID, proc(changes: seq[Change[O]]) {.gcsafe.}]

  Zen*[T, O] = ref object of ZenObject[T, O]

  ZenTable*[K, V] = Zen[Table[K, V], Pair[K, V]]
  ZenSeq*[T] = Zen[seq[T], T]
  ZenSet*[T] = Zen[set[T], T]
  ZenValue*[T] = Zen[T, T]

var local_type_registry {.threadvar.}: Table[int, RegisteredType]
var raw_type_registry: Table[int, RegisteredType]
var type_registry = addr raw_type_registry
var type_registry_lock: Lock
type_registry_lock.init_lock

var active_ctx {.threadvar.}: ZenContext

template local* {.pragma.}

template with_lock(body: untyped) =
  {.cast(gcsafe).}:
    locks.with_lock(type_registry_lock):
      body

proc init*(_: type ZenContext,
  name = "thread-" & $get_thread_id(), chan_size = 100 ): ZenContext =

  result = ZenContext(name: name, chan_size: chan_size)
  result.chan = new_chan[Message](elements = chan_size)

proc ctx(): ZenContext =
  if active_ctx == nil:
    active_ctx = ZenContext.init(name = "thread-" & $get_thread_id() )
  active_ctx

proc thread_ctx*(_: type Zen): ZenContext = ctx()

proc `thread_ctx=`*(_: type Zen, ctx: ZenContext) =
  active_ctx = ctx

proc is_nil(self: not ref): bool = false

when chronicles_enabled == "on":
  # Must be explicitly called from generic procs due to
  # https://github.com/status-im/nim-chronicles/issues/121
  template log_defaults =
    log_scope:
      topics = "model_citizen"
      thread_ctx = Zen.thread_ctx

  # formatters
  format_it(ZenContext): $(it.name)

log_defaults

var last_id: Atomic[int]
last_id.store(0)
