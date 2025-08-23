import pkg/unittest2
import model_citizen
import std/[times, os]

proc run*() =
  suite "Advanced CRDT Scenarios":
    
    test "FastLocal value correction via CRDT":
      # This tests a scenario where FastLocal shows immediate updates
      # but the CRDT backend provides the authoritative value
      var ctx_client = ZenContext.init(id = "client_device")
      var ctx_server = ZenContext.init(id = "authoritative_server")
      
      try:
        # Client creates with FastLocal for immediate UI response
        var client_score = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx_client,
          id = "game_score_authoritative"
        )
        
        # Server has the authoritative version  
        var server_score = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx_server,
          id = "game_score_authoritative"
        )
        
        # Client makes optimistic update
        client_score.value = 100
        check client_score.value == 100
        check server_score.value == 100  # Sees client's value via CRDT
        
        # Server corrects the value (e.g., due to validation)
        server_score.value = 75  # Corrected score after validation
        
        # Client should now see the corrected value from server
        check client_score.value == 75
        check server_score.value == 75
        
      finally:
        ctx_client.close()
        ctx_server.close()

    test "Multi-step CRDT synchronization chain":
      # Test synchronization across multiple contexts in sequence
      var ctx1 = ZenContext.init(id = "node_1") 
      var ctx2 = ZenContext.init(id = "node_2")
      var ctx3 = ZenContext.init(id = "node_3")
      
      try:
        var status1 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx1, id = "chain_status")
        var status2 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx2, id = "chain_status")
        var status3 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx3, id = "chain_status")
        
        # Step 1: Node 1 initiates
        status1.value = "step_1_complete"
        check status1.value == "step_1_complete"
        check status2.value == "step_1_complete"
        check status3.value == "step_1_complete"
        
        # Step 2: Node 2 continues the chain
        status2.value = "step_2_complete"
        check status1.value == "step_2_complete"
        check status2.value == "step_2_complete"
        check status3.value == "step_2_complete"
        
        # Step 3: Node 3 finishes
        status3.value = "all_steps_complete"
        check status1.value == "all_steps_complete"
        check status2.value == "all_steps_complete"
        check status3.value == "all_steps_complete"
        
      finally:
        ctx1.close()
        ctx2.close()
        ctx3.close()

    test "WaitForSync behavior compared to FastLocal":
      # Compare how WaitForSync and FastLocal behave with corrections
      var ctx_fast = ZenContext.init(id = "fast_client")
      var ctx_wait = ZenContext.init(id = "wait_client")  
      var ctx_auth = ZenContext.init(id = "auth_server")
      
      try:
        var fast_balance = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_fast, id = "account_balance")
        var wait_balance = ZenValue[int].init(sync_mode = WaitForSync, ctx = ctx_wait, id = "account_balance") 
        var auth_balance = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_auth, id = "account_balance")
        
        # Initial balance
        auth_balance.value = 1000
        check fast_balance.value == 1000
        check wait_balance.value == 1000
        check auth_balance.value == 1000
        
        # FastLocal client tries optimistic update
        fast_balance.value = 1500  # Optimistic spend
        
        # All should see the optimistic value immediately (shared CRDT)
        check fast_balance.value == 1500
        check wait_balance.value == 1500  # Even WaitForSync sees it due to shared document
        check auth_balance.value == 1500
        
        # Server corrects (insufficient funds)
        auth_balance.value = 950  # Actual balance after fees
        
        # All contexts should see the correction
        check fast_balance.value == 950
        check wait_balance.value == 950  
        check auth_balance.value == 950
        
      finally:
        ctx_fast.close()
        ctx_wait.close()
        ctx_auth.close()

    test "High-frequency updates with CRDT stability":
      # Test rapid updates to ensure CRDT remains consistent
      var ctx_producer = ZenContext.init(id = "data_producer")
      var ctx_consumer1 = ZenContext.init(id = "consumer_1")
      var ctx_consumer2 = ZenContext.init(id = "consumer_2")
      
      try:
        var producer_counter = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_producer, id = "high_freq_counter")
        var consumer1_counter = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_consumer1, id = "high_freq_counter")
        var consumer2_counter = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_consumer2, id = "high_freq_counter")
        
        # Rapid sequence of updates
        for i in 1..10:
          producer_counter.value = i * 10
          
          # All contexts should see the latest value
          check producer_counter.value == i * 10
          check consumer1_counter.value == i * 10
          check consumer2_counter.value == i * 10
        
        # Final check - all should have consistent state
        let final_value = producer_counter.value
        check consumer1_counter.value == final_value
        check consumer2_counter.value == final_value
        check final_value == 100  # Last iteration (10 * 10)
        
      finally:
        ctx_producer.close()
        ctx_consumer1.close()  
        ctx_consumer2.close()

    test "Mixed data types in shared CRDT scenario":
      # Test multiple different data types sharing CRDT documents
      var ctx_app = ZenContext.init(id = "mobile_app")
      var ctx_backend = ZenContext.init(id = "backend_service")
      
      try:
        # Different data types with different document IDs but same sync pattern
        var app_username = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx_app, id = "user_name")
        var backend_username = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx_backend, id = "user_name")
        
        var app_score = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_app, id = "user_score") 
        var backend_score = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx_backend, id = "user_score")
        
        var app_verified = ZenValue[bool].init(sync_mode = FastLocal, ctx = ctx_app, id = "user_verified")
        var backend_verified = ZenValue[bool].init(sync_mode = FastLocal, ctx = ctx_backend, id = "user_verified")
        
        # App updates user profile
        app_username.value = "player123"  
        app_score.value = 2500
        app_verified.value = true
        
        # Backend should see all updates
        check backend_username.value == "player123"
        check backend_score.value == 2500
        check backend_verified.value == true
        
        # Backend corrects some values
        backend_score.value = 2450  # Score correction
        backend_verified.value = false  # Re-verification needed
        
        # App should see backend corrections
        check app_username.value == "player123"  # Unchanged
        check app_score.value == 2450  # Corrected by backend
        check app_verified.value == false  # Corrected by backend
        
      finally:
        ctx_app.close()
        ctx_backend.close()

    test "CRDT document isolation by ID":
      # Ensure different document IDs don't interfere with each other
      var ctx1 = ZenContext.init(id = "service_1")
      var ctx2 = ZenContext.init(id = "service_2") 
      
      try:
        # Same contexts, different document IDs - should be isolated
        var doc1_ctx1 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx1, id = "document_alpha")
        var doc1_ctx2 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx2, id = "document_alpha")
        
        var doc2_ctx1 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx1, id = "document_beta")
        var doc2_ctx2 = ZenValue[string].init(sync_mode = FastLocal, ctx = ctx2, id = "document_beta")
        
        # Update document_alpha
        doc1_ctx1.value = "alpha_data"
        check doc1_ctx1.value == "alpha_data"
        check doc1_ctx2.value == "alpha_data"  # Same document ID, should sync
        
        # document_beta should be unaffected  
        check doc2_ctx1.value == ""  # Default empty string
        check doc2_ctx2.value == ""
        
        # Update document_beta
        doc2_ctx2.value = "beta_data"
        check doc2_ctx1.value == "beta_data"  # Same document ID, should sync
        check doc2_ctx2.value == "beta_data"
        
        # document_alpha should be unchanged
        check doc1_ctx1.value == "alpha_data"
        check doc1_ctx2.value == "alpha_data"
        
      finally:
        ctx1.close()
        ctx2.close()

when is_main_module:
  Zen.bootstrap
  run()