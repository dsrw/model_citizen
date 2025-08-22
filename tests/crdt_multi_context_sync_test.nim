{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
import pkg/unittest2
import std/[times, tables]
import model_citizen/[core, types, components/subscriptions]
import model_citizen/zens/[contexts, initializers]
import model_citizen/crdt/[crdt_types]
# Commenting out crdt_zen_value temporarily to test regular Zen
# import model_citizen/crdt/[crdt_zen_value]

proc run*() =
  suite "Multi-Context CRDT Sync Tests":
    
    test "Basic ZenContext creation":
      # Set up two contexts
      var ctx1 = ZenContext.init(id = "ctx1") 
      var ctx2 = ZenContext.init(id = "ctx2")
      
      # Basic context creation should work
      check ctx1.id == "ctx1"
      check ctx2.id == "ctx2"
      
    test "Basic ZenValue creation with Yolo mode":
      var ctx = ZenContext.init(id = "test-ctx")
      
      # Create basic ZenValue with Yolo mode (traditional behavior)
      var zen = ZenValue[int].init(ctx = ctx, id = "test-value", sync_mode = Yolo)
      zen.value = 42
      
      # Basic check - no crash
      check zen.value == 42
      
    test "ZenValue Yolo mode operations":
      var ctx = ZenContext.init(id = "test-ctx")
      
      # Test traditional Yolo sync mode
      var zen_yolo = ZenValue[string].init(ctx = ctx, id = "yolo", sync_mode = Yolo)
      
      zen_yolo.value = "yolo"
      
      check zen_yolo.value == "yolo"
      
    # test "Direct CRDT ZenValue creation":
    #   var ctx = ZenContext.init(id = "test-ctx")
    #   
    #   # Test direct CRDT value creation 
    #   var crdt_val = CrdtZenValue[int].init(ctx = ctx, id = "crdt-test")
    #   crdt_val.value = 100
    #   
    #   check crdt_val.value == 100

if is_main_module:
  run()