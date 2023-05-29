type
  ZID* = uint16

  ZenError* = object of CatchableError

  ConnectionError* = object of ZenError

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
    stringify: proc(self: ref RootObj): string {.no_side_effect.}
    parse: proc(ctx: ZenContext, clone_from: string):
        ref RootObj {.no_side_effect.}

  SubscriptionKind = enum Blank, Local, Remote

  Subscription = ref object
    ctx_name: string
    case kind: SubscriptionKind
    of Local:
      chan: Chan[Message]
      chan_buffer: seq[Message]
    of Remote:
      connection: Connection
    else:
      discard

  ZenContext* = ref object
    changed_callback_zid: ZID
    last_id: int
    close_procs: Table[ZID, proc() {.gcsafe.}]
    objects*: OrderedTable[string, ref ZenBase]
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
    buffer: bool
    min_recv_duration: Duration
    max_recv_duration: Duration
    subscribing*: bool
    value_initializers*: seq[proc() {.gcsafe.}]
    dead_connections: seq[Connection]
    unsubscribed*: seq[string]

  ZenBase = object of RootObj
    id*: string
    destroyed*: bool
    link_zid: ZID
    paused_zids: set[ZID]
    bound_zids: set[ZID]
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

proc init*(_: type ZenContext,
    name = "thread-" & $get_thread_id(), listen_address = "",
    blocking_recv = false, chan_size = 100, buffer = false,
    max_recv_duration = Duration.default,
    min_recv_duration = Duration.default): ZenContext =

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

proc `$`*(self: Subscription): string =
  &"{self.kind} subscription for {self.ctx_name}"


const initializers = CacheSeq"initializers"
const type_id = CacheCounter"type_id"
var type_initializers: Table[int, CreateInitializer]
var initialized = false

proc valid*[T: ref ZenBase](self: T): bool =
  log_defaults
  result = ?self and not self.destroyed
  if not result:
    let id = if ?self: self.id else: ""
    debug "Zen invalid", type_name = $T, id = id

proc valid*[T: ref ZenBase, V: ref ZenBase](self: T, value: V): bool =
  self.valid and value.valid and self.ctx == value.ctx

proc init(_: type Change,
  T: type, changes: set[ChangeKind], field_name = ""): Change[T] =

  Change[T](changes: changes, type_name: $Change[T], field_name: field_name)

proc init[T](_: type Change, item: T,
  changes: set[ChangeKind], field_name = ""): Change[T] =

  result = Change[T](item: item, changes: changes,
    type_name: $Change[T], field_name: field_name)

const default_flags* = {TrackChildren, SyncLocal, SyncRemote}
