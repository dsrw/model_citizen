const chronicles_enabled* {.strdefine.} = "off"

when chronicles_enabled == "on":
  import pkg/chronicles
  export chronicles

  # Must be explicitly called from generic procs due to
  # https://github.com/status-im/nim-chronicles/issues/121
  template log_defaults*(log_topics = "model_citizen") =
    log_scope:
      topics = log_topics
      thread_ctx = "ZenContext " & active_ctx.id

else:
  # Don't include chronicles unless it's specifically enabled.
  # Use of chronicles in a module requires that the calling module also import
  # chronicles, due to https://github.com/nim-lang/Nim/issues/11225.
  # This has been fixed in Nim, so it may be possible to fix in chronicles.
  template trace*(msg: string, _: varargs[untyped]) =
    discard

  template notice*(msg: string, _: varargs[untyped]) =
    discard

  template debug*(msg: string, _: varargs[untyped]) =
    discard

  template info*(msg: string, _: varargs[untyped]) =
    discard

  template warn*(msg: string, _: varargs[untyped]) =
    discard

  template error*(msg: string, _: varargs[untyped]) =
    discard

  template fatal*(msg: string, _: varargs[untyped]) =
    discard

  template log_scope*(body: untyped) =
    discard

  template log_defaults*(log_topics = "") =
    discard
