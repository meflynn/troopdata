# Extracted from test-data-integrity.R:139

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
expected <- c("58" = "ATG", "60" = "KNA", "403" = "STP", "591" = "SYC",
                "816" = "VNM", "972" = "TON", "987" = "FSM")
for (code in names(expected)) {
    observed <- unique(long$iso3c[long$ccode == as.numeric(code)])
    expect_equal(observed, unname(expected[code]))
  }
