# Extracted from test-get_exercises.R:134

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
mismatched <- troopdata::mme_long |>
    dplyr::summarise(n_rows = dplyr::n(),
                     participant_count = dplyr::first(participant_count),
                     .by = MMEID) |>
    dplyr::filter(n_rows != participant_count)
