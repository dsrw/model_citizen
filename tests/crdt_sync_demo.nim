import pkg/unittest2
import model_citizen
import std/[times]

proc run*() =
  suite "CRDT Sync Demo":
    test "Two ZenValues with same ID should sync via CRDT":
      # Create two separate contexts (simulating different clients)
      var ctx1 = ZenContext.init(id = "client1")
      var ctx2 = ZenContext.init(id = "client2") 
      
      try:
        # Create ZenValue objects with same document ID but different contexts
        var player_score1 = ZenValue[int].init(
          sync_mode = FastLocal, 
          ctx = ctx1, 
          id = "player_score"
        )
        
        var player_score2 = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx2, 
          id = "player_score"
        )
        
        # Set values sequentially - with shared CRDT, last write wins
        player_score1.value = 100
        check player_score1.value == 100
        check player_score2.value == 100  # Should see player1's value due to shared CRDT
        
        player_score2.value = 200
        # Both should now see the last written value (CRDT synchronization)
        check player_score1.value == 200
        check player_score2.value == 200
        
        # Verify they have CRDT state
        check player_score1.has_crdt_state()
        check player_score2.has_crdt_state()
        
        # Both should be using FastLocal mode
        check player_score1.sync_mode == FastLocal
        check player_score2.sync_mode == FastLocal
        
      finally:
        ctx1.close()
        ctx2.close()

    test "CRDT document sharing between contexts":
      var ctx_a = ZenContext.init(id = "context_a")
      var ctx_b = ZenContext.init(id = "context_b")
      
      try:
        # Create values with same document ID
        var shared_counter_a = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx_a,
          id = "shared_counter"
        )
        
        var shared_counter_b = ZenValue[int].init(
          sync_mode = FastLocal, 
          ctx = ctx_b,
          id = "shared_counter"
        )
        
        # Set different values sequentially
        shared_counter_a.value = 42
        check shared_counter_a.value == 42
        check shared_counter_b.value == 42  # Should see shared value
        
        shared_counter_b.value = 84
        # Both should see the last written value
        check shared_counter_a.value == 84
        check shared_counter_b.value == 84
        
        # Both should have CRDT backend enabled
        check shared_counter_a.has_crdt_state() == true
        check shared_counter_b.has_crdt_state() == true
        
      finally:
        ctx_a.close()
        ctx_b.close()

    test "WaitForSync mode test":
      var ctx = ZenContext.init(id = "wait_sync_test")
      
      try:
        # Create with WaitForSync mode
        var sync_value = ZenValue[string].init(
          sync_mode = WaitForSync,
          ctx = ctx,
          id = "sync_string"
        )
        
        # Set value (in WaitForSync, this should still work but may be slower)
        sync_value.value = "synchronized"
        
        # Should work same as FastLocal at API level for now
        check sync_value.value == "synchronized"
        check sync_value.sync_mode == WaitForSync
        check sync_value.has_crdt_state() == true
        
      finally:
        ctx.close()

when is_main_module:
  Zen.bootstrap
  run()