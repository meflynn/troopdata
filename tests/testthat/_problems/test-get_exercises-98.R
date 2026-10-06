# Extracted from test-get_exercises.R:98

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
result <- get_exercises(min_participants = 5, max_participants = 20)
