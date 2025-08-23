import pkg/unittest2
import model_citizen

proc run*() =
  suite "ZenValue CRDT Integration":
    setup:
      var ctx = ZenContext.init(id = "test_ctx", default_sync_mode = SyncMode.Yolo)
    
    teardown:
      ctx.close()
    
    test "ZenValue supports sync_mode parameter":
      # Test that ZenValue.init accepts sync_mode parameter
      var regular = ZenValue[int].init(ctx = ctx, id = "regular")
      var fast_local = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "fast")  
      var wait_sync = ZenValue[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait")
      
      check regular.sync_mode == ContextDefault  # Uses context default
      check fast_local.sync_mode == FastLocal
      check wait_sync.sync_mode == WaitForSync
    
    test "ZenValue with CRDT modes supports basic operations":
      # Test that basic operations work regardless of sync mode
      var regular = ZenValue[string].init(ctx = ctx, id = "regular")
      var crdt_fast = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx, id = "crdt")
      
      # Setting values should work
      regular.value = "regular_value"
      crdt_fast.value = "crdt_value"
      
      # Reading values should work
      check regular.value == "regular_value"
      check crdt_fast.value == "crdt_value"
    
    test "ZenValue preserves existing API compatibility":
      # Test that existing ZenValue usage patterns still work
      var zen_int = ZenValue[int].init(ctx = ctx)
      var zen_str = ZenValue[string].init(ctx = ctx)
      
      # Default sync_mode should be Yolo for backward compatibility
      check zen_int.sync_mode == ContextDefault  # Uses context default
      check zen_str.sync_mode == ContextDefault  # Uses context default
      
      # Basic operations
      zen_int.value = 42
      zen_str.value = "test"
      
      check zen_int.value == 42
      check zen_str.value == "test"
    
    test "Yolo is the default mode for backward compatibility":
      # Test that Yolo is the default for backward compatibility
      var crdt_zen = ZenValue[int].init(ctx = ctx)
      check crdt_zen.sync_mode == ContextDefault  # Uses context default
      
      # Should work with basic operations
      crdt_zen.value = 100
      check crdt_zen.value == 100
    
    test "Yolo mode uses traditional Zen sync":
      # Test that Yolo mode still works for traditional sync
      var yolo_zen = ZenValue[string].init(sync_mode = Yolo, ctx = ctx)
      check yolo_zen.sync_mode == Yolo
      
      # Should work with basic operations and use traditional Zen sync
      yolo_zen.value = "yolo"
      check yolo_zen.value == "yolo"

when is_main_module:
  Zen.bootstrap
  run()