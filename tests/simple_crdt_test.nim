import pkg/unittest2
import model_citizen

proc run*() =
  suite "Simple CRDT Test":
    test "Basic ZenValue CRDT operations":
      # Test that ZenValue with CRDT mode works at basic level
      var ctx = ZenContext.init(id = "simple_test")
      
      try:
        # Create ZenValue with FastLocal mode
        var crdt_value = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "test_value")
        
        # Set a value (should use CRDT backend)
        crdt_value.value = 42
        
        # Read it back
        check crdt_value.value == 42
        check crdt_value.sync_mode == FastLocal
        
      finally:
        ctx.close()

    test "ZenValue CRDT vs Yolo mode comparison":
      var ctx = ZenContext.init(id = "comparison_test") 
      
      try:
        # Traditional Yolo mode
        var yolo_value = ZenValue[string].init(sync_mode = Yolo, ctx = ctx, id = "yolo")
        yolo_value.value = "traditional"
        
        # CRDT FastLocal mode
        var crdt_value = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx, id = "crdt")  
        crdt_value.value = "crdt_enabled"
        
        # Both should work the same at API level
        check yolo_value.value == "traditional"
        check crdt_value.value == "crdt_enabled"
        check yolo_value.sync_mode == Yolo
        check crdt_value.sync_mode == FastLocal
        
      finally:
        ctx.close()

when is_main_module:
  Zen.bootstrap
  run()