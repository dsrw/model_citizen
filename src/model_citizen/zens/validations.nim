import model_citizen/[core, types]

proc valid*[T: ref ZenBase](self: T): bool =
  log_defaults
  result = ?self and not self.destroyed
  if not result:
    let id = if ?self: self.id else: "nil"

    debug "Zen invalid", type_name = $T, id

proc valid*[T: ref ZenBase, V: ref ZenBase](self: T, value: V): bool =
  self.valid and value.valid and self.ctx == value.ctx
