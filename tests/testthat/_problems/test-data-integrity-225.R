# Extracted from test-data-integrity.R:225

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
branches <- c("army_ad", "navy_ad", "air_force_ad",
                "marine_corps_ad", "coast_guard_ad", "space_force_ad")
checked <- long %>%
    dplyr::mutate(branch_sum = rowSums(dplyr::across(tidyselect::all_of(branches)), na.rm = TRUE)) %>%
    dplyr::filter(!is.na(troops_ad), troops_ad < branch_sum - 0.5)
expect_equal(nrow(checked), 0)
