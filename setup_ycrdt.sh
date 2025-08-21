#!/bin/bash

# Y-CRDT Setup Script for model_citizen
# This script downloads and builds Y-CRDT for macOS ARM64

set -e

echo "🚀 Setting up Y-CRDT for model_citizen..."

# Check platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "Platform: $PLATFORM $ARCH"

# Install Rust if not present
if ! command -v rustc &> /dev/null; then
    echo "📦 Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
else
    echo "✅ Rust already installed"
fi

# Create lib directory if it doesn't exist
mkdir -p lib

# Clone Y-CRDT if not already present
if [ ! -d "y-crdt" ]; then
    echo "📥 Cloning Y-CRDT repository..."
    git clone https://github.com/y-crdt/y-crdt.git
else
    echo "✅ Y-CRDT repository already exists"
    cd y-crdt
    git pull origin main
    cd ..
fi

cd y-crdt

# Build the C FFI library
echo "🔨 Building Y-CRDT C FFI library..."
cd yffi
cargo build --release --features c

# Copy the built library to our lib directory
echo "📋 Copying library to model_citizen/lib..."
if [ "$PLATFORM" = "Darwin" ]; then
    LIB_NAME="libyrs.dylib"
    cp target/release/$LIB_NAME ../../lib/
    
    # Update the library ID for proper loading
    install_name_tool -id "@rpath/$LIB_NAME" ../../lib/$LIB_NAME
    
    echo "✅ $LIB_NAME installed to lib/"
elif [ "$PLATFORM" = "Linux" ]; then
    LIB_NAME="libyrs.so"
    cp target/release/$LIB_NAME ../../lib/
    echo "✅ $LIB_NAME installed to lib/"
else
    echo "❌ Unsupported platform: $PLATFORM"
    exit 1
fi

cd ../..

# Copy header file
echo "📋 Copying header file..."
cp y-crdt/yffi/include/libyrs.h lib/

# Test the library
echo "🧪 Testing Y-CRDT library..."
cd lib

# Create a simple test program
cat > test_ycrdt.c << 'EOF'
#include <stdio.h>
#include "libyrs.h"

int main() {
    printf("Testing Y-CRDT library...\n");
    
    // Create a new document
    YDoc* doc = ydoc_new();
    if (doc) {
        printf("✅ Y-CRDT library loaded successfully!\n");
        ydoc_destroy(doc);
        return 0;
    } else {
        printf("❌ Failed to create Y-CRDT document\n");
        return 1;
    }
}
EOF

# Compile and run test
if [ "$PLATFORM" = "Darwin" ]; then
    gcc -o test_ycrdt test_ycrdt.c -L. -lyrs -Wl,-rpath,.
else
    gcc -o test_ycrdt test_ycrdt.c -L. -lyrs -Wl,-rpath,.
fi

if ./test_ycrdt; then
    echo "🎉 Y-CRDT setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. The library is installed in lib/$LIB_NAME"
    echo "2. Header file is in lib/libyrs.h"
    echo "3. Run 'nimble c -d:with_ycrdt tests/crdt_basic_tests.nim' to test with Y-CRDT"
    echo "4. Set the LD_LIBRARY_PATH (Linux) or DYLD_LIBRARY_PATH (macOS) to include $(pwd)"
else
    echo "❌ Y-CRDT test failed"
    exit 1
fi

# Cleanup
rm test_ycrdt test_ycrdt.c

cd ..

echo "✅ Y-CRDT setup complete!"