import model_citizen / [core, types / defs {.all.}]

proc init*(_: type Change,
  T: type, changes: set[ChangeKind], field_name = ""): Change[T] =

  Change[T](changes: changes, type_name: $Change[T], field_name: field_name)

proc init*[T](_: type Change, item: T,
  changes: set[ChangeKind], field_name = ""): Change[T] =

  result = Change[T](item: item, changes: changes,
    type_name: $Change[T], field_name: field_name)

proc init*(_: type OperationContext,
    source: string | Message = "", ctx: ZenContext = nil): OperationContext =

  let new_source = if ?ctx: ctx.name else: "??"
  result = OperationContext()
  when source is Message and defined(zen_trace):
    result.source = \"{source.source} {new_source}"
    result.trace = \"""

Source Message Trace:
{source.trace}

Op Trace:
{get_stack_trace()}

    """
  elif source is Message:
    result.source = \"{source.source} {new_source}"
  else:
    result.source = \"{source} {new_source}"

template setup_op_ctx*(self: ZenContext) =
  let op_ctx = if ?op_ctx:
    op_ctx
  else:
    OperationContext.init(source = self.name)

template privileged*() =
  private_access ZenContext
  private_access ZenBase
  private_access ZenObject
