import pkg/unittest2
import model_citizen

proc run*() =
  suite "ZenValue CRDT Integration":
    setup:
      var ctx = ZenContext.init(id = "test_ctx")
    
    teardown:
      ctx.close()
    
    test "ZenValue supports sync_mode parameter":
      # Test that ZenValue.init accepts sync_mode parameter
      var regular = ZenValue[int].init(ctx = ctx, id = "regular")
      var fast_local = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "fast")  
      var wait_sync = ZenValue[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait")
      
      check regular.sync_mode == SyncMode.None
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
      
      # Default sync_mode should be None
      check zen_int.sync_mode == SyncMode.None
      check zen_str.sync_mode == SyncMode.None
      
      # Basic operations
      zen_int.value = 42
      zen_str.value = "test"
      
      check zen_int.value == 42
      check zen_str.value == "test"
    
    test "FastLocal is available as default CRDT mode":
      # Test user's requirement: FastLocal should be available as default
      var crdt_zen = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx)
      check crdt_zen.sync_mode == FastLocal
      
      # Should work with basic operations
      crdt_zen.value = 100
      check crdt_zen.value == 100

when is_main_module:
  Zen.bootstrap
  run()