# Extracted from test-data-integrity.R:209

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
gap <- long %>%
    dplyr::filter((year == 2022 & quarter == 4) | (year == 2023 & quarter %in% c(1, 2)))
filled <- gap %>%
    dplyr::filter(ccode %in% c(260, 740, 732))
expect_equal(nrow(filled), 9)
