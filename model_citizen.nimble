# Package

version       = "0.12.1"
author        = "Scott Wadden"
description   = "Nothing for now"
license       = "MIT"
src_dir       = "src"

# Dependencies

requires(
  "nim >= 1.4.8",
  "https://github.com/treeform/pretty",
  "threading",
  "chronicles",
  "flatty",
  "netty",
  "supersnappy",
  "https://github.com/dsrw/nanoid.nim 0.2.1",
)
