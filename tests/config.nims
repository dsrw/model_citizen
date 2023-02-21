--mm:orc
--threads:on
--define:nimPreviewHashRef
--define:nimTypeNames
--define:"chronicles_enabled=on"
--define:"chronicles_sinks=textblocks[stdout]"
--define:"chronicles_log_level=INFO"
--define:"zen_trace"

switch("path", "$projectDir/../src")
