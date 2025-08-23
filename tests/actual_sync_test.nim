import pkg/unittest2
import model_citizen
import std/[os]

proc run*() =
  suite "Actual CRDT Synchronization":
    test "ZenValue should read values written by other contexts":
      # Create two separate contexts 
      var ctx1 = ZenContext.init(id = "writer_context")
      var ctx2 = ZenContext.init(id = "reader_context")
      
      try:
        # Create ZenValue objects with SAME ID but DIFFERENT contexts
        # They will share the same Y-CRDT document
        var writer = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx1,
          id = "actual_sync_counter"
        )
        
        var reader = ZenValue[int].init(
          sync_mode = FastLocal,
          ctx = ctx2,
          id = "actual_sync_counter"  # SAME ID = shared Y-CRDT document
        )
        
        # Initially, both should have default values (0 for new document)
        check writer.value == 0
        check reader.value == 0
        
        # Write from first context
        writer.value = 42
        
        # The writer should immediately see its own value (FastLocal)
        check writer.value == 42
        
        # The key test: reader should be able to read the value from Y-CRDT
        # that was written by the writer context
        check reader.value == 42  # This tests actual CRDT synchronization!
        
      finally:
        ctx1.close()
        ctx2.close()

    test "String synchronization between contexts":
      var ctx_alice = ZenContext.init(id = "alice")
      var ctx_bob = ZenContext.init(id = "bob")
      
      try:
        var alice_message = ZenValue[string].init(
          sync_mode = FastLocal,
          ctx = ctx_alice,
          id = "actual_chat_message"
        )
        
        var bob_message = ZenValue[string].init(
          sync_mode = FastLocal,
          ctx = ctx_bob,
          id = "actual_chat_message"  # SAME ID
        )
        
        # Alice writes a message
        alice_message.value = "Hello from Alice!"
        
        # Alice can read her own message
        check alice_message.value == "Hello from Alice!"
        
        # Bob should be able to read Alice's message from the shared CRDT
        check bob_message.value == "Hello from Alice!"
        
        # Bob responds
        bob_message.value = "Hi Alice, this is Bob!"
        
        # Bob sees his own message
        check bob_message.value == "Hi Alice, this is Bob!"
        
        # Alice should see Bob's response from the CRDT
        check alice_message.value == "Hi Alice, this is Bob!"
        
      finally:
        ctx_alice.close()
        ctx_bob.close()

    test "Multiple contexts reading and writing":
      var ctx1 = ZenContext.init(id = "node1")
      var ctx2 = ZenContext.init(id = "node2")
      var ctx3 = ZenContext.init(id = "node3")
      
      try:
        var counter1 = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx1, id = "actual_global_counter")
        var counter2 = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx2, id = "actual_global_counter")  
        var counter3 = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx3, id = "actual_global_counter")
        
        # All start at 0
        check counter1.value == 0
        check counter2.value == 0
        check counter3.value == 0
        
        # Node 1 increments
        counter1.value = 1
        check counter1.value == 1
        check counter2.value == 1  # Should read from shared CRDT
        check counter3.value == 1  # Should read from shared CRDT
        
        # Node 2 increments further
        counter2.value = 2
        check counter1.value == 2
        check counter2.value == 2
        check counter3.value == 2
        
        # Node 3 sets final value
        counter3.value = 100
        check counter1.value == 100
        check counter2.value == 100
        check counter3.value == 100
        
      finally:
        ctx1.close()
        ctx2.close()
        ctx3.close()

    test "Boolean synchronization":
      var ctx_client = ZenContext.init(id = "client")
      var ctx_server = ZenContext.init(id = "server")
      
      try:
        var client_flag = ZenValue[bool].init(sync_mode = FastLocal, ctx = ctx_client, id = "actual_ready_flag")
        var server_flag = ZenValue[bool].init(sync_mode = FastLocal, ctx = ctx_server, id = "actual_ready_flag")
        
        # Initially false
        check client_flag.value == false
        check server_flag.value == false
        
        # Client sets ready
        client_flag.value = true
        check client_flag.value == true
        check server_flag.value == true  # Server should see client's flag
        
        # Server acknowledges
        server_flag.value = false
        check client_flag.value == false  # Client should see server's response
        check server_flag.value == false
        
      finally:
        ctx_client.close()
        ctx_server.close()

    test "Float synchronization":
      var ctx1 = ZenContext.init(id = "sensor1") 
      var ctx2 = ZenContext.init(id = "display1")
      
      try:
        var sensor_temp = ZenValue[float].init(sync_mode = FastLocal, ctx = ctx1, id = "actual_temperature")
        var display_temp = ZenValue[float].init(sync_mode = FastLocal, ctx = ctx2, id = "actual_temperature")
        
        # Sensor reads temperature
        sensor_temp.value = 23.5
        check sensor_temp.value == 23.5
        check display_temp.value == 23.5  # Display should show sensor reading
        
        # Temperature changes
        sensor_temp.value = 24.8
        check display_temp.value == 24.8
        
      finally:
        ctx1.close()
        ctx2.close()

when is_main_module:
  Zen.bootstrap
  run()