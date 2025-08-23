import pkg/unittest2
import model_citizen

proc run*() =
  suite "ZenSeq CRDT Integration":
    setup:
      var ctx = ZenContext.init(id = "test_ctx")
    
    teardown:
      ctx.close()
    
    test "ZenSeq supports sync_mode parameter":
      # Test that ZenSeq.init accepts sync_mode parameter
      var regular = ZenSeq[int].init(ctx = ctx, id = "regular")
      var fast_local = ZenSeq[int].init(sync_mode = FastLocal, ctx = ctx, id = "fast")  
      var wait_sync = ZenSeq[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait")
      
      check regular.sync_mode == SyncMode.FastLocal  # Default is now FastLocal
      check fast_local.sync_mode == FastLocal
      check wait_sync.sync_mode == WaitForSync
    
    test "ZenSeq with CRDT modes supports basic operations":
      # Test that basic operations work regardless of sync mode
      var regular = ZenSeq[string].init(ctx = ctx, id = "regular")
      var crdt_fast = ZenSeq[string].init(sync_mode = FastLocal, ctx = ctx, id = "crdt")
      
      # Adding values should work
      regular.add("regular_item")
      crdt_fast.add("crdt_item")
      
      # Reading values should work
      check regular[0] == "regular_item"
      check crdt_fast[0] == "crdt_item"
      
      # Setting values should work
      regular.add("second")
      crdt_fast.add("second")
      regular[1] = "updated_regular"
      crdt_fast[1] = "updated_crdt"
      
      check regular[1] == "updated_regular"
      check crdt_fast[1] == "updated_crdt"
    
    test "ZenSeq preserves existing API compatibility":
      # Test that existing ZenSeq usage patterns still work
      var zen_seq = ZenSeq[int].init(ctx = ctx)
      
      # Default sync_mode should be FastLocal
      check zen_seq.sync_mode == SyncMode.FastLocal
      
      # Basic operations
      zen_seq.add(42)
      zen_seq.add(84)
      
      check zen_seq[0] == 42
      check zen_seq[1] == 84
      
      # Index assignment
      zen_seq[0] = 100
      check zen_seq[0] == 100
    
    test "Yolo mode uses traditional ZenSeq sync":
      # Test that Yolo mode still works for traditional sync
      var yolo_seq = ZenSeq[string].init(sync_mode = Yolo, ctx = ctx)
      check yolo_seq.sync_mode == Yolo
      
      # Should work with basic operations and use traditional Zen sync
      yolo_seq.add("yolo1")
      yolo_seq.add("yolo2")
      check yolo_seq[0] == "yolo1"
      check yolo_seq[1] == "yolo2"
      
      yolo_seq[0] = "updated_yolo"
      check yolo_seq[0] == "updated_yolo"

    test "FastLocal vs WaitForSync modes work":
      # Test different CRDT modes
      var fast_seq = ZenSeq[int].init(sync_mode = FastLocal, ctx = ctx)
      var wait_seq = ZenSeq[int].init(sync_mode = WaitForSync, ctx = ctx)
      
      # Both should support the same operations
      fast_seq.add(1)
      wait_seq.add(1)
      
      check fast_seq[0] == 1
      check wait_seq[0] == 1
      
      fast_seq[0] = 10
      wait_seq[0] = 10
      
      check fast_seq[0] == 10
      check wait_seq[0] == 10

when is_main_module:
  Zen.bootstrap
  run()