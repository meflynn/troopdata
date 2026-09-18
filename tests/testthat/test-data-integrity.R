# Regression tests for the data build.
#
# These guard the class of bug fixed in the 2026-09 rebuild: duplicate scaffold rows and
# duplicate source rows being summed, so that a country-year value silently became 2x or 3x
# the figure in the underlying DMDC report. They are checks on the shipped data objects, so
# they only pass after data-raw/troopdata-rebuild.R has been re-run.

test_that("no country-year-quarter exceeds its own DMDC report total", {

  # The baseline a long-frame value may not exceed is not simply the reported total. The build
  # legitimately raises troops_ad to the sum of the branch columns where that is larger (older
  # reports omit afloat personnel from Total), and it folds Hong Kong into China from 1997. Both
  # are mirrored here so that a failure means duplication, not one of those two rules.

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

})

test_that("no duplicate country-year-quarter observations", {

  long <- troopdata::troopdata_rebuild_long

  expect_equal(sum(duplicated(long[, c("ccode", "year", "month", "quarter")])), 0)

})

test_that("each country code carries one name and one iso3c", {

  long <- troopdata::troopdata_rebuild_long

  # 345 is intentionally Yugoslavia through 2006 and Serbia after, so names are checked per year.
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

})

test_that("known reference values match the published DMDC reports", {

  long <- troopdata::troopdata_rebuild_long

  # South Vietnam, September 1968. Peak reported US strength in country.
  expect_equal(max(long$troops_ad[long$ccode == 817 & long$year == 1968], na.rm = TRUE), 537377)

  # West Germany, June 1955.
  expect_equal(max(long$troops_ad[long$ccode == 260 & long$year == 1955], na.rm = TRUE), 269260)

  # South Korea, June 1953. The report's Total is 326,863, but the branch columns sum to more
  # because Navy and Marine Corps figures are reported only in the ashore/afloat columns, so the
  # build's max(total, branch sum) rule applies. Checked as a range rather than a fixed value.
  korea.1953 <- max(long$troops_ad[long$ccode == 732 & long$year == 1953], na.rm = TRUE)
  expect_gte(korea.1953, 326863)
  expect_lt(korea.1953, 400000)

})

test_that("Botswana and Swaziland/Eswatini use the correct codes", {

  long <- troopdata::troopdata_rebuild_long

  expect_equal(unique(long$iso3c[long$ccode == 571]), "BWA")
  expect_equal(unique(long$iso3c[long$ccode == 572]), "SWZ")
  expect_true(min(long$year[long$ccode == 571]) <= 1960)
  expect_true(min(long$year[long$ccode == 572]) <= 1970)

})

test_that("Vietnam is split at 1975 and modern Vietnam has data", {

  long <- troopdata::troopdata_rebuild_long

  # G&W 815 is a nineteenth century polity. Plain "Vietnam" resolves to it through countrycode,
  # so its absence here is what proves the recode ran.
  expect_equal(nrow(long[long$ccode == 815, ]), 0)

  # 817 is the Republic of Vietnam and ends with it.
  expect_equal(nrow(long[long$ccode == 817 & long$year > 1975, ]), 0)
  expect_true(max(long$troops_ad[long$ccode == 817], na.rm = TRUE) > 500000)

  # 816 is unified Vietnam and must carry the post-war deployments.
  expect_true(max(long$troops_ad[long$ccode == 816 & long$year > 1990], na.rm = TRUE) > 0)
  expect_equal(unique(long$iso3c[long$ccode == 816]), "VNM")

})

test_that("Serbia is not double coded after the 2006 split", {

  long <- troopdata::troopdata_rebuild_long

  expect_equal(nrow(long[long$ccode == 345 & long$year > 2006, ]), 0)
  expect_true(nrow(long[long$ccode == 340, ]) > 0)

})

test_that("states with an ISO code have one", {

  long <- troopdata::troopdata_rebuild_long

  expected <- c("58" = "ATG", "60" = "KNA", "403" = "STP", "591" = "SYC",
                "816" = "VNM", "972" = "TON", "987" = "FSM")

  for (code in names(expected)) {
    observed <- unique(long$iso3c[long$ccode == as.numeric(code)])
    expect_equal(observed, unname(expected[code]))
  }

})

test_that("get_troopdata errors on an unmatched host instead of returning nothing", {

  expect_error(get_troopdata(host = "Wakanda"))

})

test_that("reports are returned as reported, not aggregated", {

  japan <- get_troopdata(host = 740, reports = TRUE, quarters = TRUE,
                         startyear = 1970, endyear = 1975)

  # The report's own location column survives, and separately reported territories stay separate.
  expect_true("Location" %in% names(japan))
  expect_true(nrow(japan) > 0)

})

test_that("host names resolve through country codes, not report labels", {

  # The Ryukyu Islands are reported separately but coded to Japan, so asking for Japan by name has
  # to return those rows too. 1972 is a Ryukyu-only year in the reports.
  by.name <- get_troopdata(host = "Japan", reports = TRUE, quarters = TRUE,
                           startyear = 1972, endyear = 1972)
  by.code <- get_troopdata(host = 740, reports = TRUE, quarters = TRUE,
                           startyear = 1972, endyear = 1972)

  expect_equal(nrow(by.name), nrow(by.code))
  expect_true(nrow(by.name) > 0)

})

test_that("the reported anchors of the 2022-2023 gap are not overwritten", {

  long <- troopdata::troopdata_rebuild_long

  # Hong Kong is folded into China from 1997, so its Army figure is part of China's here.
  reports <- troopdata::troopdata_rebuild_reports %>%
    dplyr::filter(year == 2023, month == "September") %>%
    dplyr::mutate(ccode = dplyr::if_else(ccode == 1009, 710, ccode),
                  reported_army = dplyr::coalesce(`Army Active Duty`, `Army Total`)) %>%
    dplyr::group_by(ccode) %>%
    dplyr::summarise(reported_army = sum(reported_army, na.rm = TRUE), .groups = "drop")

  checked <- long %>%
    dplyr::filter(year == 2023, month == "September") %>%
    dplyr::inner_join(reports, by = "ccode") %>%
    dplyr::filter(!is.na(reported_army), !is.na(army_ad),
                  abs(army_ad - reported_army) > 0.5)

  expect_equal(nrow(checked), 0)

})

test_that("the three unreported quarters of the 2022-2023 gap are filled", {

  long <- troopdata::troopdata_rebuild_long

  gap <- long %>%
    dplyr::filter((year == 2022 & quarter == 4) | (year == 2023 & quarter %in% c(1, 2)))

  # Germany, Japan and South Korea are reported on both sides of the gap, so all three must be
  # interpolated rather than left at zero.
  filled <- gap %>%
    dplyr::filter(ccode %in% c(260, 740, 732))

  expect_equal(nrow(filled), 9)
  expect_true(all(filled$troops_ad > 0))

})

test_that("troops_ad is never less than the sum of its own branches", {

  long <- troopdata::troopdata_rebuild_long

  branches <- c("army_ad", "navy_ad", "air_force_ad",
                "marine_corps_ad", "coast_guard_ad", "space_force_ad")

  checked <- long %>%
    dplyr::mutate(branch_sum = rowSums(dplyr::across(tidyselect::all_of(branches)), na.rm = TRUE)) %>%
    dplyr::filter(!is.na(troops_ad), troops_ad < branch_sum - 0.5)

  expect_equal(nrow(checked), 0)

})

test_that("Guam, the Northern Marianas and the Marshall Islands have separate codes", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  expect_equal(unique(long$countryname[long$ccode == 1008]), "Guam")
  expect_equal(unique(long$iso3c[long$ccode == 1008]), "GUM")
  expect_equal(unique(long$countryname[long$ccode == 1011]), "Northern Mariana Islands")
  expect_equal(unique(long$iso3c[long$ccode == 1011]), "MNP")

  # No Northern Marianas or Marshall Islands rows may be filed under Guam's code.
  guam <- reports[reports$ccode == 1008, ]
  expect_equal(sum(grepl("northern mariana|marshall", guam$Location, ignore.case = TRUE)), 0)

  # And the Pacific custom codes carry a region in the reports, not NA.
  pacific <- reports[reports$ccode %in% c(983, 1008, 1011), ]
  expect_true(all(!is.na(pacific$region)))

})
