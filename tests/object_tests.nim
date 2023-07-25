import std / [unittest]
import pkg / [pretty, chronicles]
import model_citizen

proc run* =
  test "generate properties":
    type ZenString = ZenValue[string]
    type Beep = ref object of RootObj
      id*: string
      zen_name: ZenValue[string]

    type Boop = ref object of Beep
      zenState: ZenString
      messages*: ZenSeq[string]

    Zen.register(Boop, false)
    var b = Boop().init_zen_fields

    var counter = 0
    b.changes(name):
      if added:
        inc counter
    b.changes(state):
      if added:
        inc counter

    b.name = "scott"
    check counter == 1

when is_main_module:
  Zen.bootstrap
  run()
