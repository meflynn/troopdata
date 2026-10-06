# Extracted from test-data-integrity.R:81

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
expect_equal(max(long$troops_ad[long$ccode == 817 & long$year == 1968], na.rm = TRUE), 537377)
expect_equal(max(long$troops_ad[long$ccode == 260 & long$year == 1955], na.rm = TRUE), 269260)
