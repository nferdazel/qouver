# Vendor mummy 0.4.8 with the overlapping copyMem -> moveMem fix.
# Same resolution rule as `./task` (which passes -p:vendor/mummy to every nim
# invocation): the vendored source wins over the nimble package.
switch("path", "vendor/mummy")
