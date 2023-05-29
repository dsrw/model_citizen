template setup_op_ctx(self: ZenContext) =
  let op_ctx = if ?op_ctx:
    op_ctx
  else:
    OperationContext(source: self.name)
