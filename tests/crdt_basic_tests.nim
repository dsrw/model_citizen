{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
import std/[unittest, strutils]
import model_citizen

proc run*() =
  suite "CRDT Basic Tests":
    setup:
      var ctx = ZenContext.init(id = "test_ctx")
    
    teardown:
      ctx.close()
    
    test "CrdtZenValue FastLocal mode":
      # Test that FastLocal mode provides immediate responsiveness
      var player_pos = CrdtZenValue[int].init(ctx, id = "player_pos", mode = FastLocal)
      
      var callback_fired = false
      var received_value: int
      var received_sync_state: SyncState
      
      player_pos.track proc(changes: seq[CrdtChange[int]]) =
        callback_fired = true
        for change in changes:
          received_value = change.new_value
          received_sync_state = change.sync_state
      
      # Set value - should trigger immediate callback in FastLocal mode
      player_pos.value = 42
      
      check callback_fired == true
      check received_value == 42
      check player_pos.value == 42  # Should return local value immediately
      check received_sync_state in [Syncing, Converged]  # May be either depending on sync speed
    
    test "CrdtZenValue mode switching":
      var game_score = CrdtZenValue[int].init(ctx, id = "game_score", mode = FastLocal)
      
      # Start in FastLocal mode
      check game_score.mode == FastLocal
      game_score.value = 100
      check game_score.value == 100
      
      # Switch to WaitForSync mode
      game_score.set_sync_mode(WaitForSync)
      check game_score.mode == WaitForSync
      
      # Value should still be accessible
      check game_score.value == 100
    
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
    
    test "Sync state tracking":
      var sync_obj = CrdtZenValue[string].init(ctx, id = "sync_test", mode = FastLocal)
      
      var sync_states: seq[SyncState] = @[]
      sync_obj.track_sync proc(state: SyncState) =
        sync_states.add(state)
      
      # Setting value should eventually trigger sync callbacks
      sync_obj.value = "test_value"
      
      # For now, just check that the object is created properly
      check sync_obj.value == "test_value"
      check sync_obj.sync_state in [LocalOnly, Syncing, Converged]
    
    test "CRDT types compilation":
      # Test that all CRDT types compile correctly
      var crdt_table = CrdtZenTable[string, int].init(ctx, id = "test_table")
      var crdt_seq = CrdtZenSeq[string].init(ctx, id = "test_seq") 
      var crdt_set = CrdtZenSet[int].init(ctx, id = "test_set")
      
      # Basic operations should work (though full functionality not implemented yet)
      check crdt_table.id == "test_table"
      check crdt_seq.id == "test_seq"
      check crdt_set.id == "test_set"

when is_main_module:
  Zen.bootstrap
  run()