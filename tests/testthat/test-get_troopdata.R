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
  # The upper bound is wherever the data ends, so this does not break each time a new DMDC
  # workbook extends the series.
  last.year <- max(troopdata::troopdata_rebuild_long$year)
  result <- get_troopdata()
  expect_true(all(result$year >= 1950 & result$year <= last.year))

  windowed <- get_troopdata(startyear = 1990, endyear = 2000)
  expect_true(all(windowed$year >= 1990 & windowed$year <= 2000))
  expect_true(all(1990:2000 %in% windowed$year))
})

test_that("get_troopdata filters by host country", {
  # 260 is Germany in the Gleditsch and Ward list. This test used 255, the Correlates of War code,
  # which matches nothing here, so `all()` of an empty vector passed without testing anything.
  result <- get_troopdata(host = 260, startyear = 1950, endyear = 2025)
  expect_gt(nrow(result), 0)
  expect_true(all(result$ccode == 260))
})

test_that("branch argument adds service-specific columns", {
  result <- get_troopdata(host = 260, branch = TRUE,
                          startyear = 2000, endyear = 2001)
  expect_gt(nrow(result), 0)
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


test_that("a country name reaches every historical form of a divided country", {

  # A substring match on countryname covers most divided countries on its own, but not Germany:
  # the two German states are stored as "Federal Republic of Germany" and "German Democratic
  # Republic", and "Germany" is not a substring of the second, so host = "Germany" returned the west
  # only and silently dropped 1950-1990 East Germany. A group alias closes that gap.
  result <- suppressWarnings(
    get_troopdata(host = "Germany", startyear = 1950, endyear = 2025))

  expect_setequal(unique(result$ccode), c(260, 265))
  expect_setequal(unique(result$countryname),
                  c("Federal Republic of Germany", "German Democratic Republic"))
  expect_gt(sum(result$troops_ad[result$ccode == 265], na.rm = TRUE), 0)

  # Case does not matter.
  lower <- suppressWarnings(
    get_troopdata(host = "germany", startyear = 1950, endyear = 2025))
  expect_setequal(unique(lower$ccode), c(260, 265))

  # The two states are still reachable one at a time, under the names a user is likely to type.
  west <- suppressWarnings(
    get_troopdata(host = "West Germany", startyear = 1950, endyear = 2025))
  expect_equal(unique(west$ccode), 260)

  east <- suppressWarnings(
    get_troopdata(host = "East Germany", startyear = 1950, endyear = 2025))
  expect_equal(unique(east$ccode), 265)
  expect_lte(max(east$year), 1990)

  # And by ISO3C, since the GDR carries its retired ISO 3166-3 code.
  ddr <- suppressWarnings(
    get_troopdata(host = "DDR", startyear = 1950, endyear = 2025))
  expect_equal(unique(ddr$ccode), 265)

})

test_that("substring matching still spans the other divided countries", {

  for (spec in list(list(q = "Korea",   codes = c(731, 732)),
                    list(q = "Vietnam", codes = c(816, 817)),
                    list(q = "Czech",   codes = c(315, 316)),
                    list(q = "Yemen",   codes = c(678, 680)))) {
    result <- suppressWarnings(
      get_troopdata(host = spec$q, startyear = 1950, endyear = 2025))
    expect_setequal(unique(result$ccode), spec$codes)
  }

  # A name matching one state only still returns one.
  japan <- suppressWarnings(
    get_troopdata(host = "Japan", startyear = 1950, endyear = 2025))
  expect_equal(unique(japan$ccode), 740)

})

test_that("a multi-code host warns so sums are not silently doubled", {

  expect_warning(
    get_troopdata(host = "Germany", startyear = 1950, endyear = 2025),
    "matched more than one country code"
  )

  # One code, no warning about it.
  warnings.seen <- testthat::capture_warnings(
    get_troopdata(host = "Japan", startyear = 1950, endyear = 2025))
  expect_false(any(grepl("matched more than one country code", warnings.seen)))

})

test_that("a numeric host that matches nothing is an error, not an empty result", {
  # 255 is Germany in the Correlates of War list; the data uses Gleditsch and Ward codes, where
  # Germany is 260. This used to return zero rows without a word.
  expect_error(suppressWarnings(get_troopdata(host = 255, startyear = 2000, endyear = 2001)),
               "did not match any country code")

  # One good code and one bad one: the good one is returned and the bad one is named.
  expect_warning(result <- get_troopdata(host = c(260, 255), startyear = 2000, endyear = 2001),
                 "255")
  expect_true(all(result$ccode == 260))
  expect_gt(nrow(result), 0)
})

test_that("personnel afloat are a location of their own", {
  # By default no country holds personnel afloat before 2008; they are one worldwide figure under
  # 10200. The `afloat` argument, tested below, moves the ones a report attributes to a location.
  afloat <- get_troopdata(host = "Afloat", startyear = 1950, endyear = 2025)
  expect_equal(unique(afloat$ccode), 10200)
  expect_equal(afloat$troops_ad[afloat$year == 1985], 230613)
  expect_equal(max(afloat$year), 2007)

  by.code <- suppressWarnings(
    get_troopdata(host = 10200, branch = TRUE, startyear = 1985, endyear = 1985))
  expect_equal(by.code$navy_ad, 225745)
  expect_equal(by.code$marine_corps_ad, 4868)

  # They have no ISO3C code because they are in no country, so the warning about locations an
  # ISO3C filter cannot reach does not list them.
  warnings.seen <- testthat::capture_warnings(
    get_troopdata(host = "DEU", startyear = 1980, endyear = 1990))
  expect_false(any(grepl("Afloat", warnings.seen)))
})

test_that("afloat chooses where personnel afloat attributed to a location are counted", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))
  value <- function(data, code, yr, column = "troops_ad") {
    data[[column]][data$ccode == code & data$year == yr]
  }

  exclude <- quiet(startyear = 1950, endyear = 2010, branch = TRUE)
  include <- quiet(startyear = 1950, endyear = 2010, branch = TRUE, afloat = "include")
  separate <- quiet(startyear = 1950, endyear = 2010, branch = TRUE, afloat = "separate")

  # "exclude" is the default, and anything else is refused.
  expect_identical(exclude, quiet(startyear = 1950, endyear = 2010, branch = TRUE, afloat = "exclude"))
  expect_error(quiet(afloat = "both"), "should be one of")

  # The same rows whichever is chosen; "separate" adds three columns and nothing else changes shape.
  expect_equal(nrow(include), nrow(exclude))
  expect_equal(nrow(separate), nrow(exclude))
  expect_identical(names(include), names(exclude))
  expect_setequal(setdiff(names(separate), names(exclude)),
                  c("troops_afloat", "navy_afloat", "marine_corps_afloat"))
  expect_false(any(grepl("afloat", names(exclude))))

  # "include" gives the figure the report prints with the personnel afloat nearby added. Greece,
  # September 1960: 1,976 ashore and 13,090 afloat with Greece as the nearest port.
  expect_equal(value(exclude, 350, 1960), 1976)
  expect_equal(value(include, 350, 1960), 15066)
  expect_equal(value(include, 350, 1957), 15360)     # the report's own total for Greece
  expect_equal(value(include, 140, 1953), 12716)     # Brazil: 269 ashore
  expect_equal(value(include, 817, 1970), 410878)    # South Vietnam: 390,278 ashore
  expect_equal(value(include, 740, 1974), 54946)     # Japan: 51,608 ashore
  expect_equal(value(include, 350, 1960, "navy_ad"), 308 + 13090)
  expect_equal(value(include, 732, 1953, "marine_corps_ad"), 33531 + 1019)

  # The United States: the fleet in home waters. 1953 and 1960 are the reports' own totals.
  expect_equal(value(include, 2, 1953), 2338379)
  expect_equal(value(include, 2, 1960), 1806455)
  expect_equal(value(include, 2, 1985), 1399473 + 161013)
  expect_equal(value(include, 2, 2007), 936447 + 92590)

  # "separate" leaves the ashore figures alone and puts the personnel afloat beside them.
  expect_equal(value(separate, 350, 1960), 1976)
  expect_equal(value(separate, 350, 1960, "navy_ad"), 308)
  expect_equal(value(separate, 350, 1960, "navy_afloat"), 13090)
  expect_equal(value(separate, 350, 1957, "marine_corps_afloat"), 1333)
  expect_equal(value(separate, 350, 1957, "troops_afloat"), 12587 + 1333)
  expect_equal(value(separate, 2, 1985, "navy_afloat"), 161013)
  expect_equal(value(separate, 2, 1950, "navy_afloat"), 33351)
  located <- separate[!is.na(separate$troops_afloat), ]
  expect_equal(located$troops_afloat, located$navy_afloat + located$marine_corps_afloat)

  # Zero where a report that lists personnel afloat by location has none; missing where the
  # report gives no figure for the location at all.
  expect_equal(value(separate, 260, 1960, "navy_afloat"), 0)          # Germany, 1960
  expect_true(is.na(value(separate, 260, 1985, "navy_afloat")))       # by region only, 1977-2007
  expect_true(is.na(value(separate, 740, 1951, "navy_afloat")))       # no report
  expect_true(all(is.na(separate$troops_afloat[separate$year >= 2008])))
  expect_true(all(is.na(separate$troops_afloat[separate$ccode == 10200])))
  expect_false(anyNA(separate$troops_afloat[separate$year %in% 1953:1976 & separate$ccode != 10200]))

  # Nothing changes from 2008, when a crew is counted at its home port.
  late <- function(data) data[data$year >= 2008, names(exclude)]
  expect_equal(late(include), late(exclude))
  expect_equal(late(separate), late(exclude))

  # The worldwide location holds everyone afloat under "exclude", and only those attributed to no
  # location otherwise, so nobody is counted twice.
  expect_equal(value(exclude, 10200, 1960), 274454)
  expect_equal(value(include, 10200, 1960), 63978)
  expect_equal(value(separate, 10200, 1960), 63978)
  expect_equal(value(include, 10200, 1985), 230613 - 161013)
  expect_true(all(include$troops_ad[include$ccode == 10200] >= 0))
  expect_true(all(include$troops_ad[include$ccode == 10200] <=
                    exclude$troops_ad[exclude$ccode == 10200]))

  # So the three add up to the same total in every year, in all and for each sea service.
  yearly <- function(data, column, beside = NULL) {
    total <- tapply(data[[column]], data$year, sum, na.rm = TRUE)
    if (!is.null(beside)) total <- total + tapply(data[[beside]], data$year, sum, na.rm = TRUE)
    total
  }
  expect_equal(yearly(include, "troops_ad"), yearly(exclude, "troops_ad"))
  expect_equal(yearly(separate, "troops_ad", "troops_afloat"), yearly(exclude, "troops_ad"))
  expect_equal(yearly(include, "navy_ad"), yearly(exclude, "navy_ad"))
  expect_equal(yearly(separate, "navy_ad", "navy_afloat"), yearly(exclude, "navy_ad"))
  expect_equal(yearly(include, "marine_corps_ad"), yearly(exclude, "marine_corps_ad"))
  expect_equal(yearly(separate, "marine_corps_ad", "marine_corps_afloat"),
               yearly(exclude, "marine_corps_ad"))

})

test_that("afloat works with the other arguments", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))

  # A host filter does not change the figures: the worldwide row is worked out from every location
  # in the report, not only the ones asked for.
  alone <- quiet(host = "Afloat", startyear = 1960, endyear = 1960, afloat = "include")
  expect_equal(alone$troops_ad, 63978)
  greece <- quiet(host = "GRC", startyear = 1960, endyear = 1960, afloat = "include")
  expect_equal(greece$troops_ad, 15066)

  # "separate" returns the Navy and Marine Corps ashore columns even when branch = FALSE.
  narrow <- quiet(host = "Greece", startyear = 1960, endyear = 1960, afloat = "separate")
  expect_true(all(c("troops_ad", "troops_afloat", "navy_ad", "navy_afloat",
                    "marine_corps_ad", "marine_corps_afloat") %in% names(narrow)))
  expect_false("army_ad" %in% names(narrow))
  expect_equal(narrow$navy_ad, 308)
  expect_equal(narrow$navy_afloat, 13090)

  # Quarterly data and the reports follow the same rule.
  quarterly <- quiet(host = "Japan", startyear = 1955, endyear = 1955, quarters = TRUE,
                     afloat = "separate")
  expect_equal(quarterly$troops_afloat, 35486)

  reported <- function(choice) {
    quiet(host = c("Greece", "Afloat"), startyear = 1960, endyear = 1960, quarters = TRUE,
          reports = TRUE, afloat = choice)
  }
  expect_equal(reported("exclude")$troops_ad, c(1976, 274454))
  expect_equal(reported("include")$troops_ad, c(15066, 63978))
  expect_equal(reported("separate")$troops_ad, c(1976, 63978))
  expect_equal(reported("separate")$navy_afloat, c(13090, NA))
  expect_false(any(c("troops_afloat", "navy_afloat") %in% names(reported("exclude"))))
  expect_false(any(c("troops_afloat", "navy_afloat") %in% names(reported("include"))))
  expect_true("Navy Other" %in% names(reported("include")))   # the report's own columns stay

  # troops_all moves with troops_ad.
  everyone <- quiet(host = 2, startyear = 2007, endyear = 2008, guard_reserve = TRUE,
                    afloat = "include")
  expect_equal(everyone$troops_all[everyone$year == 2007], 936447 + 92590)

  # The state data starts in 2008 and has no afloat figure, so the argument does nothing there.
  expect_equal(quiet(state_data = TRUE, startyear = 2010, endyear = 2010, afloat = "include"),
               quiet(state_data = TRUE, startyear = 2010, endyear = 2010))

})

test_that("a region host returns the locations in the region, one row each", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))

  # A region chooses which locations come back and nothing more. The query used to return a
  # single row per region, holding the largest value found in any one country of it: 246,875 for
  # Europe in 1985, which is West Germany.
  europe <- quiet(host = "Europe", startyear = 1985, endyear = 1985)
  expect_equal(unique(europe$region), "Europe & Central Asia")
  expect_gt(nrow(europe), 40)
  expect_false(any(duplicated(europe$ccode)))
  expect_true(all(c("ccode", "iso3c", "countryname", "region", "year", "troops_ad") %in%
                    names(europe)))
  expect_equal(europe$troops_ad[europe$ccode == 260], 246875)   # West Germany
  expect_equal(europe$troops_ad[europe$ccode == 200], 29532)    # United Kingdom
  expect_equal(sum(europe$troops_ad), 321502)                   # nothing added up for the user

  # Every region: exactly the rows a query with no host returns for the locations of that region,
  # in the same columns and the same order. "Afloat" and "Antarctica" are regions of one location
  # each, and their names are read as that location's name.
  everything <- quiet(branch = TRUE)
  regions <- setdiff(unique(everything$region), c("Afloat", "Antarctica"))
  expect_setequal(regions, c("East Asia & Pacific", "Europe & Central Asia",
                             "Latin America & Caribbean", "Middle East & North Africa",
                             "North America", "South Asia", "Sub-Saharan Africa"))

  for (name in regions) {
    got <- quiet(host = name, branch = TRUE)
    want <- everything[everything$region == name, ]
    expect_gt(length(unique(got$ccode)), 1)
    expect_identical(as.data.frame(got), as.data.frame(want), info = name)
  }

  # A string that matches several regions returns the locations of each.
  several <- quiet(host = c("Europe", "Asia"), startyear = 2019, endyear = 2020)
  expect_setequal(several$region,
                  c("East Asia & Pacific", "Europe & Central Asia", "South Asia"))
  expect_false(any(duplicated(several[, c("ccode", "year")])))
  expect_true(all(c(260, 740, 750) %in% several$ccode))   # Germany, Japan, India

})

test_that("a region host works with the other arguments like any other host", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))

  same_as_unfiltered <- function(region.host, region.name, ...) {
    got <- quiet(host = region.host, ...)
    want <- quiet(...)
    expect_identical(as.data.frame(got), as.data.frame(want[want$region == region.name, ]),
                     info = paste(region.host, paste(names(list(...)), collapse = " ")))
    invisible(got)
  }

  # Quarterly data: one row per location and quarter.
  quarterly <- same_as_unfiltered("East Asia", "East Asia & Pacific",
                                  startyear = 2019, endyear = 2019, quarters = TRUE, branch = TRUE)
  expect_setequal(quarterly$quarter, 1:4)
  expect_false(any(duplicated(quarterly[, c("ccode", "quarter")])))

  # Guard, reserve and civilian components.
  same_as_unfiltered("Europe", "Europe & Central Asia",
                     startyear = 2005, endyear = 2009, guard_reserve = TRUE, civilians = TRUE)

  # Personnel afloat, under each setting.
  for (choice in c("exclude", "include", "separate")) {
    same_as_unfiltered("East Asia", "East Asia & Pacific",
                       startyear = 1955, endyear = 1975, afloat = choice)
  }
  apart <- quiet(host = "North America", startyear = 2007, endyear = 2007, afloat = "separate")
  expect_equal(apart$troops_afloat[apart$ccode == 2], 92590)
  expect_true(is.na(apart$troops_afloat[apart$ccode == 20]))

  # The reports for the region, as reported.
  reported <- quiet(host = "South Asia", startyear = 2010, endyear = 2010, quarters = TRUE,
                    reports = TRUE)
  expect_true("Location" %in% names(reported))
  expect_gt(length(unique(reported$ccode)), 1)
  expect_equal(unique(reported$region), "South Asia")

  # A string that is also part of a country name is read as a country, not a region.
  africa <- quiet(host = "Africa", startyear = 1985, endyear = 1985)
  expect_setequal(africa$ccode, c(482, 560))   # Central African Republic, South Africa

})

test_that("the region note fires only for strings that do not return one whole region", {

  # Every warning a call raises, as text.
  warnings_of <- function(...) {
    seen <- character()
    withCallingHandlers(get_troopdata(...),
                        warning = function(w) {
                          seen <<- c(seen, conditionMessage(w))
                          invokeRestart("muffleWarning")
                        })
    seen
  }
  region.note <- function(...) grep("`host` value", warnings_of(...), value = TRUE)

  # Part of a region's name, but read as a country because it is part of a country name too.
  # The note says what came back and which regions the string could have meant.
  africa <- region.note(host = "Africa", startyear = 2000, endyear = 2000)
  expect_length(africa, 1)
  expect_match(africa, "was read as a country name, not as a region")
  expect_match(africa, "names it matches are Central African Republic, South Africa\\.")
  expect_match(africa, "'Middle East & North Africa', 'Sub-Saharan Africa'")

  america <- region.note(host = "America", startyear = 2000, endyear = 2000)
  expect_match(america, "name it matches is American Samoa\\.")
  expect_match(america, "'Latin America & Caribbean', 'North America'")

  # Part of several regions' names.
  asia <- region.note(host = "Asia", startyear = 2000, endyear = 2000)
  expect_length(asia, 1)
  expect_match(asia, "is not the full name of a region and matched 3 of them")
  expect_match(asia, "'East Asia & Pacific', 'Europe & Central Asia', 'South Asia'")

  # No note for a full region name, for a string that matches one region only, or for a country
  # whose name shares a word with a region. The first version of this warning fired on all of
  # these, because it tested the string alone.
  for (fine in c("Sub-Saharan Africa", "North America", "Europe & Central Asia", "South Asia",
                 "Europe", "East Asia", "Middle East", "Caribbean",
                 "South Africa", "American Samoa", "Central African Republic", "Japan",
                 "Afloat", "Antarctica")) {
    expect_length(region.note(host = fine, startyear = 2000, endyear = 2000), 0)
  }
  expect_length(region.note(host = "ZAF", startyear = 2000, endyear = 2000), 0)
  expect_length(region.note(host = 560, startyear = 2000, endyear = 2000), 0)
  expect_length(region.note(startyear = 2000, endyear = 2000), 0)
  expect_length(region.note(host = "Kansas", state_data = TRUE, startyear = 2010, endyear = 2010), 0)

  # A region given alongside a country name is not returned, and the note says so.
  mixed <- region.note(host = c("Europe", "Japan"), startyear = 2000, endyear = 2000)
  expect_match(mixed, "'Europe' matched no country name and returned nothing")

  # The note describes the result: the names it gives are the ones that come back.
  got <- suppressWarnings(get_troopdata(host = "Africa", startyear = 2000, endyear = 2000))
  expect_setequal(got$countryname, c("Central African Republic", "South Africa"))
  got <- suppressWarnings(get_troopdata(host = "Asia", startyear = 2000, endyear = 2000))
  expect_setequal(got$region, c("East Asia & Pacific", "Europe & Central Asia", "South Asia"))

})

test_that("state data can be returned with the guard and reserve columns", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))

  # This call failed with "Column `troops_all` doesn't exist" in every earlier version: the
  # function selects troops_all with the guard and reserve columns, and the state data had none.
  states <- quiet(state_data = TRUE, guard_reserve = TRUE, startyear = 2010, endyear = 2010)
  expect_equal(nrow(states), 51)
  expect_true(all(c("total_selected_reserve", "troops_all", "army_national_guard") %in%
                    names(states)))
  expect_equal(states$troops_all, states$troops_ad + states$total_selected_reserve)
  expect_true(all(states$troops_all > states$troops_ad))

  # With the other arguments, and for one state by name and by FIPS code.
  everything <- quiet(state_data = TRUE, guard_reserve = TRUE, branch = TRUE, civilians = TRUE,
                      quarters = TRUE, startyear = 2019, endyear = 2019)
  expect_equal(nrow(everything), 51 * 4)
  expect_equal(everything$troops_all,
               everything$troops_ad + everything$total_selected_reserve)

  kansas <- quiet(host = "Kansas", state_data = TRUE, guard_reserve = TRUE,
                  startyear = 2010, endyear = 2012)
  by.fips <- quiet(host = 20, state_data = TRUE, guard_reserve = TRUE,
                   startyear = 2010, endyear = 2012)
  expect_equal(kansas$troops_all, by.fips$troops_all)
  expect_equal(nrow(kansas), 3)

  # In the three quarters the Army did not report, the total is missing with troops_ad.
  gap <- quiet(state_data = TRUE, guard_reserve = TRUE, quarters = TRUE,
               startyear = 2023, endyear = 2023)
  expect_true(all(is.na(gap$troops_all[gap$quarter %in% 1:2])))
  expect_false(any(is.na(gap$troops_all[gap$quarter %in% 3:4])))

})

test_that("a missing host means no host, and missing values among the hosts are dropped", {

  quiet <- function(...) suppressWarnings(get_troopdata(...))

  warnings_of <- function(...) {
    seen <- character()
    withCallingHandlers(get_troopdata(...),
                        warning = function(w) {
                          seen <<- c(seen, conditionMessage(w))
                          invokeRestart("muffleWarning")
                        })
    seen
  }

  # host = NA failed with "object 'host.type' not found", although the help gave NA as the
  # default, one of the function's own warnings recommended it, and get_builddata() and
  # get_basedata() take it. It now means what NULL means: every location.
  everything <- quiet(startyear = 2000, endyear = 2000)
  expect_gt(nrow(everything), 150)
  expect_identical(quiet(host = NULL, startyear = 2000, endyear = 2000), everything)
  expect_identical(quiet(host = NA, startyear = 2000, endyear = 2000), everything)
  expect_identical(quiet(host = NA_character_, startyear = 2000, endyear = 2000), everything)
  expect_identical(quiet(host = NA_real_, startyear = 2000, endyear = 2000), everything)
  expect_identical(quiet(host = c(NA, NA), startyear = 2000, endyear = 2000), everything)

  # With the other data objects too.
  expect_identical(quiet(host = NA, state_data = TRUE, startyear = 2010, endyear = 2010),
                   quiet(state_data = TRUE, startyear = 2010, endyear = 2010))
  expect_identical(quiet(host = NA, quarters = TRUE, reports = TRUE, startyear = 2010, endyear = 2010),
                   quiet(quarters = TRUE, reports = TRUE, startyear = 2010, endyear = 2010))
  expect_identical(quiet(host = NA, branch = TRUE, guard_reserve = TRUE, afloat = "separate",
                         startyear = 1960, endyear = 1960),
                   quiet(branch = TRUE, guard_reserve = TRUE, afloat = "separate",
                         startyear = 1960, endyear = 1960))

  # A missing value among the hosts was pasted into the search pattern as the text "NA", which
  # is part of China, Ghana, Canada and many other names: eighteen rows for 2000 instead of one.
  japan <- quiet(host = "Japan", startyear = 2000, endyear = 2000)
  expect_equal(nrow(japan), 1)
  expect_identical(quiet(host = c("Japan", NA), startyear = 2000, endyear = 2000), japan)
  expect_identical(quiet(host = c(NA, "Japan"), startyear = 2000, endyear = 2000), japan)
  expect_identical(quiet(host = c(740, NA), startyear = 2000, endyear = 2000),
                   quiet(host = 740, startyear = 2000, endyear = 2000))

  # Dropping a value is said; a host that is missing altogether needs no comment.
  dropped <- "Missing values in `host` were ignored"
  expect_true(any(grepl(dropped, warnings_of(host = c("Japan", NA), startyear = 2000, endyear = 2000))))
  expect_false(any(grepl(dropped, warnings_of(host = NA, startyear = 2000, endyear = 2000))))
  expect_false(any(grepl(dropped, warnings_of(host = "Japan", startyear = 2000, endyear = 2000))))

  # The ISO3C warning no longer recommends an input by name; it says to leave host unset.
  iso <- grep("ISO3C codes cannot reach", warnings_of(host = "GRL"), value = TRUE)
  expect_length(iso, 1)
  expect_match(iso, "leave `host` unset")
  expect_match(iso, "British West Indies")

})

test_that("an ISO3C host returns locations that share a code on rows of their own", {

  quiet <- function(...) suppressMessages(suppressWarnings(get_troopdata(...)))

  warnings_of <- function(...) {
    seen <- character()
    withCallingHandlers(suppressMessages(get_troopdata(...)),
                        warning = function(w) {
                          seen <<- c(seen, conditionMessage(w))
                          invokeRestart("muffleWarning")
                        })
    seen
  }

  # A location with no ISO3C code of its own carries its parent's, so one code can belong to
  # several locations. The rows were grouped on the ISO3C code alone, which merged those locations
  # into one row per code and year under the first location's name and with the largest of their
  # values. host = "PRT" for 1958 returned one row, "Portugal", with the 2,428 personnel of the
  # Azores; Portugal's own 71 were lost.
  prt <- quiet(host = "PRT", startyear = 1958, endyear = 1958)
  expect_equal(nrow(prt), 2)
  expect_equal(prt$troops_ad[prt$countryname == "Portugal"], 71)
  expect_equal(prt$troops_ad[prt$countryname == "Azores"], 2428)
  expect_equal(prt$ccode[prt$countryname == "Portugal"], 235)
  expect_equal(prt$ccode[prt$countryname == "Azores"], 1040)

  # host = "UMI" returned Midway alone.
  umi <- quiet(host = "UMI", startyear = 1960, endyear = 1960)
  expect_setequal(umi$countryname, c("Midway Islands", "Wake Island", "Johnston Island"))

  # The general rule: a query on an ISO3C code returns every location and year that carries the
  # code, each with the values it has when no host is given. Checked for every code that more
  # than one location carries and for two that one location carries.
  everything <- quiet()
  pairs <- unique(everything[!is.na(everything$iso3c), c("iso3c", "ccode")])
  shared <- sort(unique(pairs$iso3c[duplicated(pairs$iso3c)]))
  expect_true(all(c("PRT", "UMI", "GBR", "GEO") %in% shared))

  columns <- c("iso3c", "ccode", "year", "countryname", "region", "troops_ad")
  in_order <- function(x) as.data.frame(x[order(x$ccode, x$year), columns])
  codes <- c(shared, "JPN", "DEU")
  same <- vapply(codes, function(code) {
    isTRUE(all.equal(in_order(quiet(host = code)),
                     in_order(everything[which(everything$iso3c == code), ]),
                     check.attributes = FALSE))
  }, logical(1))
  expect_equal(codes[!same], character())

  # No row and no person is lost or counted twice.
  from.codes <- do.call(rbind, lapply(shared, function(code) in_order(quiet(host = code))))
  expect_equal(nrow(unique(from.codes[, c("ccode", "year")])), nrow(from.codes))
  expect_equal(sum(from.codes$troops_ad, na.rm = TRUE),
               sum(everything$troops_ad[everything$iso3c %in% shared], na.rm = TRUE))

  # By quarter and with the other columns: Akrotiri carries GBR and has rows for two quarters of
  # 2017.
  gbr <- quiet(host = "GBR", quarters = TRUE, branch = TRUE, guard_reserve = TRUE,
               startyear = 2017, endyear = 2017)
  gbr.all <- quiet(quarters = TRUE, branch = TRUE, guard_reserve = TRUE,
                   startyear = 2017, endyear = 2017)
  gbr.all <- gbr.all[which(gbr.all$iso3c == "GBR"), ]
  expect_setequal(gbr$countryname, c("United Kingdom", "Akrotiri"))
  expect_equal(nrow(gbr), nrow(gbr.all))
  expect_setequal(names(gbr), names(gbr.all))
  by_quarter <- function(x) as.data.frame(x[order(x$ccode, x$quarter), names(gbr)])
  expect_equal(by_quarter(gbr), by_quarter(gbr.all), ignore_attr = TRUE)

  # The columns come in the order they always had.
  expect_named(quiet(host = "JPN", startyear = 2000, endyear = 2000),
               c("iso3c", "year", "ccode", "countryname", "region", "troops_ad"))
  expect_named(quiet(host = "JPN", quarters = TRUE, startyear = 2015, endyear = 2015),
               c("iso3c", "year", "month", "quarter", "ccode", "countryname", "region", "troops_ad"))

  # The warning said the rows were separate when they were not. It still fires, and is now true.
  expect_true(any(grepl("returned as separate rows",
                        warnings_of(host = "PRT", startyear = 1958, endyear = 1958))))
  expect_false(any(grepl("returned as separate rows",
                         warnings_of(host = "JPN", startyear = 1958, endyear = 1958))))

})

test_that("state names are matched without regard to case, and a whole name returns that state alone", {

  quiet <- function(...) {
    suppressMessages(suppressWarnings(
      get_troopdata(state_data = TRUE, startyear = 2010, endyear = 2010, ...)
    ))
  }

  # The check on a state name ignored case and the filter after it did not: host = "kansas"
  # passed the check and returned Arkansas, the one name that contains the string as typed, and
  # host = "texas" returned no rows at all.
  expect_identical(quiet(host = "kansas")$state, "Kansas")
  expect_identical(quiet(host = "KANSAS")$state, "Kansas")
  expect_identical(quiet(host = "kansas"), quiet(host = "Kansas"))
  expect_identical(quiet(host = "texas")$state, "Texas")
  expect_identical(quiet(host = "new york")$state, "New York")
  expect_identical(quiet(host = " kansas ")$state, "Kansas")

  # The data spell it "District Of Columbia".
  expect_identical(quiet(host = "District of Columbia")$state, "District Of Columbia")

  # A whole name is that state and no other: "Virginia" used to bring West Virginia with it.
  expect_identical(quiet(host = "Virginia")$state, "Virginia")
  expect_identical(quiet(host = "virginia")$state, "Virginia")
  expect_identical(quiet(host = "west virginia")$state, "West Virginia")
  expect_setequal(quiet(host = c("kansas", "arkansas"))$state, c("Kansas", "Arkansas"))

  # Every state, asked for by its own name in lower case, comes back alone.
  states <- sort(unique(troopdata::troopdata_rebuild_us_states$state))
  expect_length(states, 51)
  returned <- vapply(states, function(s) paste(quiet(host = tolower(s))$state, collapse = " + "),
                     character(1), USE.NAMES = FALSE)
  expect_equal(returned, states)

  # Part of a name still returns every state that contains it, in any case.
  expect_setequal(quiet(host = "Carolina")$state, c("North Carolina", "South Carolina"))
  expect_setequal(quiet(host = "dakota")$state, c("North Dakota", "South Dakota"))

  # FIPS codes are unchanged, and a host that matches no state is an error either way.
  expect_identical(quiet(host = 20)$state, "Kansas")
  expect_error(quiet(host = "Narnia"), "did not match any state")
  expect_error(quiet(host = 999), "did not match any state FIPS code")

})

test_that("values of host that match nothing are named in a warning", {

  quiet <- function(...) suppressMessages(suppressWarnings(get_troopdata(...)))

  warnings_of <- function(...) {
    seen <- character()
    withCallingHandlers(suppressMessages(get_troopdata(...)),
                        warning = function(w) {
                          seen <<- c(seen, conditionMessage(w))
                          invokeRestart("muffleWarning")
                        })
    seen
  }

  ignored <- "did not match any .* in the data and were ignored"

  # How host is read is decided for the vector as a whole, and a value that then matched
  # nothing was dropped without a word. The result is the same as before; the value is named.
  mixed <- warnings_of(host = c("USA", "Japan"), startyear = 2000, endyear = 2000)
  expect_true(any(grepl("'USA' did not match any country name", mixed)))
  expect_true(any(grepl("must all be of one kind", mixed)))
  expect_identical(quiet(host = c("USA", "Japan"), startyear = 2000, endyear = 2000)$countryname,
                   "Japan")

  expect_true(any(grepl("'GER' did not match any ISO3C code",
                        warnings_of(host = c("JPN", "KOR", "GER"), startyear = 2000, endyear = 2000))))
  expect_setequal(quiet(host = c("JPN", "KOR", "GER"), startyear = 2000, endyear = 2000)$iso3c,
                  c("JPN", "KOR"))

  expect_true(any(grepl("'South Koera' did not match any country name",
                        warnings_of(host = c("Japan", "South Koera"), startyear = 2000, endyear = 2000))))

  expect_true(any(grepl("'Narnia' did not match any region",
                        warnings_of(host = c("Europe & Central Asia", "Narnia"),
                                    startyear = 2000, endyear = 2000))))

  # The state data, by name and by FIPS code.
  expect_true(any(grepl("'Narnia' did not match any state name",
                        warnings_of(host = c("texas", "Narnia"), state_data = TRUE,
                                    startyear = 2010, endyear = 2010))))
  expect_true(any(grepl("999 did not match any state FIPS code",
                        warnings_of(host = c(48, 999), state_data = TRUE,
                                    startyear = 2010, endyear = 2010))))

  # Nothing is said when every value matches.
  all.matched <- list(
    list(host = "Japan"), list(host = c("Japan", "Italy")), list(host = c("JPN", "KOR")),
    list(host = c(200, 220)), list(host = "Europe & Central Asia"), list(host = "Korea"),
    list(host = "Germany"), list(), list(host = c("Texas", "kansas"), state_data = TRUE),
    list(host = " kansas ", state_data = TRUE),
    list(host = c(20, 48), state_data = TRUE)
  )

  for (arguments in all.matched) {
    seen <- do.call(warnings_of, c(arguments, list(startyear = 2010, endyear = 2010)))
    expect_false(any(grepl(ignored, seen)), info = paste(unlist(arguments), collapse = ", "))
  }

  # A numeric country code keeps its own message, and a region given beside country names
  # keeps the note that explains it; neither gets a second warning.
  codes <- warnings_of(host = c(200, 9999), startyear = 2000, endyear = 2000)
  expect_equal(sum(grepl("did not match", codes)), 1)

  region.and.country <- warnings_of(host = c("Japan", "Europe"), startyear = 2000, endyear = 2000)
  expect_true(any(grepl("matched no country name and returned nothing", region.and.country)))
  expect_false(any(grepl(ignored, region.and.country)))

})
