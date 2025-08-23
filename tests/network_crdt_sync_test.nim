import pkg/unittest2
import model_citizen
from std/times import init_duration
import std/os

const recv_duration = init_duration(milliseconds = 10)

proc run*() =
  suite "Network CRDT Synchronization":
    
    test "CRDT sync over network with FastLocal":
      # Test CRDT synchronization combined with network subscriptions
      var ctx1 = ZenContext.init(id = "network_client")
      var ctx2 = ZenContext.init(
        id = "network_server",
        listen_address = "127.0.0.1", 
        min_recv_duration = recv_duration,
        blocking_recv = true
      )
      
      try:
        # Set up network subscription 
        ctx1.subscribe "127.0.0.1"
        
        # Give network time to establish
        sleep(50)
        
        # Create CRDT-enabled ZenValues on both ends
        var client_data = ZenValue[string].init(
          sync_mode = FastLocal,
          id = "network_crdt_data", 
          ctx = ctx1
        )
        
        var server_data = ZenValue[string].init(
          sync_mode = FastLocal,
          id = "network_crdt_data",
          ctx = ctx2  
        )
        
        # Client updates - should sync both via CRDT and network
        client_data.value = "client_update_1"
        
        # Allow time for network propagation
        sleep(20)
        
        # Both CRDT sharing and network sync should work
        check client_data.value == "client_update_1"
        check server_data.value == "client_update_1"
        
        # Server responds
        server_data.value = "server_response_1"
        sleep(20)
        
        check client_data.value == "server_response_1"  
        check server_data.value == "server_response_1"
        
      finally:
        ctx1.close()
        ctx2.close()

    test "Network CRDT conflict resolution":
      # Test how CRDT behaves with network conflicts
      var ctx_node1 = ZenContext.init(id = "distributed_node1")
      var ctx_node2 = ZenContext.init(
        id = "distributed_node2",
        listen_address = "127.0.0.1",
        min_recv_duration = recv_duration,
        blocking_recv = true
      )
      
      try:
        # Set up bidirectional network sync
        ctx_node1.subscribe "127.0.0.1"
        sleep(50)  # Allow connection establishment
        
        # Both nodes create CRDT values with same ID
        var node1_counter = ZenValue[int].init(
          sync_mode = FastLocal,
          id = "distributed_counter",
          ctx = ctx_node1
        )
        
        var node2_counter = ZenValue[int].init(
          sync_mode = FastLocal, 
          id = "distributed_counter",
          ctx = ctx_node2
        )
        
        # Initial sync
        node1_counter.value = 100
        sleep(20)
        check node2_counter.value == 100
        
        # Simulate concurrent updates (conflict scenario)
        # In a real network, these might happen simultaneously
        node1_counter.value = 150  # Node 1 increments
        node2_counter.value = 200  # Node 2 sets different value
        
        sleep(30)  # Allow network propagation
        
        # With last-writer-wins CRDT behavior, both should converge
        # (The exact final value depends on timing, but they should be equal)
        check node1_counter.value == node2_counter.value
        
        # The value should be one of the written values
        let final_value = node1_counter.value
        check final_value == 150 or final_value == 200
        
      finally:
        ctx_node1.close()
        ctx_node2.close()

    test "Network sync with WaitForSync mode":
      # Test how WaitForSync behaves over network
      var ctx_primary = ZenContext.init(id = "primary_node")
      var ctx_replica = ZenContext.init(
        id = "replica_node",
        listen_address = "127.0.0.1",
        min_recv_duration = recv_duration,
        blocking_recv = true
      )
      
      try:
        ctx_primary.subscribe "127.0.0.1"
        sleep(50)
        
        var primary_status = ZenValue[string].init(
          sync_mode = WaitForSync,  # Using WaitForSync mode
          id = "network_sync_status",
          ctx = ctx_primary
        )
        
        var replica_status = ZenValue[string].init(
          sync_mode = WaitForSync,
          id = "network_sync_status", 
          ctx = ctx_replica
        )
        
        # Update from primary
        primary_status.value = "synchronized"
        sleep(30)  # Allow network sync
        
        # Both should show the synchronized value
        check primary_status.value == "synchronized"
        check replica_status.value == "synchronized"
        
        # Update from replica
        replica_status.value = "replica_updated"
        sleep(30)
        
        check primary_status.value == "replica_updated"
        check replica_status.value == "replica_updated"
        
      finally:
        ctx_primary.close()
        ctx_replica.close()

when is_main_module:
  Zen.bootstrap
  run()