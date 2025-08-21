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
        
    test "Basic Y-CRDT map operations":
      let doc = ydoc_new()
      check doc != nil
      
      if doc != nil:
        let map = ymap(doc, "test_map")
        check map != nil
        
        let txn = ydoc_write_transaction(doc)
        check txn != nil
        
        if txn != nil:
          # Test string insertion
          let str_input = yinput_string("Hello Y-CRDT!")
          ymap_insert(map, txn, "greeting", str_input)
          
          # Test number insertion
          let num_input = yinput_long(42)
          ymap_insert(map, txn, "answer", num_input)
          
          ytransaction_commit(txn)
          
          echo "✅ Y-CRDT map operations completed successfully!"
        
        ydoc_destroy(doc)

when is_main_module:
  run()