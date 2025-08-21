import pkg/unittest2
import model_citizen
import ./object_tests_types

proc run*() =
  test "generate properties":
    var boop = Boop().init_zen_fields
    var bloop = Bloop().init_zen_fields

    var counter = 0

    boop.name_value.changes:
      if added:
        inc counter

    boop.state_value.changes:
      if added:
        inc counter

    bloop.name_value.changes:
      if added:
        inc counter

    bloop.age_value.changes:
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

    beep.name_value.changes:
      if added:
        inc counter

    `name=`(beep, "cal")

    check counter == 6

when is_main_module:
  Zen.bootstrap
  run()
