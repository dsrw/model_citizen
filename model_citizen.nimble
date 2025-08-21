version = "0.19.4"
author = "Scott Wadden"
description = "Nothing for now"
license = "MIT"
src_dir = "src"

requires(
  "nim >= 1.4.8", "https://github.com/treeform/pretty 0.2.0", "threading",
  "chronicles", "flatty", "netty", "supersnappy", "unittest2",
  "https://github.com/dsrw/nanoid.nim 0.2.1", "metrics#51f1227",
  "futhark"
)

task test, "Run tests":
  exec "nimble c -r tests/tests.nim"
