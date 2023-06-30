import std / [tables, sugar, unittest]
import pkg / [flatty, chronicles, pretty]
import model_citizen
from std / times import init_duration

const recv_duration = init_duration(milliseconds = 10)

proc run* =
  test "4 way sync":
    var
      ctx1 = ZenContext.init(id = "ctx1")
      ctx2 = ZenContext.init(id = "ctx2", listen_address = "127.0.0.1",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx3 = ZenContext.init(id = "ctx3",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx4 = ZenContext.init(id = "ctx4")

    ctx2.subscribe(ctx1)
    ctx3.subscribe(ctx4)
    ctx3.subscribe "127.0.0.1", callback = proc() =
      ctx2.recv(blocking = false)

    var
      a = ZenValue[string].init(id = "test1", ctx = ctx1)
      b = ZenValue[string].init(id = "test1", ctx = ctx2)
      c = ZenValue[string].init(id = "test1", ctx = ctx3)
      d = ZenValue[string].init(id = "test1", ctx = ctx4)

    ctx1.recv
    ctx2.recv

    a.value = "set"
    ctx1.recv
    ctx2.recv
    ctx3.recv
    ctx4.recv
    check d.value == "set"

    ctx2.close

  test "trigger changes on subscribe":
    var
      count = 0
      ctx1 = ZenContext.init(id = "ctx1")
      ctx2 = ZenContext.init(id = "ctx2", listen_address = "127.0.0.1",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx3 = ZenContext.init(id = "ctx3",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx4 = ZenContext.init(id = "ctx4")

    var
      a = Zen.init(@["a1", "a2"], id = "test2", ctx = ctx1)
      b = Zen.init(@["b1", "b2"], id = "test2", ctx = ctx2)
      c = Zen.init(@["c1", "c2"], id = "test2", ctx = ctx3)
      d = Zen.init(@["d1", "d2"], id = "test2", ctx = ctx4)

    d.changes:
      if added:
        inc count

    ctx2.subscribe(ctx1)
    ctx3.subscribe(ctx4)

    ctx1.recv

    check a.value == @["a1", "a2"]
    check b.value == @["a1", "a2"]

    ctx4.recv
    ctx3.subscribe "127.0.0.1", callback = proc() =
      ctx2.recv(blocking = false)

    ctx4.recv

    check count == 2
    check a.len == 2

    check a.value == @["a1", "a2"]
    check b.value == @["a1", "a2"]
    check c.value == @["a1", "a2"]
    check d.value == @["a1", "a2"]

    ctx2.close

  test "nested collection":
    type
      Unit = object
        code: ZenValue[string]

    var
      count = 0
      ctx1 = ZenContext.init(id = "ctx1")
      ctx2 = ZenContext.init(id = "ctx2", listen_address = "127.0.0.1",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx3 = ZenContext.init(id = "ctx3",
          min_recv_duration = recv_duration, blocking_recv = true)
      ctx4 = ZenContext.init(id = "ctx4")

    var
      a = Zen.init(@["a1", "a2"], id = "test2", ctx = ctx1)
      b = Zen.init(@["b1", "b2"], id = "test2", ctx = ctx2)
      c = Zen.init(@["c1", "c2"], id = "test2", ctx = ctx3)
      d = Zen.init(@["d1", "d2"], id = "test2", ctx = ctx4)

    d.changes:
      if added:
        inc count

    ctx2.subscribe(ctx1)
    ctx3.subscribe(ctx4)

    ctx1.recv

    check a.value == @["a1", "a2"]
    check b.value == @["a1", "a2"]

    ctx4.recv
    ctx3.subscribe "127.0.0.1", callback = proc() =
      ctx2.recv(blocking = false)

    ctx4.recv

    check count == 2
    check a.len == 2

    check a.value == @["a1", "a2"]
    check b.value == @["a1", "a2"]
    check c.value == @["a1", "a2"]
    check d.value == @["a1", "a2"]

    ctx2.close

when is_main_module:
  Zen.bootstrap
  run()
