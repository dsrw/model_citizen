{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
import pkg/unittest2
import model_citizen
import model_citizen/crdt/[crdt_types, unified_crdt]

proc run*() =
  suite "CRDT Basic Tests":
    setup:
      var ctx = ZenContext.init(id = "test_ctx")
    
    teardown:
      ctx.close()
    
    test "ZenValue FastLocal CRDT mode":
      # Test that FastLocal mode provides immediate responsiveness
      var player_pos = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "player_pos")
      
      # Basic operations should work with unified API
      player_pos.value = 42
      check player_pos.value == 42  # Should return local value immediately
      
      # Check that CRDT state is enabled
      check player_pos.has_crdt_state() == true
    
    test "ZenValue CRDT sync modes":
      var game_score = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "game_score")
      
      # Start in FastLocal mode  
      check game_score.sync_mode == FastLocal
      game_score.value = 100
      check game_score.value == 100
      
      # Unified API - sync modes are set at creation time
      var wait_score = ZenValue[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait_score")
      check wait_score.sync_mode == WaitForSync
    
    test "Vector clock operations":
      var clock1 = VectorClock.init("peer1")
      var clock2 = VectorClock.init("peer2")
      
      # Initial state
      check not clock1.is_concurrent_with(clock2)
      check not clock1.happened_before(clock2)
      check not clock2.happened_before(clock1)
      
      # After one peer increments
      clock1.tick()
      check clock1.happened_before(clock2) == false  # clock2 hasn't moved
      check clock2.happened_before(clock1) == true   # clock1 is ahead
      
      # After both increment  
      clock2.tick()
      clock2.tick()  # Make clock2 ahead
      check clock1.is_concurrent_with(clock2) == false  # One is clearly ahead
      check clock2.happened_before(clock1) == false
      check clock1.happened_before(clock2) == true
    
    test "CRDT sync state tracking":
      var sync_obj = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx, id = "sync_test")
      
      # Setting value should work with unified API
      sync_obj.value = "test_value"
      
      # Basic check that the object is created properly
      check sync_obj.value == "test_value"
      check sync_obj.has_crdt_state() == true
    
    # test "CRDT collection types":
    #   # TODO: Implement ZenSeq and ZenSet CRDT support in unified approach
    #   # For now, only ZenValue CRDT is supported through unified API
    #   var zen_seq = ZenSeq[string].init(ctx, id = "test_seq", sync_mode = FastLocal)
    #   var zen_set = ZenSet[int].init(ctx, id = "test_set", sync_mode = FastLocal)
    #   
    #   check zen_seq.id == "test_seq"
    #   check zen_set.id == "test_set"

when is_main_module:
  Zen.bootstrap
  run()