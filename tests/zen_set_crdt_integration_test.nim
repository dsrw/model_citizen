import pkg/unittest2
import model_citizen

proc run*() =
  suite "ZenSet CRDT Integration":
    setup:
      var ctx = ZenContext.init(id = "test_ctx")
    
    teardown:
      ctx.close()
    
    test "ZenSet supports sync_mode parameter":
      # Test that ZenSet.init accepts sync_mode parameter
      var regular = ZenSet[int].init(ctx = ctx, id = "regular")
      var fast_local = ZenSet[int].init(sync_mode = FastLocal, ctx = ctx, id = "fast")  
      var wait_sync = ZenSet[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait")
      
      check regular.sync_mode == SyncMode.FastLocal
      check fast_local.sync_mode == FastLocal
      check wait_sync.sync_mode == WaitForSync
    
    test "ZenSet with CRDT modes supports basic operations":
      # Test that basic operations work regardless of sync mode
      var regular = ZenSet[string].init(ctx = ctx, id = "regular")
      var crdt_fast = ZenSet[string].init(sync_mode = FastLocal, ctx = ctx, id = "crdt")
      
      # Adding values should work
      regular += "regular_value"
      crdt_fast += "crdt_value"
      
      # Contains should work
      check "regular_value" in regular.tracked
      check "crdt_value" in crdt_fast.tracked
    
    test "ZenSet preserves existing API compatibility":
      # Test that existing ZenSet usage patterns still work
      var zen_set = ZenSet[int].init(ctx = ctx)
      
      # Default sync_mode should be FastLocal
      check zen_set.sync_mode == SyncMode.FastLocal
      
      # Basic operations
      zen_set += 42
      zen_set += 100
      
      check 42 in zen_set.tracked
      check 100 in zen_set.tracked
      check zen_set.tracked.len == 2
    
    test "FastLocal is now the default mode":
      # Test that FastLocal is now the default
      var crdt_zen = ZenSet[int].init(ctx = ctx)
      check crdt_zen.sync_mode == FastLocal
      
      # Should work with basic operations
      crdt_zen += 100
      check 100 in crdt_zen.tracked
    
    test "Yolo mode uses traditional Zen sync":
      # Test that Yolo mode still works for traditional sync
      var yolo_zen = ZenSet[string].init(sync_mode = Yolo, ctx = ctx)
      check yolo_zen.sync_mode == Yolo
      
      # Should work with basic operations and use traditional Zen sync
      yolo_zen += "yolo"
      check "yolo" in yolo_zen.tracked
    
    test "ZenSet += operator delegates to CRDT":
      # Test that += operations delegate to CRDT when sync_mode != Yolo
      var fast_set = ZenSet[int].init(sync_mode = FastLocal, ctx = ctx)
      var wait_set = ZenSet[int].init(sync_mode = WaitForSync, ctx = ctx)
      
      # Add items using += operator
      fast_set += 1
      fast_set += 2
      wait_set += 10
      wait_set += 20
      
      # Verify items are present (through regular ZenSet interface)
      check 1 in fast_set.tracked
      check 2 in fast_set.tracked
      check 10 in wait_set.tracked
      check 20 in wait_set.tracked
    
    test "ZenSet -= operator delegates to CRDT":
      # Test that -= operations delegate to CRDT when sync_mode != Yolo
      var fast_set = ZenSet[int].init(sync_mode = FastLocal, ctx = ctx)
      
      # Add items first
      fast_set += 1
      fast_set += 2
      fast_set += 3
      
      # Remove one item using -= operator
      fast_set -= 2
      
      # Verify correct items remain
      check 1 in fast_set.tracked
      check 2 notin fast_set.tracked
      check 3 in fast_set.tracked
      check fast_set.tracked.len == 2
    
    test "ZenSet set-based operations work with CRDT":
      # Test set-based += and -= operations
      var crdt_set = ZenSet[int].init(sync_mode = FastLocal, ctx = ctx)
      
      # Add multiple items using set
      crdt_set += {1, 2, 3}
      
      check 1 in crdt_set.tracked
      check 2 in crdt_set.tracked  
      check 3 in crdt_set.tracked
      check crdt_set.tracked.len == 3
      
      # Remove multiple items using set
      crdt_set -= {1, 3}
      
      check 1 notin crdt_set.tracked
      check 2 in crdt_set.tracked
      check 3 notin crdt_set.tracked
      check crdt_set.tracked.len == 1
    
    test "Direct CrdtZenSet operations work":
      # Test direct CrdtZenSet usage
      var crdt_set = CrdtZenSet[string].init(ctx, mode = FastLocal)
      
      # Basic operations
      crdt_set += "test1"
      crdt_set += "test2"
      
      check crdt_set.contains("test1")
      check crdt_set.contains("test2")
      check crdt_set.len == 2
      
      # Remove operation
      crdt_set -= "test1"
      check not crdt_set.contains("test1")
      check crdt_set.contains("test2")
      check crdt_set.len == 1
    
    test "CrdtZenSet dual-mode operations":
      # Test different modes
      var fast_set = CrdtZenSet[int].init(ctx, mode = FastLocal)
      var wait_set = CrdtZenSet[int].init(ctx, mode = WaitForSync)
      
      # FastLocal mode operations
      fast_set += 42
      check fast_set.contains(42)
      
      # WaitForSync mode operations  
      wait_set += 100
      check wait_set.contains(100)
      
      # Both should have their items
      check fast_set.len == 1
      check wait_set.len == 1
    
    test "CrdtZenSet mode switching":
      # Test dynamic mode switching
      var crdt_set = CrdtZenSet[string].init(ctx, mode = FastLocal)
      
      crdt_set += "item1"
      check crdt_set.contains("item1")
      
      # Switch to WaitForSync mode
      crdt_set.set_sync_mode(WaitForSync)
      
      crdt_set += "item2"
      check crdt_set.contains("item1")
      check crdt_set.contains("item2")
      
      # Switch back to FastLocal  
      crdt_set.set_sync_mode(FastLocal)
      
      crdt_set += "item3"
      check crdt_set.contains("item1")
      check crdt_set.contains("item2")
      check crdt_set.contains("item3")
    
    test "CrdtZenSet iteration works":
      # Test iteration over CRDT set
      var crdt_set = CrdtZenSet[int].init(ctx, mode = FastLocal)
      
      let test_items = [1, 2, 3, 4, 5]
      for item in test_items:
        crdt_set += item
      
      var found_items: seq[int] = @[]
      for item in crdt_set.crdt_items:
        found_items.add(item)
      
      check found_items.len == test_items.len
      for item in test_items:
        check item in found_items

when is_main_module:
  Zen.bootstrap
  run()