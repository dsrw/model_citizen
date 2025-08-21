import std/tables

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

proc total_events*(self: VectorClock): uint64 =
  ## Get total number of events across all peers
  result = 0
  for count in self.clocks.values:
    result += count

proc happened_before*(self: VectorClock, other: VectorClock): bool =
  ## Simple logical ordering: fewer total events happened before more events
  self.total_events() < other.total_events()

proc is_concurrent_with*(self: VectorClock, other: VectorClock): bool =
  ## Events are concurrent only if they have exactly the same total count
  self.total_events() == other.total_events()

when is_main_module:
  var clock1 = VectorClock.init("peer1") 
  var clock2 = VectorClock.init("peer2")
  
  echo "=== Test Simple Clock Logic ==="
  echo "Initial state:"
  echo "clock1 total: ", clock1.total_events()
  echo "clock2 total: ", clock2.total_events()
  echo "concurrent: ", clock1.is_concurrent_with(clock2)
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  echo ""
  
  clock1.tick()
  echo "After clock1.tick():"
  echo "clock1 total: ", clock1.total_events()
  echo "clock2 total: ", clock2.total_events()
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  echo ""
  
  clock2.tick()
  clock2.tick()
  echo "After clock2.tick() x2:"
  echo "clock1 total: ", clock1.total_events()
  echo "clock2 total: ", clock2.total_events()
  echo "concurrent: ", clock1.is_concurrent_with(clock2)
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)