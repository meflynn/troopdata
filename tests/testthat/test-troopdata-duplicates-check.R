# Write a test that checks for duplicate entries in the troopdata dataset
# Use the get_troopdata() function to check country year observations.

library(testthat)

test_that("No duplicate country-year entries in troopdata dataset", {
  data <- troopdata::get_troopdata()

  # Check for duplicates based on country and year
  duplicates <- data[duplicated(data[, c("countryname", "year")]) | duplicated(data[, c("countryname", "year")], fromLast = TRUE), ]

  # Expect no duplicates
  expect_equal(nrow(duplicates), 0, info = "There are duplicate country-year entries in the troopdata dataset.")
})

# Now we do the same thing but for the quarterly data

test_that("No duplicate country-year-quarter entries in troopdata dataset", {
  data <- troopdata::get_troopdata(quarters = TRUE)

  # Check for duplicates based on country, year, and quarter
  duplicates <- data[duplicated(data[, c("countryname", "year", "quarter")]) | duplicated(data[, c("countryname", "year", "quarter")], fromLast = TRUE), ]

  # Expect no duplicates
  expect_equal(nrow(duplicates), 0, info = "There are duplicate country-year-quarter entries in the troopdata quarterly dataset.")
})
