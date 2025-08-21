{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
import pkg/unittest2
import model_citizen/crdt/ycrdt_futhark

proc run*() =
  suite "Y-CRDT FFI Test":
    test "Basic Y-CRDT library loading":
      # Test that we can load the library and create a document
      let doc = ydoc_new()
      check doc != nil
      
      if doc != nil:
        ydoc_destroy(doc)
        
    test "Basic Y-CRDT input creation":
      # Test just creating YInput without any other operations
      try:
        var input = yinput_string("Hello Y-CRDT!".cstring)
        check input.tag != 0
        check input.len > 0
      except CatchableError as e:
        check false
        
    test "Basic Y-CRDT map operations":
      let doc = ydoc_new()
      check doc != nil
      
      if doc != nil:
        let map = ymap(doc, "test_map")
        check map != nil
        
        let txn = ydoc_write_transaction_simple(doc)
        check txn != nil
        
        if txn != nil:
          try:
            var input = yinput_string("Hello Y-CRDT!".cstring)
            ymap_insert(map, txn, "greeting".cstring, addr input)
          except CatchableError as e:
            check false
            
          ytransaction_commit(txn)
        
        ydoc_destroy(doc)

when is_main_module:
  run()