# Extracted from test-get_exercises.R:45

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
expect_warning(result <- get_exercises(startyear = 1900, endyear = 2100))
