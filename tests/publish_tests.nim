import std / [tables, sugar, unittest]
import pkg / [flatty, chronicles, print]
import model_citizen
from std / times import init_duration

proc run* =
  type
    Unit = ref object of RootObj
      id: string

    Build = ref object of Unit
      build_stuff: string

    Bot = ref object of Unit
      bot_stuff: string

  Zen.register_type(Build)
  Zen.register_type(Bot)

  test "object publish inheritance":
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")
      build = Build(id: "some_build", build_stuff: "asdf")
      bot = Bot(id: "some_bot", bot_stuff: "wasd")
      units1 = ZenSeq[Unit].init(id = "units", ctx = ctx1)
      units2 = ZenSeq[Unit].init(id = "units", ctx = ctx2)

    ctx2.subscribe(ctx1)

    units1 += build
    units1 += bot

    ctx2.recv

    check units1.len == 2
    check units1[0] of Build
    check units1[1] of Bot

    check units2.len == 2
    check units2[0] of Build
    check units2[1] of Bot

  test "object mass assign inheritance":
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")
      build = Build(id: "some_build", build_stuff: "asdf")
      bot = Bot(id: "some_bot", bot_stuff: "wasd")
      units1 = ZenSeq[Unit].init(id = "units", ctx = ctx1)
      units2 = ZenSeq[Unit].init(id = "units", ctx = ctx2)

    ctx2.subscribe(ctx1)

    var units: seq[Unit]
    units.add build
    units.add bot

    units1.value = units

    ctx2.recv

    check units1.len == 2
    check units1[0] of Build
    check units1[1] of Bot

    check units2.len == 2
    check units2[0] of Build
    check units2[1] of Bot

  test "object publish on subscribe inheritance":
    var
      ctx1 = ZenContext.init(name = "ctx1")
      ctx2 = ZenContext.init(name = "ctx2")
      build = Build(id: "some_build", build_stuff: "asdf")
      bot = Bot(id: "some_bot", bot_stuff: "wasd")
      units1 = ZenSeq[Unit].init(id = "units", ctx = ctx1)
      units2 = ZenSeq[Unit].init(id = "units", ctx = ctx2)

    units1 += build
    units1 += bot

    ctx2.subscribe(ctx1)

    check units1.len == 2
    check units1[0] of Build
    check units1[1] of Bot

    check units2.len == 2
    check units2[0] of Build
    check units2[1] of Bot

when is_main_module:
  Zen.system_init
  run()
