# Extracted from test-data-integrity.R:34

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
branches <- c("army_ad", "navy_ad", "air_force_ad",
                "marine_corps_ad", "coast_guard_ad", "space_force_ad")
reports <- troopdata::troopdata_rebuild_reports %>%
    dplyr::mutate(
      ccode = dplyr::if_else(ccode == 1009 & year >= 1997, 710, ccode),
      branch_sum = rowSums(dplyr::across(tidyselect::any_of(branches)), na.rm = TRUE)) %>%
    dplyr::group_by(ccode, year, month) %>%
    dplyr::summarise(reported = sum(troops_ad, na.rm = TRUE),
                     branch_sum = sum(branch_sum, na.rm = TRUE),
                     .groups = "drop") %>%
    dplyr::mutate(baseline = pmax(reported, branch_sum, na.rm = TRUE))
checked <- long %>%
    dplyr::inner_join(reports, by = c("ccode", "year", "month")) %>%
    dplyr::filter(baseline > 0, troops_ad > baseline * 1.05)
expect_equal(nrow(checked), 0)
