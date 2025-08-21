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
- **`crdt/`**: CRDT (Conflict-free Replicated Data Types) support with Y-CRDT integration

### Testing Structure
- All tests are in `tests/` directory
- Main test runner: `tests/tests.nim`
- Individual test suites: `basic_tests.nim`, `threading_tests.nim`, `network_tests.nim`, `publish_tests.nim`, `object_tests.nim`, `memory_tests.nim`, `network_threading_tests.nim`, `error_handling_tests.nim`, `utils_tests.nim`, `validation_tests.nim`, `crdt_basic_tests.nim`, `ycrdt_ffi_test.nim`
- Additional files: `object_tests_types.nim` (type definitions for object tests)
- Failing tests directory: `failing/` contains tests for edge cases and failure scenarios
- **Test count**: Currently 75 tests across all suites
- **Testing framework**: Uses `pkg/unittest2` consistently across all test files

## Development Commands

### Running Tests
```bash
nimble test
```
This compiles and runs all test suites. Tests pass successfully (75 tests total).

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
- **CRDT support**: Y-CRDT library with C FFI bindings (libyrs)

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

### CRDT Support (Experimental)
- **Conflict-free Replicated Data Types** for eventual consistency
- Y-CRDT integration via C FFI with automatic binding generation using Futhark
- Vector clock implementation for ordering and causality tracking
- CRDT-enabled reactive objects: `CrdtZenValue`, `CrdtZenTable`, `CrdtZenSeq`, `CrdtZenSet`
- Multiple sync modes: `FastLocal` (immediate local updates) and `WaitForSync` (wait for convergence)
- Sync state tracking: `LocalOnly`, `Syncing`, `Converged`

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

### CRDT Usage (Experimental)
```nim
# Create CRDT-enabled reactive objects
var ctx = ZenContext.init(id = "main")
var crdt_value = CrdtZenValue[int].init(ctx, id = "player_score", mode = FastLocal)

# Track CRDT changes with sync state
crdt_value.track proc(changes: seq[CrdtChange[int]]) =
  for change in changes:
    echo "Value changed to: ", change.new_value
    echo "Sync state: ", change.sync_state

# Track sync state changes
crdt_value.track_sync proc(state: SyncState) =
  echo "Sync state changed to: ", state

# Set value (triggers immediate callback in FastLocal mode)
crdt_value.value = 42

# Switch sync modes
crdt_value.set_sync_mode(WaitForSync)
```

## Coding Conventions

This project follows specific naming conventions that differ from Nim's standard library:

### Naming Style
- **Variables and procedures**: Use `snake_case` exclusively (e.g., `my_variable`, `process_changes`)
- **Types**: Use `UpperCamelCase` (e.g., `ZenContext`, `ChangeKind`)
- **Constants**: Use `snake_case` (e.g., `default_flags`)
- **Fields**: Use `snake_case` (e.g., `object_id`, `type_name`)

### Standard Library Usage
- **IMPORTANT**: When calling Nim standard library functions, always use `snake_case` style
- Use `init_hash_set()` instead of `initHashSet()`
- Use `to_flatty()` instead of `toFlatty()`
- Use `from_flatty()` instead of `fromFlatty()`
- Use `add_int64()` instead of `addInt64()`
- Use `read_int64()` instead of `readInt64()`

### Style Rationale
- While Nim is style-insensitive and the standard library uses `lowerCamelCase`, this project consistently uses `snake_case` for all identifiers
- This applies even when calling standard library functions - always convert to `snake_case`
- Type names follow `UpperCamelCase` to distinguish them from variables and procedures

### Examples
```nim
# Correct style for this project
var my_table = init_table[string, int]()
let serialized_data = my_object.to_flatty()
proc process_user_input(input: string): bool = ...
type UserPreferences = object
  theme_name: string
  font_size: int

# Avoid (even though valid Nim)
var myTable = initTable[string, int]()
let serializedData = myObject.toFlatty()
proc processUserInput(input: string): bool = ...
```

## Custom Language Extensions

This project defines several custom operators and conventions that extend Nim's standard library:

### Custom `?` Operator (Truth Testing)
The project defines a custom `?` operator in `utils/misc.nim` for consistent truth/presence checking across different types:

```nim
# Usage examples
if ?my_ref_object:        # checks if not nil
if ?my_string:            # checks if not empty
if ?my_sequence:          # checks if length > 0
if ?my_set:               # checks if not empty
if ?my_option:            # checks if is_some
if ?my_number:            # checks if != 0
```

**Rule**: Always use `?` instead of manual nil checks, emptiness checks, or is_some calls.

### TypeName.init Convention
All type initializers should follow the `TypeName.init()` pattern where possible:

```nim
# Preferred for project types
var ctx = ZenContext.init(id = "main")
var table = ZenTable[string, int].init(ctx)

# Standard library types use their normal constructors
var std_table = init_table[string, int]()
var hash_set = init_hash_set[string]()
```

**Note**: The project provides helper templates in `utils/misc.nim` for some standard library types to enable uniform `.init()` syntax, but it's not required to create these for every stdlib type.

### Access Control Keywords
The project uses custom access control through special keywords:

- **`privileged`**: Marks procedures that access internal object state
- **`private_access TypeName`**: Grants access to private fields of a type
- **`mutate(op_ctx):`**: Wraps mutation operations with context tracking

```nim
proc my_internal_operation() =
  privileged                    # Indicates this accesses private state
  private_access ZenBase        # Grants access to ZenBase private fields
  mutate(op_ctx):              # Tracks mutations with operation context
    self.internal_field = value
```

### Custom Templates and Patterns

- **`fail(msg)`**: Custom assertion template that raises with a message
- **String interpolation with `\`**: Custom string formatting template
- **`make_discardable()`**: Workaround for template discardability
- **Conditional compilation**: Uses `when defined(zen_trace)`, `when defined(dump_zen_objects)`, etc.

### Method Call Patterns
- Use `.to_flatty()` and `.from_flatty()` for serialization (always snake_case)
- Use `.track()` and `.untrack()` for callback management
- Use `+=` and `-=` operators for collection modifications

## Development Notes

- The codebase uses advanced Nim features like macros, templates, and meta-programming
- Heavy use of `{.gcsafe.}` pragmas for thread safety
- Extensive logging and metrics collection capabilities
- Some deprecation warnings exist (e.g., `newIdentNode` usage)
- Project follows a modular architecture with clear separation of concerns

## CRDT Integration Roadmap

The CRDT support is currently experimental and located in `src/model_citizen/crdt/`. Future integration plans include:

### Current State
- Y-CRDT C library integration via Futhark-generated bindings (`ycrdt_futhark.nim`)
- **COMPLETED**: CRDT support integrated into existing Zen types with `sync_mode` parameter
- Basic CRDT types: `CrdtZenValue`, `CrdtZenTable`, `CrdtZenSeq`, `CrdtZenSet` (legacy, being phased out)
- Vector clock implementation for causality tracking
- Sync modes: `None` (traditional), `FastLocal` (immediate local), `WaitForSync` (convergence-based)
- Test coverage with 11 CRDT-specific tests including integration tests

### Current Integration Features
- **ZenValue CRDT Support**: All Zen.init procedures now accept optional `sync_mode` parameter
- **API Compatibility**: Existing ZenValue usage works unchanged (sync_mode defaults to None)
- **Dual Mode Support**: FastLocal (immediate local updates) and WaitForSync (wait for convergence)
- **Test Coverage**: Full integration testing validates API compatibility and CRDT modes
- **Transparent Usage**: `ZenValue[int].init(sync_mode = FastLocal)` enables CRDT behavior

### Usage Examples

```nim
# Traditional ZenValue (no CRDT)
var regular = ZenValue[int].init(ctx = ctx, id = "regular")
regular.value = 42

# CRDT-enabled ZenValue with FastLocal mode
var crdt_fast = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "fast")
crdt_fast.value = 100  # Immediate local update, syncs in background

# CRDT-enabled ZenValue with WaitForSync mode  
var crdt_wait = ZenValue[int].init(sync_mode = WaitForSync, ctx = ctx, id = "wait")
crdt_wait.value = 200  # Waits for convergence before completing

# All three work with the same API
assert regular.value == 42
assert crdt_fast.value == 100  
assert crdt_wait.value == 200
```

### Future Integration Goals
- Full CRDT backend implementation for FastLocal and WaitForSync modes
- Network synchronization integration with existing netty-based networking
- Performance optimization for CRDT operations
- Deprecation of separate CrdtZen types in favor of integrated approach

### Dependencies
- Y-CRDT library (libyrs) must be available in system library path or `../lib/`
- Futhark for automatic C binding generation
- Requires `-lyrs` linking and appropriate rpath settings

## Helpful Development Information

### Library Linking
The CRDT functionality requires the Y-CRDT library. Test files include:
```nim
{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
```

### Common Issues
- **Library not found**: Ensure libyrs is available in `../lib/` or system paths
- **Vector clock logic**: Uses total event count ordering, not true vector clock semantics
- **Test framework**: All tests use `pkg/unittest2` for consistency

### Build Notes
- Tests compile with some benign linker warnings about duplicate rpath and library paths
- Uses ORC memory management with threading enabled
- Extensive conditional compilation with flags like `zen_trace`, `metrics`, `dump_zen_objects`

## Git Workflow Guidelines

### Branch and PR Workflow
- **Always work in feature branches** - never commit directly to main
- Create descriptive branch names (e.g., `fix-vector-clock-logic`, `add-crdt-support`)
- Use Pull Requests for all changes to main branch
- Keep branches focused on specific features or fixes

### Work Tree Management
- Always stay within the current work tree directory during operations
- If working in a git work tree, fetch and ensure the current branch is up to date with `origin/main` before starting any task
- Work trees allow multiple branches to be checked out simultaneously for parallel development

### Commit Guidelines
- **ALWAYS use single-line commit messages** - no multi-line descriptions, bullet points, or "Generated with Claude Code" messages
- **Simple format**: `Brief description of what was done`
- **Co-Authored-By tag**: Always include when working with AI assistance:
  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

#### Examples
```bash
# Correct
git commit -m "Fix camelCase usage in deps.nim

Co-Authored-By: Claude <noreply@anthropic.com>"

# Avoid - no bullet points, itemized changes, or generated messages
git commit -m "Fix camelCase usage and document coding conventions

- Fix snake_case usage in deps.nim for stdlib functions  
- Add comprehensive coding conventions section to CLAUDE.md
🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```
