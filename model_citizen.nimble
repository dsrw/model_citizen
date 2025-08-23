version = "0.19.4"
author = "Scott Wadden"
description = "Nothing for now"
license = "MIT"
src_dir = "src"

requires(
  "nim >= 1.4.8", "https://github.com/treeform/pretty 0.2.0", "threading",
  "chronicles", "flatty", "netty", "supersnappy", "unittest2",
  "https://github.com/dsrw/nanoid.nim 0.2.1", "metrics#51f1227"
  # TODO: "futhark" - temporarily disabled while CRDT is disabled to fix macOS CI
)

task build_ycrdt, "Build Y-CRDT library":
  echo "🚀 Building Y-CRDT library..."
  
  # Check if lib directory exists, create if not
  if not dir_exists("lib"):
    mk_dir("lib")
  
  # Check if library already exists
  when defined(macosx):
    let lib_file = "lib/libyrs.dylib"
  else:
    let lib_file = "lib/libyrs.so"
  
  if file_exists(lib_file):
    echo "✅ Y-CRDT library already exists: " & lib_file
    return
  
  # Check if Rust is installed by trying to run rustc
  try:
    exec "rustc --version"
    echo "✅ Rust toolchain found"
  except:
    echo "❌ Rust not found. Please install Rust first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    quit(1)
  
  # Clone Y-CRDT if not present
  if not dir_exists("y-crdt"):
    echo "📥 Cloning Y-CRDT repository..."
    exec "git clone https://github.com/y-crdt/y-crdt.git"
  else:
    echo "✅ Y-CRDT repository already exists"
  
  # Build the library
  echo "🔨 Building Y-CRDT C FFI library..."
  cd "y-crdt/yffi"
  exec "cargo build --release --features c"
  cd "../.."
  
  # Copy library to lib directory
  when defined(macosx):
    exec "cp y-crdt/yffi/target/release/libyrs.dylib lib/"
    exec "install_name_tool -id @rpath/libyrs.dylib lib/libyrs.dylib"
    echo "✅ libyrs.dylib installed to lib/"
  else:
    exec "cp y-crdt/yffi/target/release/libyrs.so lib/"
    echo "✅ libyrs.so installed to lib/"
  
  # Copy header file
  exec "cp y-crdt/yffi/include/libyrs.h lib/"
  echo "✅ Y-CRDT library build complete!"

task test, "Run tests":
  exec "nimble c -r tests/tests.nim"
