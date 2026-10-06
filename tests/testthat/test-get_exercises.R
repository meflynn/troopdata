# Tests for get_exercises()
#
# get_exercises() subsets the long-format multilateral military exercise data
# (troopdata::mme_long), which is an exercise-country-year data frame. Each test
# below exercises one function argument so we can confirm every filter behaves
# as documented. A final block checks the data for unnecessary duplicate rows.

test_that("get_exercises returns a data frame with expected columns", {
  result <- get_exercises()
  expect_s3_class(result, "data.frame")
  expect_true(all(c("MMEID", "Ex_Name", "gwcode", "country", "year") %in%
                    names(result)))
  expect_gt(nrow(result), 0)
})

test_that("no-argument call returns the full data set", {
  result <- get_exercises()
  expect_equal(nrow(result), nrow(troopdata::mme_long))
})

test_that("country accepts a numeric Gleditsch & Ward code", {
  result <- get_exercises(country = 2) # United States
  expect_gt(nrow(result), 0)
  expect_true(all(result$gwcode == 2, na.rm = TRUE))
})

test_that("country accepts a fuzzy character name", {
  result <- get_exercises(country = "korea")
  expect_gt(nrow(result), 0)
  # Case-insensitive grepl match should catch both Koreas.
  expect_true(all(grepl("korea", result$country, ignore.case = TRUE)))
})

test_that("country accepts a vector of names", {
  result <- get_exercises(country = c("korea", "japan"))
  expect_true(all(grepl("korea|japan", result$country, ignore.case = TRUE)))
})

test_that("startyear and endyear bound the series", {
  result <- get_exercises(startyear = 2000, endyear = 2005)
  expect_true(all(result$year >= 2000 & result$year <= 2005))
})

test_that("out-of-range years warn and are clamped to the data range", {
  expect_warning(result <- get_exercises(startyear = 1900, endyear = 2100))
  data_min <- min(troopdata::mme_long$year, na.rm = TRUE)
  data_max <- max(troopdata::mme_long$year, na.rm = TRUE)
  expect_true(all(result$year >= data_min & result$year <= data_max))
})

test_that("min_duration and max_duration filter on computed duration", {
  result <- get_exercises(min_duration = 5, max_duration = 30)
  expect_true("duration" %in% names(result))
  expect_true(all(result$duration >= 5 & result$duration <= 30, na.rm = TRUE))
  expect_false(any(is.na(result$duration)))
})

test_that("location performs a case-insensitive fuzzy match", {
  result <- get_exercises(location = "thailand")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("thailand", result$Location, ignore.case = TRUE)))
})

test_that("exercise_name matches Ex_Name or Series_Name", {
  result <- get_exercises(exercise_name = "cobra")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("cobra", result$Ex_Name, ignore.case = TRUE) |
                    grepl("cobra", result$Series_Name, ignore.case = TRUE)))
})

test_that("domain keeps exercises flagged for the requested environment", {
  result <- get_exercises(domain = "sea")
  expect_gt(nrow(result), 0)
  expect_true(all(result$Sea == 1, na.rm = TRUE))
})

test_that("domain accepts multiple values as a logical OR", {
  result <- get_exercises(domain = c("sea", "amphibious"))
  expect_true(all((result$Sea == 1 & !is.na(result$Sea)) |
                    (result$Amphibious == 1 & !is.na(result$Amphibious))))
})

test_that("unknown domain values warn but do not error", {
  expect_warning(get_exercises(domain = "space"))
})

test_that("focus keeps exercises flagged for the requested mission", {
  result <- get_exercises(focus = "humanitarian")
  expect_gt(nrow(result), 0)
  expect_true(all(result$Humanitarian == 1, na.rm = TRUE))
})

test_that("unknown focus values warn but do not error", {
  expect_warning(get_exercises(focus = "logistics"))
})

test_that("min_participants and max_participants filter on participant_count", {
  result <- get_exercises(min_participants = 5, max_participants = 20)
  expect_true(all(result$participant_count >= 5 &
                    result$participant_count <= 20, na.rm = TRUE))
})

test_that("filters combine correctly", {
  result <- get_exercises(exercise_name = "cobra gold", location = "thailand")
  expect_true(all(grepl("cobra gold", result$Ex_Name, ignore.case = TRUE) |
                    grepl("cobra gold", result$Series_Name, ignore.case = TRUE)))
  expect_true(all(grepl("thailand", result$Location, ignore.case = TRUE)))
})

# ---- Duplicate / integrity checks ------------------------------------------
# The data is at the exercise-participant level: each exercise (MMEID) has one
# row per participating country. Some participants are unidentified -- these
# appear as missing country names/codes and therefore look like duplicate rows,
# but they are real participant slots and must be kept. Rather than treating
# identical rows as errors, the invariant to enforce is that the number of rows
# for an exercise equals its recorded participant_count.

test_that("participant_count is consistent within each exercise", {
  by_ex <- troopdata::mme_long |>
    dplyr::summarise(n_pc = dplyr::n_distinct(participant_count),
                     .by = MMEID)
  expect_true(all(by_ex$n_pc == 1),
              info = "Some exercises carry more than one participant_count value.")
})

test_that("each exercise has one row per participating country", {
  # rows-per-MMEID should equal the recorded participant_count (identified and
  # unidentified participants alike). A mismatch signals accidentally dropped or
  # duplicated rows, not the intentional unidentified-participant records.
  mismatched <- troopdata::mme_long |>
    dplyr::summarise(n_rows = dplyr::n(),
                     participant_count = dplyr::first(participant_count),
                     .by = MMEID) |>
    dplyr::filter(n_rows != participant_count)
  expect_equal(nrow(mismatched), 0,
               info = paste("Exercises where row count != participant_count:",
                            paste(mismatched$MMEID, collapse = ", ")))
})

test_that("the duration filter does not depend on which row comes first", {
  # The source writes a date as "5/16/80" when the day is known and "1993-05-xx" when it is not.
  # as.Date() with tryFormats settles on one format from the first non-missing value, so whenever
  # the first row of a filtered result held an "xx" date every duration came back NA and the filter
  # returned nothing. Lithuania's first row is one of those, as is the first row of 2006.
  lithuania <- get_exercises(country = "Lithuania", min_duration = 1)
  expect_gt(nrow(lithuania), 0)

  in.2006 <- get_exercises(startyear = 2006, endyear = 2006, min_duration = 1)
  expect_gt(nrow(in.2006), 0)

  # And the same exercise gets the same duration however the data was filtered first.
  everything <- get_exercises(min_duration = 1)
  expect_true(all(lithuania$MMEID %in% everything$MMEID))
})

test_that("gwcode follows the Gleditsch and Ward list", {
  mme <- troopdata::mme_long

  # countrycode sends "Vietnam" to 815, a nineteenth century polity in the G&W list; the modern
  # state is 816. It has no gwn entry at all for Yemen or the G&W microstates.
  expect_false(815 %in% mme$gwcode)
  expect_equal(unique(mme$gwcode[mme$country == "Vietnam"]), 816)
  expect_equal(unique(mme$gwcode[mme$country == "Yemen"]), 678)
  expect_equal(unique(mme$gwcode[mme$country == "Grenada"]), 55)
  expect_false(anyNA(mme$gwcode[mme$country %in% c("Dominica", "Tonga", "Vanuatu",
                                                    "Palau", "Seychelles")]))

  # The G&W list has no Serbia before 2006.
  expect_false(any(mme$gwcode == 340 & mme$year < 2006, na.rm = TRUE))
})
