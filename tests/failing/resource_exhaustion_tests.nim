import std/[sequtils]
import pkg/[pretty, unittest2]
import model_citizen

proc run*() =
  test "context with excessive object creation":
    var ctx = ZenContext.init(id = "exhaustion_ctx")
    var objects: seq[ZenValue[string]]

    # Create many objects to test memory/resource limits
    # This might hit internal limits or cause memory issues
    for i in 1 .. 10000:
      let obj = ZenValue[string].init(ctx = ctx, id = "obj_" & $i)
      obj.value = "data_" & $i
      objects.add obj

      # Check if context is still responding
      if i mod 1000 == 0:
        ctx.boop()

    # Context should still be functional
    check ctx.len == 10000
    check objects[0].value == "data_1"
    check objects[9999].value == "data_10000"

  test "excessive tracking callbacks":
    var ctx = ZenContext.init(id = "callback_ctx")
    var obj = ZenValue[int].init(ctx = ctx)

    var total_callbacks = 0

    # Register many callbacks - this might hit internal limits
    for i in 1 .. 1000:
      obj.track proc(changes: auto) {.gcsafe.} =
        total_callbacks += 1

    # Trigger callbacks
    obj.value = 42

    # All callbacks should fire, but system might hit limits
    check total_callbacks == 1000

  test "deep object nesting":
    var ctx = ZenContext.init(id = "nesting_ctx")

    # Create deeply nested structure that might hit stack limits
    var root = ZenTable[
      string, ZenTable[string, ZenTable[string, ZenValue[string]]]
    ].init(ctx = ctx)

    # Create nested structure
    for i in 1 .. 100:
      let key1 = "level1_" & $i
      root[key1] =
        ZenTable[string, ZenTable[string, ZenValue[string]]].init(ctx = ctx)

      for j in 1 .. 10:
        let key2 = "level2_" & $j
        root[key1][key2] = ZenTable[string, ZenValue[string]].init(ctx = ctx)

        for k in 1 .. 5:
          let key3 = "level3_" & $k
          root[key1][key2][key3] = ZenValue[string].init(ctx = ctx)
          root[key1][key2][key3].value = $i & "_" & $j & "_" & $k

    # Should still be accessible
    check root["level1_1"]["level2_1"]["level3_1"].value == "1_1_1"

  test "massive sequence operations":
    var ctx = ZenContext.init(id = "sequence_ctx")
    var large_seq = ZenSeq[int].init(ctx = ctx)

    # Add many items rapidly
    for i in 1 .. 50000:
      large_seq += i

    # Sequence should handle large amounts of data
    check large_seq.len == 50000
    check large_seq[0] == 1
    check large_seq[49999] == 50000

    # Test removing many items
    for i in 1 .. 25000:
      large_seq.del(0) # Remove from front

    check large_seq.len == 25000
    check large_seq[0] == 25001

  test "subscription chain exhaustion":
    # Create a long chain of subscriptions
    var contexts: seq[ZenContext]

    for i in 1 .. 100:
      contexts.add ZenContext.init(id = "chain_" & $i)

    # Chain subscriptions
    for i in 1 ..< contexts.len:
      contexts[i].subscribe(contexts[i - 1])

    # Create object at start of chain
    var obj = ZenValue[string].init(ctx = contexts[0], id = "chain_obj")
    obj.value = "propagate_me"

    # Propagate through all contexts
    for ctx in contexts:
      ctx.boop()

    # Should reach the end of the chain
    let final_obj = ZenValue[string](contexts[^1]["chain_obj"])
    check final_obj.value == "propagate_me"

when is_main_module:
  Zen.bootstrap
  run()
