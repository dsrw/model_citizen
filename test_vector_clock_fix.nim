import std/[tables, sequtils]

type
  VectorClock* = ref object
    clocks*: Table[string, uint64]
    local_id*: string

proc init*(_: type VectorClock, local_id: string): VectorClock =
  result = VectorClock()
  result.local_id = local_id
  result.clocks = init_table[string, uint64]()
  result.clocks[local_id] = 0

proc tick*(self: VectorClock) =
  self.clocks[self.local_id] = self.clocks.get_or_default(self.local_id, 0) + 1

proc sync_knowledge*(self: VectorClock, other: VectorClock) =
  ## Sync knowledge of other peers (simulates communication)
  for peer_id, peer_time in other.clocks:
    if peer_id != self.local_id:
      self.clocks[peer_id] = max(
        self.clocks.get_or_default(peer_id, 0),
        peer_time
      )

proc happened_before*(self: VectorClock, other: VectorClock): bool =
  # For comparison, temporarily sync knowledge
  var self_copy = VectorClock()
  self_copy.clocks = self.clocks
  self_copy.local_id = self.local_id
  var other_copy = VectorClock()
  other_copy.clocks = other.clocks
  other_copy.local_id = other.local_id
  
  # Ensure both know about all peers
  for peer in self.clocks.keys:
    if peer notin other_copy.clocks:
      other_copy.clocks[peer] = 0
  for peer in other.clocks.keys:
    if peer notin self_copy.clocks:
      self_copy.clocks[peer] = 0
  
  var all_less_or_equal = true
  var at_least_one_less = false
  
  for peer in self_copy.clocks.keys:
    let self_time = self_copy.clocks[peer]
    let other_time = other_copy.clocks[peer]
    
    if self_time > other_time:
      all_less_or_equal = false
      break
    elif self_time < other_time:
      at_least_one_less = true
      
  result = all_less_or_equal and at_least_one_less

proc is_concurrent_with*(self: VectorClock, other: VectorClock): bool =
  result = not self.happened_before(other) and not other.happened_before(self)

when is_main_module:
  var clock1 = VectorClock.init("peer1") 
  var clock2 = VectorClock.init("peer2")
  
  echo "=== Test Vector Clock Logic ==="
  echo "Initial state:"
  echo "clock1: ", clock1.clocks
  echo "clock2: ", clock2.clocks
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  echo ""
  
  clock1.tick()
  echo "After clock1.tick():"
  echo "clock1: ", clock1.clocks  
  echo "clock2: ", clock2.clocks
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  echo ""
  
  clock2.tick()
  clock2.tick()
  echo "After clock2.tick() x2:"
  echo "clock1: ", clock1.clocks
  echo "clock2: ", clock2.clocks  
  echo "concurrent: ", clock1.is_concurrent_with(clock2)
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)