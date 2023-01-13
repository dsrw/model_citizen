--mm:orc
--threads:on
--define:nimPreviewHashRef
--deepcopy:on
--define:nimTypeNames
--define:"chronicles_enabled=on"
--define:"chronicles_sinks=textblocks[stdout]"
--define:"chronicles_log_level=INFO"

switch("path", "$projectDir/../src")
