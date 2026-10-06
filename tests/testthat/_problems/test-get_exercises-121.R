# Extracted from test-get_exercises.R:121

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
by_ex <- troopdata::mme_long |>
    dplyr::summarise(n_pc = dplyr::n_distinct(participant_count),
                     .by = MMEID)
