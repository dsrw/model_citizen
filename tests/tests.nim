import model_citizen, basic_tests, threading_tests, network_tests, publish_tests
Zen.bootstrap

basic_tests.run()
threading_tests.run()
network_tests.run()
publish_tests.run()
