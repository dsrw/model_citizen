{.passL: "-Llib -lyrs -Wl,-rpath,./lib".}
import
  model_citizen, basic_tests, ycrdt_ffi_test, zen_value_crdt_integration_test,
  simple_crdt_test, crdt_sync_demo, multi_context_crdt_sync_test, actual_sync_test

Zen.bootstrap

# Run essential tests to verify CRDT integration
basic_tests.run()
ycrdt_ffi_test.run()
zen_value_crdt_integration_test.run()
simple_crdt_test.run()
crdt_sync_demo.run()
multi_context_crdt_sync_test.run()
actual_sync_test.run()