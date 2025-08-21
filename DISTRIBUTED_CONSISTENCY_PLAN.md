# Model Citizen Distributed Consistency Plan

## Executive Summary

Model Citizen currently has fundamental consistency issues that make it unsuitable for production use where data integrity is critical. The current architecture allows for race conditions, lost updates, and inconsistent state when multiple contexts modify shared data concurrently. This document outlines three architectural approaches to achieve sound distributed consistency while preserving the reactive programming model.

## Current State Analysis

### Architecture Overview
- **ZenContext**: Central coordination managing object lifecycle and subscriptions
- **Reactive Objects**: ZenTable, ZenSeq, ZenSet, ZenValue with change callbacks
- **Synchronization**: Message-passing via channels (local) and netty (remote)
- **Change Propagation**: Immediate broadcast to subscribers without coordination

### Identified Consistency Issues

1. **Race Conditions**: Concurrent modifications can clobber each other (demonstrated in `tests/failing/concurrent_safety_tests.nim`)
2. **Lost Updates**: No transaction boundaries or atomic operations
3. **Network Partitions**: No handling of split-brain scenarios  
4. **Ordering Issues**: No guaranteed message ordering across contexts
5. **No Rollback**: Changes are immediately applied with no abort mechanism

### Fundamental Incompatibilities

The current model has some features that conflict with strong consistency:
- **Immediate Local Application**: Changes apply locally before remote coordination
- **Fire-and-Forget Messaging**: No acknowledgment or consensus required
- **No Transactions**: Operations execute individually without atomicity

## Recommended Approaches

### Option 1: CRDT-Based Eventually Consistent (Recommended)

#### Overview
Implement Conflict-free Replicated Data Types while preserving the reactive model. This provides eventual consistency without requiring consensus protocols.

#### Technical Design

**CRDT Integration Layer**
```nim
type
  CrdtZenValue[T] = ref object of ZenBase
    crdt_state: StateBased_CRDT[T]
    vector_clock: VectorClock
    
  CrdtZenTable[K, V] = ref object of ZenBase  
    crdt_state: ORMap[K, V]
    vector_clock: VectorClock
```

**Implementation Strategy**
- Replace internal data structures with CRDT equivalents
- Maintain reactive callback system on top of CRDT merge operations  
- Use vector clocks for causal ordering
- Implement delta-state CRDTs for efficient network transmission

**CRDT Types Mapping**
- `ZenValue[T]` → Last-Writer-Wins Register with timestamps
- `ZenTable[K,V]` → OR-Map (Observed-Remove Map)  
- `ZenSeq[T]` → RGA (Replicated Growable Array) or Logoot
- `ZenSet[T]` → OR-Set (Observed-Remove Set)

**Benefits**
- ✅ Mathematically guaranteed eventual consistency
- ✅ Excellent partition tolerance  
- ✅ Preserves reactive programming model
- ✅ No need for leader election or consensus
- ✅ Strong theoretical foundation

**Drawbacks**
- ❌ Memory overhead (metadata for each element)
- ❌ Complex to implement correctly
- ❌ Some operations may behave unexpectedly (e.g., sequence ordering)
- ❌ No traditional transactions

**Performance Characteristics** (2024 research)
- Modern CRDT implementations show 5000x improvements over early versions
- Delta-state CRDTs reduce network overhead significantly
- Memory usage typically 2-4x baseline due to metadata

#### Implementation Timeline
- **Phase 1** (2-3 months): CRDT library integration, basic LWW-Register
- **Phase 2** (3-4 months): OR-Map and OR-Set implementation  
- **Phase 3** (4-5 months): Sequence CRDT (most complex)
- **Phase 4** (1-2 months): Performance optimization and testing

### Option 2: Raft-Based Strong Consistency

#### Overview
Implement a Raft consensus layer that coordinates all mutations while maintaining the reactive interface.

#### Technical Design

**Consensus Layer**
```nim
type
  RaftZenContext = ref object of ZenContext
    raft_node: RaftNode
    pending_operations: Table[string, Future[void]]
    is_leader: bool
    
  TransactionOperation = object
    operation_type: OperationType
    target_id: string  
    data: string
    transaction_id: string
```

**Transaction Flow**
1. Local operation → Create transaction proposal
2. Submit to Raft leader for consensus  
3. Leader replicates to majority
4. Apply operation and trigger callbacks
5. Notify client of commit/abort

**Benefits**
- ✅ Strong consistency guarantees
- ✅ Well-understood algorithm with many implementations
- ✅ ACID transaction support possible
- ✅ Clear commit/rollback semantics

**Drawbacks**
- ❌ Requires leader election (availability impact)
- ❌ Higher latency (consensus round-trip)
- ❌ Complex integration with reactive model
- ❌ Network partition sensitivity

#### Implementation Strategy
- Use HashiCorp Raft (Go) with Nim FFI bindings
- Implement transaction log serialization with flatty
- Batch operations for performance
- Add transaction callbacks for commit/rollback events

#### Implementation Timeline  
- **Phase 1** (2-3 months): Raft integration and basic operations
- **Phase 2** (3-4 months): Transaction system and rollback
- **Phase 3** (2-3 months): Performance optimization
- **Phase 4** (1-2 months): Advanced features (read replicas, etc.)

### Option 3: Hybrid Operational Transform + Consensus

#### Overview
Use Operational Transform for real-time collaboration with Raft consensus for transaction boundaries.

#### Technical Design
- **OT Layer**: Handle concurrent operations on same data
- **Raft Layer**: Establish operation ordering and transaction boundaries
- **Reactive Layer**: Maintain current callback system

**Benefits**
- ✅ Excellent for collaborative editing scenarios
- ✅ Strong consistency with good real-time performance  
- ✅ Well-suited for sequence operations

**Drawbacks**
- ❌ Most complex to implement correctly
- ❌ Limited to specific data types (sequences, text)
- ❌ Requires both OT and consensus expertise

## Recommended Implementation: CRDT-Based Approach

### Rationale

After analyzing the options, **CRDTs are the recommended approach** for the following reasons:

1. **Preservation of Architecture**: Maintains the reactive, decentralized nature of model_citizen
2. **Partition Tolerance**: Works well with the existing network layer  
3. **Mathematical Guarantees**: Eventual consistency is provable
4. **Performance**: Modern CRDT implementations have excellent performance characteristics
5. **Complexity Management**: While complex, CRDTs are more self-contained than consensus protocols

### Migration Strategy

#### Phase 1: Foundation (Months 1-3)
- Integrate a CRDT library (recommend Diamond-types or Yrs for Nim)
- Implement CRDT wrapper for ZenValue[T] using LWW-Register
- Add vector clock infrastructure  
- Maintain backward compatibility with existing API

#### Phase 2: Core Collections (Months 4-7)  
- Implement CRDT-backed ZenTable using OR-Map
- Implement CRDT-backed ZenSet using OR-Set
- Add delta-state synchronization for network efficiency
- Comprehensive testing with concurrent scenarios

#### Phase 3: Sequences (Months 8-12)
- Implement ZenSeq using RGA or similar sequence CRDT
- This is the most complex phase due to sequence semantics
- May require API changes for optimal CRDT behavior

#### Phase 4: Optimization & Production (Months 13-15)
- Performance tuning and memory optimization
- Production testing and monitoring
- Documentation and migration guides

### API Impact Assessment

**Minimal Breaking Changes**
- Most current operations remain the same
- New APIs for conflict resolution preferences
- Additional metadata in change notifications

**New Features**
```nim
# Conflict resolution options
zen_value.set_merge_policy(LastWriterWins)
zen_table.set_concurrent_behavior(MergeValues)

# Vector clock access
let causality = zen_obj.vector_clock
let is_concurrent = clock1.is_concurrent_with(clock2)

# Enhanced change notifications  
zen_obj.track proc(changes: seq[CrdtChange[T]]) =
  for change in changes:
    if change.is_merge:
      echo "Resolved conflict: ", change.merge_info
```

## Alternative Considerations

### Questions for Decision Making

1. **Performance Requirements**: What latency is acceptable for mutations?
2. **Consistency Needs**: Is eventual consistency sufficient, or do you need strong consistency?
3. **Network Characteristics**: How often do you expect partitions?
4. **Development Timeline**: How much time can be allocated to this redesign?

### If CRDT Approach is Rejected

**Next Best Option: Raft with Batching**
- Implement basic Raft consensus
- Batch operations to reduce latency impact
- Add read replicas for scaling
- Implement async operation submission to maintain responsiveness

**Redis Raft Integration**
The Redis Raft implementation could be integrated via:
- Nim C interop with Redis modules
- Network protocol integration  
- Custom serialization layer

## Conclusion

The CRDT-based approach provides the best balance of consistency guarantees, performance, and compatibility with model_citizen's existing architecture. While implementation is complex, it preserves the core reactive and decentralized design principles that make model_citizen valuable.

The migration should be incremental, starting with simple data types and gradually adding complexity. This allows for learning and iteration while maintaining system stability.

Key success factors:
- Start with thorough CRDT library evaluation
- Invest in comprehensive testing infrastructure
- Plan for gradual rollout with backward compatibility
- Consider performance monitoring from day one

This approach transforms model_citizen from an unsafe but fast reactive system into a mathematically sound, eventually consistent, distributed reactive database suitable for production use.