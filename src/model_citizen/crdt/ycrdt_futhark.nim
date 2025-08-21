when defined(generate_ycrdt_binding):
  import std/strformat
  import std/[os, strutils, sequtils]
  import futhark

  proc rename_symbol(
      n: string, k: SymbolKind, p: string, overloading: var bool
  ): string =
    result = n
    if k in [Typedef, Enum, Struct, Anon]:
      result = n.split("_").map_it(it.capitalize_ascii()).join("")

  const
    lib_dir = current_source_path.parent_dir / ".." / ".." / ".." / "lib"
    sys_path =
      "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/"
    output_path =
      current_source_path.parent_dir / "generated" / "ycrdt_binding.nim"

  importc:
    # futhark symbols must be camelCase
    renameCallback rename_symbol
    sysPath sys_path
    path lib_dir
    outputPath output_path
    "libyrs.h"
else:
  import generated/ycrdt_binding
  export ycrdt_binding