# Extracted from test-data-integrity.R:125

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
expect_equal(nrow(long[long$ccode == 345 & long$year > 2006, ]), 0)
