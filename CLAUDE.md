# model_citizen - Data Model Library for Nim

`model_citizen` is a data model library written in Nim that provides thread-safe and network-synchronized data structures with reactive programming capabilities. It's designed to sync data across threads and the network while allowing components to react to changes.

## Project Overview

This library provides "Zen" objects - reactive data containers that can:
- Sync data across multiple threads
- Sync data across network connections
- Track changes and notify subscribers
- Handle complex nested data structures
- Provide automatic serialization/deserialization

## Key Architecture Components

### Core Types (`src/model_citizen/types.nim`)
- **ZenContext**: Central coordination object managing object lifecycle, subscriptions, and message passing
- **ZenBase**: Base class for all reactive objects
- **Zen[T, O]**: Generic reactive container for type T with change objects of type O
- **ZenTable[K, V]**, **ZenSeq[T]**, **ZenSet[T]**, **ZenValue[T]**: Specialized reactive collections
- **Change[O]**: Represents modifications to objects with change tracking
- **Subscription**: Manages local/remote connections for data synchronization

### Key Modules
- **`zens/`**: Core reactive object operations, contexts, initializers, validations
- **`components/`**: Subscription management and type registry
- **`utils/`**: Logging, statistics, type IDs, and miscellaneous utilities

### Testing Structure
- All tests are in `tests/` directory
- Main test runner: `tests/tests.nim`
- Individual test suites: `basic_tests.nim`, `threading_tests.nim`, `network_tests.nim`, `publish_tests.nim`, `object_tests.nim`

## Development Commands

### Running Tests
```bash
nimble test
```
This compiles and runs all test suites. Tests pass successfully with some warnings about unused imports.

### Build Configuration
- Uses Nim config in `tests/config.nims` with:
  - ORC memory management (`--mm:orc`)
  - Threading enabled (`--threads:on`)
  - Various debugging flags including `zen_trace` and `metrics`
  - Chronicles logging enabled

### Dependencies
Key dependencies from `model_citizen.nimble`:
- `nim >= 1.4.8`
- `pretty`, `threading`, `chronicles`, `flatty`, `netty`, `supersnappy`
- `nanoid.nim`, `metrics`

## Key Features

### Thread Safety
- Built on Nim's threading system with channels for message passing
- Thread-safe reactive objects that can be shared across threads
- Automatic synchronization of changes between thread contexts

### Network Synchronization
- Objects can sync across network connections using netty
- Remote subscriptions allow distributed reactive programming
- Automatic serialization/deserialization with flatty

### Change Tracking
- Detailed change notifications with `ChangeKind` (Created, Added, Removed, Modified, Touched, Closed)
- Reactive callbacks triggered on data modifications
- Change propagation through object hierarchies

### Memory Management
- Reference counting with `CountedRef` for shared objects
- Automatic cleanup of unused references
- Object lifecycle management through ZenContext

## Usage Patterns

### Basic Usage
```nim
# Create a context
var ctx = ZenContext.init(id = "main")

# Create reactive objects
var zen_table = ZenTable[string, int].init(ctx)
var zen_seq = ZenSeq[string].init(ctx)

# Track changes
zen_table.track proc(changes: seq[Change[Pair[string, int]]]) =
  echo "Table changed: ", changes

# Modify data (triggers callbacks)
zen_table["key"] = 42
```

### Cross-Thread Synchronization
```nim
# Set up contexts in different threads
var ctx1 = ZenContext.init(id = "thread1")
var ctx2 = ZenContext.init(id = "thread2")

# Subscribe for sync
ctx2.subscribe(ctx1)

# Changes in ctx1 objects automatically sync to ctx2
```

## Development Notes

- The codebase uses advanced Nim features like macros, templates, and meta-programming
- Heavy use of `{.gcsafe.}` pragmas for thread safety
- Extensive logging and metrics collection capabilities
- Some deprecation warnings exist (e.g., `newIdentNode` usage)
- Project follows a modular architecture with clear separation of concerns
