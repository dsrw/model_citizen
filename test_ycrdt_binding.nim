import src/model_citizen/crdt/ycrdt_futhark

when defined(generate_ycrdt_binding):
  echo "Generating Y-CRDT binding..."
else:
  echo "Using existing Y-CRDT binding"

when is_main_module:
  echo "Y-CRDT binding test"