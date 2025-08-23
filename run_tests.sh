#!/bin/bash

# Test runner script that sets up proper library paths for Y-CRDT
# This solves the rpath issues by setting DYLD_LIBRARY_PATH

set -e

echo "🧪 Running model_citizen tests with Y-CRDT support..."

# Get absolute path to lib directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="$SCRIPT_DIR/lib"

# Set library path for macOS
export DYLD_LIBRARY_PATH="$LIB_DIR:$DYLD_LIBRARY_PATH"

# Set library path for Linux (just in case)
export LD_LIBRARY_PATH="$LIB_DIR:$LD_LIBRARY_PATH"

echo "📚 Library path set to: $LIB_DIR"

# Function to run a single test with proper environment
run_test() {
    local test_name="$1"
    local test_path="$2"
    
    echo "🔍 Running $test_name..."
    
    if [ -f "$test_path" ]; then
        if "$test_path"; then
            echo "✅ $test_name passed"
        else
            echo "❌ $test_name failed"
            return 1
        fi
    else
        echo "⚠️  $test_name executable not found at $test_path"
        return 1
    fi
}

# Check if nimble is available and run tests
if command -v nimble &> /dev/null; then
    echo "🔨 Compiling tests with nimble..."
    nimble test
else
    echo "🔨 Compiling and running tests manually..."
    
    # Compile and run CRDT-specific tests
    echo "🔨 Compiling CRDT tests..."
    
    # CRDT Basic Tests
    if [ ! -f "tests/crdt_basic_tests" ] || [ "tests/crdt_basic_tests.nim" -nt "tests/crdt_basic_tests" ]; then
        nim c --threads:on tests/crdt_basic_tests.nim
    fi
    
    # CRDT Multi-Context Sync Tests
    if [ ! -f "tests/crdt_multi_context_sync_test" ] || [ "tests/crdt_multi_context_sync_test.nim" -nt "tests/crdt_multi_context_sync_test" ]; then
        nim c --threads:on tests/crdt_multi_context_sync_test.nim
    fi
    
    # Run the tests
    echo ""
    echo "🧪 Running CRDT tests..."
    
    run_test "CRDT Basic Tests" "tests/crdt_basic_tests"
    run_test "CRDT Multi-Context Sync Tests" "tests/crdt_multi_context_sync_test"
    
    # Try to run other CRDT tests if they exist
    for test_file in tests/*crdt*.nim; do
        if [ -f "$test_file" ]; then
            test_name=$(basename "$test_file" .nim)
            test_executable="tests/$test_name"
            
            # Skip if we already ran it above
            if [[ "$test_name" != "crdt_basic_tests" && "$test_name" != "crdt_multi_context_sync_test" ]]; then
                if [ ! -f "$test_executable" ] || [ "$test_file" -nt "$test_executable" ]; then
                    echo "🔨 Compiling $test_name..."
                    nim c --threads:on "$test_file"
                fi
                
                if [ -f "$test_executable" ]; then
                    run_test "$test_name" "$test_executable"
                fi
            fi
        fi
    done
fi

echo ""
echo "✅ Test run completed!"
echo ""
echo "💡 To run tests manually with proper library paths:"
echo "   export DYLD_LIBRARY_PATH=$LIB_DIR:\$DYLD_LIBRARY_PATH"
echo "   ./tests/your_test_executable"