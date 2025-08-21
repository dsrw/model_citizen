import std/[os, locks]
import pkg/[pretty, unittest2]
import model_citizen

var test_lock: Lock
var modification_count: int

proc concurrent_modifier(ctx: ZenContext) {.thread.} =
  Zen.thread_ctx = ctx

  # Try to get the shared object
  if "shared_obj" in ctx:
    let shared_obj = ZenValue[int](ctx["shared_obj"])

    # Rapid modifications
    for i in 1 .. 100:
      test_lock.acquire()
      shared_obj.value = shared_obj.value + 1
      inc modification_count
      test_lock.release()
      sleep(1) # Small delay

proc run*() =
  test_lock.init_lock()

  test "concurrent modification during iteration":
    var ctx1 = ZenContext.init(id = "ctx1")
    var ctx2 = ZenContext.init(id = "ctx2")

    ctx2.subscribe(ctx1)

    var shared_obj = ZenValue[int].init(ctx = ctx1, id = "shared_obj")
    shared_obj.value = 0

    ctx2.boop()

    # Start concurrent modification
    var modifier_thread: Thread[ZenContext]
    modifier_thread.create_thread(concurrent_modifier, ctx2)

    # Meanwhile, try to iterate/read the object
    var read_count = 0
    for i in 1 .. 50:
      test_lock.acquire()
      let current_value = shared_obj.value
      inc read_count
      test_lock.release()
      sleep(2)

    modifier_thread.join_thread()

    # This test might reveal race conditions
    check read_count == 50
    check modification_count > 0

  test "concurrent tracking callback registration":
    var ctx = ZenContext.init(id = "test_ctx")
    var shared_seq = ZenSeq[string].init(ctx = ctx)

    var callback_count = 0

    # Register many callbacks concurrently (simulated)
    for i in 1 .. 10:
      shared_seq.track proc(changes: auto) {.gcsafe.} =
        test_lock.acquire()
        inc callback_count
        test_lock.release()

    # Trigger change
    shared_seq += "test"

    # All callbacks should fire, but there might be race conditions
    check callback_count == 10

  test "concurrent subscription and modification":
    var ctx1 = ZenContext.init(id = "ctx1")
    var obj = ZenValue[string].init(ctx = ctx1, id = "racing_obj")

    # Modify object while subscription is happening
    obj.value = "initial"

    var ctx2 = ZenContext.init(id = "ctx2")

    # This could expose race conditions during subscription
    obj.value = "during_subscription"
    ctx2.subscribe(ctx1)
    obj.value = "after_subscription"

    ctx2.boop()

    let remote_obj = ZenValue[string](ctx2["racing_obj"])

    # The final value should be consistent, but timing might cause issues
    check remote_obj.value == "after_subscription"

when is_main_module:
  Zen.bootstrap
  run()
