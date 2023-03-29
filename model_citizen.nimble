# Package

version       = "0.10.5"
author        = "Scott Wadden"
description   = "Nothing for now"
license       = "MIT"
src_dir       = "src"

# Dependencies

requires(
  "nim >= 1.4.8",
  "print#b671140",
  "threading",
  "chronicles",
  "flatty",
  "netty",
  "supersnappy",
  "https://github.com/dsrw/nanoid.nim 0.2.1",
)
