import src/model_citizen/crdt/crdt_types

when is_main_module:
  var clock1 = VectorClock.init("peer1") 
  var clock2 = VectorClock.init("peer2")
  
  echo "Initial:"
  echo "clock1: ", clock1.clocks
  echo "clock2: ", clock2.clocks
  echo "concurrent: ", clock1.is_concurrent_with(clock2)
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  
  clock1.tick()
  echo "\nAfter clock1.tick():"
  echo "clock1: ", clock1.clocks  
  echo "clock2: ", clock2.clocks
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)
  
  clock2.tick()
  clock2.tick()
  echo "\nAfter clock2.tick() x2:"
  echo "clock1: ", clock1.clocks
  echo "clock2: ", clock2.clocks  
  echo "concurrent: ", clock1.is_concurrent_with(clock2)
  echo "1 before 2: ", clock1.happened_before(clock2)
  echo "2 before 1: ", clock2.happened_before(clock1)