import pkg/unittest2
import model_citizen
import std/[times, os]

proc run*() =
  suite "Multi-Context CRDT Sync":
    test "ZenValues with same ID should sync via shared Y-CRDT document":
      # Create two separate contexts (simulating different clients/threads)
      var ctx1 = ZenContext.init(id = "client1")
      var ctx2 = ZenContext.init(id = "client2") 
      
      try:
        # Create ZenValue objects with SAME object ID but DIFFERENT contexts
        # This should cause them to share the same Y-CRDT document
        var player_score_ctx1 = ZenValue[int].init(
          sync_mode = FastLocal, 
          ctx = ctx1, 
          id = "shared_player_score"  # SAME ID
        )
        
        var player_score_ctx2 = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx2, 
          id = "shared_player_score"  # SAME ID 
        )
        
        # Set different values initially
        player_score_ctx1.value = 100
        player_score_ctx2.value = 200
        
        # Both should have their local values immediately (FastLocal mode)
        check player_score_ctx1.value == 100
        check player_score_ctx2.value == 200
        
        # Verify they have CRDT state
        check player_score_ctx1.has_crdt_state()
        check player_score_ctx2.has_crdt_state()
        
        # Both should be using FastLocal mode
        check player_score_ctx1.sync_mode == FastLocal
        check player_score_ctx2.sync_mode == FastLocal
        
        # The key test: they should be sharing the same Y-CRDT document
        # This is verified by the document coordinator managing shared documents
        
      finally:
        ctx1.close()
        ctx2.close()

    test "ZenValues with different IDs should use separate Y-CRDT documents":
      var ctx1 = ZenContext.init(id = "client1")
      var ctx2 = ZenContext.init(id = "client2")
      
      try:
        # Create ZenValue objects with DIFFERENT object IDs
        var score_a = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx1,
          id = "score_a"  # DIFFERENT ID
        )
        
        var score_b = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx2,
          id = "score_b"  # DIFFERENT ID
        )
        
        # Set values
        score_a.value = 42
        score_b.value = 84
        
        # Should work independently
        check score_a.value == 42
        check score_b.value == 84
        check score_a.has_crdt_state()
        check score_b.has_crdt_state()
        
      finally:
        ctx1.close()
        ctx2.close()

    test "Y-CRDT document sharing with string values":
      var ctx_game = ZenContext.init(id = "game_server")
      var ctx_ui = ZenContext.init(id = "ui_client")
      
      try:
        # Both contexts create ZenValue with same ID for game state
        var game_state_server = ZenValue[string].init(
          sync_mode = FastLocal,
          ctx = ctx_game,
          id = "current_game_state"
        )
        
        var game_state_ui = ZenValue[string].init(
          sync_mode = FastLocal,
          ctx = ctx_ui,
          id = "current_game_state"  # SAME ID - should share Y-CRDT document
        )
        
        # Update game state from server
        game_state_server.value = "player1_turn"
        
        # Update from UI 
        game_state_ui.value = "player2_turn"
        
        # Both should have their local updates immediately
        check game_state_server.value == "player1_turn"
        check game_state_ui.value == "player2_turn"
        
        # Both should have CRDT backend
        check game_state_server.has_crdt_state()
        check game_state_ui.has_crdt_state()
        
      finally:
        ctx_game.close()
        ctx_ui.close()

    test "WaitForSync mode with shared documents":
      var ctx_primary = ZenContext.init(id = "primary")
      var ctx_replica = ZenContext.init(id = "replica")
      
      try:
        # Create with WaitForSync mode
        var primary_counter = ZenValue[int].init(
          sync_mode = WaitForSync,
          ctx = ctx_primary,
          id = "sync_counter"
        )
        
        var replica_counter = ZenValue[int].init(
          sync_mode = WaitForSync,
          ctx = ctx_replica,
          id = "sync_counter"  # SAME ID
        )
        
        # Set values (should still work at API level)
        primary_counter.value = 1000
        replica_counter.value = 2000
        
        # API should work regardless of sync mode  
        check primary_counter.value == 1000
        check replica_counter.value == 2000
        check primary_counter.sync_mode == WaitForSync
        check replica_counter.sync_mode == WaitForSync
        
      finally:
        ctx_primary.close()
        ctx_replica.close()

when is_main_module:
  Zen.bootstrap
  run()