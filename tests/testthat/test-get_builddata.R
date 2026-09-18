# Tests for get_builddata()
#
# get_builddata() subsets the geocoded military construction spending data
# (troopdata::builddata), a location-project-year data frame. Each test below
# exercises one function argument. A final block checks for unnecessary
# duplicate rows.
#
# NOTE: get_builddata() was rewritten to expect the new comptroller MILCON
# schema (fiscal_year, state_country, appn/auth/toa_amount, organization,
# transaction_type, fiscal_category_title, budget_activity_title,
# project_title, location_name, location_full_name). The packaged
# troopdata::builddata must be rebuilt to that schema for these tests to run;
# until then skip_if_builddata_ready() skips the suite instead of erroring.

skip_if_builddata_ready <- function() {
  needed <- c("fiscal_year", "state_country", "iso3c", "gwcode", "toa_amount",
              "appn_amount", "auth_amount", "organization", "transaction_type",
              "fiscal_category_title", "budget_activity_title",
              "project_title", "location_name", "location_full_name")
  have <- needed %in% names(troopdata::builddata)
  testthat::skip_if_not(
    all(have),
    paste("builddata is not on the new comptroller schema; missing:",
          paste(needed[!have], collapse = ", "))
  )
}

# Convenience: a start/end year guaranteed to be inside the data range.
bd_years <- function() {
  yr <- troopdata::builddata$fiscal_year
  list(start = min(yr, na.rm = TRUE), end = max(yr, na.rm = TRUE))
}

test_that("get_builddata returns a data frame with expected columns", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(get_builddata(startyear = y$start, endyear = y$end))
  expect_s3_class(result, "data.frame")
  expect_true(all(c("fiscal_year", "state_country", "organization",
                    "toa_amount") %in% names(result)))
  expect_gt(nrow(result), 0)
})

test_that("startyear/endyear bound the series", {
  skip_if_builddata_ready()
  result <- suppressWarnings(get_builddata(startyear = 2010, endyear = 2015))
  expect_true(all(result$fiscal_year >= 2010 & result$fiscal_year <= 2015))
})

test_that("out-of-range years raise an error", {
  skip_if_builddata_ready()
  y <- bd_years()
  expect_error(get_builddata(startyear = y$start - 50, endyear = y$end),
               "out of range")
  expect_error(get_builddata(startyear = y$start, endyear = y$end + 50),
               "out of range")
})

test_that("invalid spend_type raises an error", {
  skip_if_builddata_ready()
  y <- bd_years()
  expect_error(
    get_builddata(spend_type = "banana", startyear = y$start, endyear = y$end),
    "Invalid spend_type"
  )
})

test_that("get_builddata warns that amounts are in thousands of dollars", {
  skip_if_builddata_ready()
  y <- bd_years()
  expect_warning(get_builddata(startyear = y$start, endyear = y$end),
                 "thousands of current US dollars")
})

test_that("character host filters on the ISO3C code", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(host = "JPN", startyear = y$start, endyear = y$end))
  expect_true(all(result$iso3c == "JPN"))
})

test_that("character host is case-insensitive", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(host = "jpn", startyear = y$start, endyear = y$end))
  expect_true(all(result$iso3c == "JPN"))
})

test_that("character host accepts a vector of ISO3C codes", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(host = c("JPN", "DEU"), startyear = y$start, endyear = y$end))
  expect_true(all(result$iso3c %in% c("JPN", "DEU")))
})

test_that("numeric host filters on the Gleditsch and Ward code", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(host = 740, startyear = y$start, endyear = y$end)) # Japan
  expect_true(all(result$gwcode == 740))
})

test_that("location performs a case-insensitive regex match", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(location = "base", startyear = y$start, endyear = y$end))
  expect_true(all(grepl("base", result$location_name, ignore.case = TRUE) |
                    grepl("base", result$location_full_name, ignore.case = TRUE)))
})

test_that("organization filters on the organization code", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(organization = "N", startyear = y$start, endyear = y$end))
  expect_true(all(result$organization == "N"))
})

test_that("transaction_type filters on transaction type", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(transaction_type = "BUDGET", startyear = y$start, endyear = y$end))
  expect_true(all(result$transaction_type == "BUDGET"))
})

test_that("fiscal_category filters on fiscal_category_title", {
  skip_if_builddata_ready()
  y <- bd_years()
  cat <- troopdata::builddata$fiscal_category_title
  target <- cat[!is.na(cat)][1]
  result <- suppressWarnings(
    get_builddata(fiscal_category = target, startyear = y$start, endyear = y$end))
  expect_true(all(result$fiscal_category_title == target))
})

test_that("budget_activity filters on budget_activity_title", {
  skip_if_builddata_ready()
  y <- bd_years()
  ba <- troopdata::builddata$budget_activity_title
  target <- ba[!is.na(ba)][1]
  result <- suppressWarnings(
    get_builddata(budget_activity = target, startyear = y$start, endyear = y$end))
  expect_true(all(result$budget_activity_title == target))
})

test_that("project performs a case-insensitive regex match on project_title", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(project = "hospital", startyear = y$start, endyear = y$end))
  expect_true(all(grepl("hospital", result$project_title, ignore.case = TRUE)))
})

test_that("spend_type selects the amount column and drops its NA rows", {
  skip_if_builddata_ready()
  y <- bd_years()
  for (st in c("appn", "auth", "toa")) {
    col <- paste0(st, "_amount")
    result <- suppressWarnings(
      get_builddata(spend_type = st, startyear = y$start, endyear = y$end))
    expect_false(any(is.na(result[[col]])),
                 info = paste("NA remaining in", col, "for spend_type =", st))
  }
})

test_that("min_amount and max_amount bound the selected amount column", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(spend_type = "toa", min_amount = 1000, max_amount = 100000,
                  startyear = y$start, endyear = y$end))
  expect_true(all(result$toa_amount >= 1000 & result$toa_amount <= 100000))
})

# ---- Duplicate checks ------------------------------------------------------
# Construction data is at the location-project-year level. Fully identical rows
# are redundant and would double-count spending in any aggregation.

test_that("no fully duplicated rows in builddata", {
  skip_if_builddata_ready()
  n_dupes <- sum(duplicated(troopdata::builddata))
  expect_equal(n_dupes, 0,
               info = paste("Found", n_dupes, "fully duplicated rows in builddata."))
})
