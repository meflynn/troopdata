# Extracted from test-data-integrity.R:69

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
names.per.ccode.year <- long %>%
    dplyr::distinct(ccode, year, countryname) %>%
    dplyr::count(ccode, year) %>%
    dplyr::filter(n > 1)
iso.per.ccode <- long %>%
    dplyr::filter(!is.na(iso3c)) %>%
    dplyr::distinct(ccode, iso3c) %>%
    dplyr::count(ccode) %>%
    dplyr::filter(n > 1)
ccode.per.name <- long %>%
    dplyr::distinct(countryname, ccode) %>%
    dplyr::count(countryname) %>%
    dplyr::filter(n > 1)
expect_equal(nrow(names.per.ccode.year), 0)
expect_equal(nrow(iso.per.ccode), 0)
expect_equal(nrow(ccode.per.name), 0)
