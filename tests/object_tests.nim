import std / [unittest]
import pkg / [pretty, chronicles]
import model_citizen

proc run* =
  test "generate properties":
    type ZenString = ZenValue[string]
    type Beep = ref object of RootObj
      id*: string
      name: ZenValue[string]

    type Boop = ref object of Beep
      state: ZenString
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

    `name=`(b, "scott")
    check name(b) == "scott"
    check counter == 1

when is_main_module:
  Zen.bootstrap
  run()
