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

    type Bloop = ref object of Beep
      age: ZenValue[int]

    Zen.register(Boop, false)
    Zen.register(Bloop, false)
    var boop = Boop().init_zen_fields
    var bloop = Bloop().init_zen_fields

    var counter = 0

    boop.changes(name):
      if added:
        inc counter

    boop.changes(state):
      if added:
        inc counter

    bloop.changes(name):
      if added:
        inc counter

    bloop.changes(age):
      if added:
        inc counter

    `name=`(boop, "scott")
    check name(boop) == "scott"
    `age=`(bloop, 99)
    check age(bloop) == 99

    check counter == 2

    var beep = Beep(boop)
    `name=`(beep, "claire")

    beep = Beep(bloop)
    `name=`(beep, "marie")

    check counter == 4

    beep.changes(name):
      if added:
        inc counter

    `name=`(beep, "jeff")

    check counter == 6

when is_main_module:
  Zen.bootstrap
  run()
