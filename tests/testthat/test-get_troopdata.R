# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html
test_that("get_troopdata returns a data frame with expected columns", {
  result <- get_troopdata()
  expect_s3_class(result, "data.frame")
  expect_true("countryname" %in% names(result))
  expect_true("ccode" %in% names(result))
  expect_true("troops_ad" %in% names(result))
})

test_that("get_troopdata filters by year correctly", {
  result <- get_troopdata()
  expect_true(all(result$year >= 1950 & result$year <= 2025))
})

test_that("get_troopdata filters by host country", {
  result <- get_troopdata(host = 255, startyear = 1950, endyear = 2025)
  expect_true(all(result$ccode == 255))
})

test_that("branch argument adds service-specific columns", {
  result <- get_troopdata(host = 255, branch = TRUE,
                          startyear = 2000, endyear = 2001)
  expect_true("army_ad" %in% names(result))
})

test_that("get_troopdata accepts ISO3C character host codes", {
  result <- get_troopdata(host = "DEU", startyear = 2000, endyear = 2001)
  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
})

test_that("no duplicate countryname-year observations", {
  result <- get_troopdata()
  dupes <- result |>
    dplyr::count(countryname, year) |>
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0,
               info = paste("Duplicate countryname-year pairs found:",
                            paste(dupes$countryname, dupes$year,
                                  collapse = ", ")))
})

test_that("no duplicate ccode-year observations", {
  result <- get_troopdata(startyear = 1950, endyear = 2024)
  dupes <- result |>
    dplyr::count(ccode, year) |>
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0,
               info = paste("Duplicate ccode-year pairs found:",
                            paste(dupes$ccode, dupes$year,
                                  collapse = ", ")))
})
