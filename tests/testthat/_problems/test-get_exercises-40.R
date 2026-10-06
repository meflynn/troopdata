# Extracted from test-get_exercises.R:40

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
result <- get_exercises(startyear = 2000, endyear = 2005)
