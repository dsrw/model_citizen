{.passL: "-L../lib -lyrs -Wl,-rpath,../lib".}
import
  model_citizen, basic_tests, threading_tests, network_tests, publish_tests,
  object_tests, utils_tests, validation_tests, error_handling_tests, memory_tests,
  crdt_basic_tests, network_threading_tests, ycrdt_ffi_test, zen_value_crdt_integration_test,
  simple_crdt_test, crdt_sync_demo, multi_context_crdt_sync_test, actual_sync_test

Zen.bootstrap

basic_tests.run()
threading_tests.run()
network_tests.run()
publish_tests.run()
object_tests.run()
utils_tests.run()
validation_tests.run()
error_handling_tests.run()
memory_tests.run()
crdt_basic_tests.run()
network_threading_tests.run()
ycrdt_ffi_test.run()
zen_value_crdt_integration_test.run()
simple_crdt_test.run()
crdt_sync_demo.run()
multi_context_crdt_sync_test.run()
actual_sync_test.run()
