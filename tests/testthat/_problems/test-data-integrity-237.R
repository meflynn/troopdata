# Extracted from test-data-integrity.R:237

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "troopdata", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
long <- troopdata::troopdata_rebuild_long
reports <- troopdata::troopdata_rebuild_reports
expect_equal(unique(long$countryname[long$ccode == 1008]), "Guam")
expect_equal(unique(long$iso3c[long$ccode == 1008]), "GUM")
expect_equal(unique(long$countryname[long$ccode == 1011]), "Northern Mariana Islands")
expect_equal(unique(long$iso3c[long$ccode == 1011]), "MNP")
