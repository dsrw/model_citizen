import std/[unittest]
import model_citizen/crdt/ycrdt_bindings

proc run*() =
  suite "Y-CRDT FFI Test":
    test "Basic Y-CRDT library loading":
      # Test that we can load the library and create a document
      let doc = ydoc_new()
      check doc != nil
      
      if doc != nil:
        echo "✅ Y-CRDT document created successfully!"
        ydoc_destroy(doc)
      else:
        echo "❌ Failed to create Y-CRDT document"
        
    test "Basic Y-CRDT input creation":
      # Test just creating YInput without any other operations
      try:
        echo "Testing yinput_string..."
        var input = yinput_string("Hello Y-CRDT!".cstring)
        echo "✅ yinput_string successful!"
        echo "Input tag: ", input.tag
        echo "Input len: ", input.len
      except CatchableError as e:
        echo "❌ yinput_string failed: ", e.msg
        
    test "Basic Y-CRDT map operations":
      let doc = ydoc_new()
      check doc != nil
      
      if doc != nil:
        echo "Created Y-CRDT document"
        
        let map = ymap(doc, "test_map")
        check map != nil
        echo "Created Y-CRDT map"
        
        let txn = ydoc_write_transaction(doc)
        check txn != nil
        echo "Created write transaction"
        
        if txn != nil:
          echo "About to test string insertion..."
          
          # Test just one operation first - call directly
          try:
            echo "Calling yinput_string..."
            var input = yinput_string("Hello Y-CRDT!".cstring)
            echo "Created YInput successfully"
            echo "Calling ymap_insert..."
            ymap_insert(map, txn, "greeting".cstring, addr input)
            echo "✅ String insertion successful!"
          except CatchableError as e:
            echo "❌ String insertion failed: ", e.msg
            
          ytransaction_commit(txn)
          echo "Transaction committed"
        
        ydoc_destroy(doc)
        echo "Document destroyed"

when is_main_module:
  run()