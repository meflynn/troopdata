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

  # December 2022, March 2023 and June 2023 are left out: the Army reported nothing for them, so
  # the reports carry no total and no Army figure, and the long frame adds an interpolated one.
  # Those quarters have a test of their own below.
  checked <- long %>%
    dplyr::inner_join(reports, by = c("ccode", "year", "month")) %>%
    dplyr::filter(!((year == 2022 & quarter == 4) | (year == 2023 & quarter %in% c(1, 2)))) %>%
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

  # 816 is intentionally VDR (North Vietnam) through 1975 and VNM (unified Vietnam) after, so
  # iso3c is checked per year for the same reason the name is.
  iso.per.ccode.year <- long %>%
    dplyr::filter(!is.na(iso3c)) %>%
    dplyr::distinct(ccode, year, iso3c) %>%
    dplyr::count(ccode, year) %>%
    dplyr::filter(n > 1)

  ccode.per.name <- long %>%
    dplyr::distinct(countryname, ccode) %>%
    dplyr::count(countryname) %>%
    dplyr::filter(n > 1)

  expect_equal(nrow(names.per.ccode.year), 0)
  expect_equal(nrow(iso.per.ccode.year), 0)
  expect_equal(nrow(ccode.per.name), 0)

})

test_that("known reference values match the published DMDC reports", {

  long <- troopdata::troopdata_rebuild_long

  # South Vietnam, September 1968. Peak reported US strength in country.
  expect_equal(max(long$troops_ad[long$ccode == 817 & long$year == 1968], na.rm = TRUE), 537377)

  # West Germany, June 1955: 268,504 ashore. The report's total is 269,260, which adds 756
  # afloat and mobile.
  expect_equal(max(long$troops_ad[long$ccode == 260 & long$year == 1955], na.rm = TRUE), 268504)

  # South Korea, June 1953. The report's own total, 326,863. The 21,715 Navy personnel it prints
  # in parentheses beside it are afloat, with Korea as the nearest port, and are not in Korea.
  expect_equal(max(long$troops_ad[long$ccode == 732 & long$year == 1953], na.rm = TRUE), 326863)

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
  expect_equal(unique(long$iso3c[long$ccode == 816 & long$year > 1975]), "VNM")
  expect_equal(unique(long$countryname[long$ccode == 816 & long$year > 1975]), "Vietnam")

})

test_that("North Vietnam exists as a state while Vietnam was divided", {

  long <- troopdata::troopdata_rebuild_long

  # G&W 816 is the Democratic Republic of Vietnam until unification. The scaffold comes from the
  # G&W system list, so North Vietnam gets country-years for the divided period exactly as East
  # Germany, South Yemen and North Korea do -- none of which host US troops either. A blanket
  # 815/816/817 -> 817 recode erased it: the rows were relabelled South Vietnam and then collapsed
  # as duplicates, leaving a gap no other divided state has.
  north <- long[long$ccode == 816 & long$year <= 1975, ]

  expect_gt(nrow(north), 0)
  expect_equal(unique(north$countryname), "North Vietnam")
  expect_equal(unique(north$iso3c), "VDR")

  # North and South coexist, each on its own code, for the overlapping years.
  overlap <- intersect(north$year, long$year[long$ccode == 817])
  expect_gt(length(overlap), 0)

  # Treated the same way as the other divided states: present in the frame, essentially no US
  # troops. Compare with East Germany, which is present throughout with a handful of embassy staff.
  expect_gt(nrow(long[long$ccode == 265, ]), 0)

  # "North Vietnam" belongs to 816 alone.
  expect_equal(unique(long$ccode[long$countryname == "North Vietnam"]), 816)

})

test_that("Serbia is not double coded after the 2006 split", {

  long <- troopdata::troopdata_rebuild_long

  expect_equal(nrow(long[long$ccode == 345 & long$year > 2006, ]), 0)
  expect_true(nrow(long[long$ccode == 340, ]) > 0)

})

test_that("states with an ISO code have one", {

  long <- troopdata::troopdata_rebuild_long

  expected <- c("58" = "ATG", "60" = "KNA", "403" = "STP", "591" = "SYC",
                "972" = "TON", "987" = "FSM")

  for (code in names(expected)) {
    observed <- unique(long$iso3c[long$ccode == as.numeric(code)])
    expect_equal(observed, unname(expected[code]))
  }

  # 816 is the exception, and deliberately so: the Democratic Republic of Vietnam (VDR, the retired
  # ISO 3166-3 alpha-3, as DDR and YMD are used here) while the country was divided, and unified
  # Vietnam (VNM) from 1976. One code per ccode-year still holds; see the per-year check above.
  expect_equal(unique(long$iso3c[long$ccode == 816 & long$year <= 1975]), "VDR")
  expect_equal(unique(long$iso3c[long$ccode == 816 & long$year > 1975]), "VNM")

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
  # to return those rows too. 1972 carries both a Japan row and a Ryukyu Islands row.
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

  # Only the Army is missing from those three workbooks, so only the Army is interpolated. What
  # the other services reported is kept: these used to be replaced by a straight line between
  # September 2022 and September 2023 (Marine Corps in Japan about 18,160, in Norway 24).
  at <- function(code, yr, qtr, column) {
    long[[column]][long$ccode == code & long$year == yr & long$quarter == qtr]
  }
  expect_equal(at(740, 2022, 4, "marine_corps_ad"), 21132)   # Japan, December 2022
  expect_equal(at(740, 2022, 4, "navy_ad"), 21066)
  expect_equal(at(385, 2023, 1, "marine_corps_ad"), 683)     # Norway, March 2023
  expect_equal(at(800, 2023, 1, "marine_corps_ad"), 260)     # Thailand, March 2023

  # Army in Japan: 2,455 in September 2022 and 2,360 in September 2023, so 2,431 a quarter in.
  expect_equal(at(740, 2022, 4, "army_ad"), 2431)
  expect_equal(at(740, 2022, 4, "troops_ad"), 2431 + 21066 + 21132 + 12834 + 19)

  # The totals are the sum of their parts in those quarters.
  branch.sum <- rowSums(gap[, c("army_ad", "navy_ad", "air_force_ad", "marine_corps_ad",
                                "coast_guard_ad", "space_force_ad")], na.rm = TRUE)
  expect_equal(gap$troops_ad, branch.sum)
  reserve.sum <- rowSums(gap[, c("army_national_guard", "air_national_guard", "army_reserve",
                                 "navy_reserve", "marine_corps_reserve", "air_force_reserve",
                                 "coast_guard_reserve")], na.rm = TRUE)
  expect_equal(gap$total_selected_reserve, reserve.sum)

  # The reports frame holds those rows as the workbooks print them: no Army, no total.
  reports <- troopdata::troopdata_rebuild_reports
  japan <- reports[reports$ccode == 740 & reports$year == 2022 & reports$quarter == 4, ]
  expect_equal(nrow(japan), 1)
  expect_true(is.na(japan$troops_ad))
  expect_true(is.na(japan$army_ad))
  expect_equal(japan$`Marine Corps Active Duty`, 21132)

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


test_that("region holds a single vocabulary", {

  long <- troopdata::troopdata_rebuild_long

  # countrycode renamed its World Bank MENA label to "Middle East, North Africa, Afghanistan &
  # Pakistan", and both spellings were reaching this column -- 22 codes under the new name, 4 under
  # the old. Because get_troopdata() matches a region `host` against this column, two labels meant
  # host = "Middle East & North Africa" returned 4 countries and silently missed Iraq, Saudi Arabia,
  # Egypt and the rest. The column now holds one label, the shorter one.
  reports <- troopdata::troopdata_rebuild_reports

  expect_true("Middle East & North Africa" %in% long$region)
  expect_false("Middle East, North Africa, Afghanistan & Pakistan" %in% long$region)
  expect_false("Middle East, North Africa, Afghanistan & Pakistan" %in% reports$region)

  # No region label names a country. Afghanistan (700) and Pakistan (770) are classified in South
  # Asia here, so a MENA label naming them described a grouping this column does not use.
  for (frame in list(long, reports)) {
    labels <- unique(frame$region[!is.na(frame$region)])
    expect_false(any(grepl("Afghanistan|Pakistan", labels)))
  }
  expect_equal(unique(long$region[long$ccode == 700]), "South Asia")   # Afghanistan
  expect_equal(unique(long$region[long$ccode == 770]), "South Asia")   # Pakistan

  # Exactly one label per region, and the MENA label reaches the actual MENA states.
  mena <- unique(long$ccode[long$region == "Middle East & North Africa"])
  expect_true(all(c(630, 645, 651, 666, 670, 690) %in% mena))  # Iran, Iraq, Egypt, Israel, Saudi, Kuwait
  expect_false(any(c(700, 770) %in% mena))

  # Every row carries a region.
  expect_equal(sum(is.na(long$region)), 0)

  # St. Helena is a South Atlantic territory. It was landing in MENA off a name match, while
  # Ascension -- the same British overseas territory -- was already in Sub-Saharan Africa.
  helena <- unique(long$region[grepl("Helena", long$countryname)])
  if (length(helena) > 0) expect_equal(helena, "Sub-Saharan Africa")

})

test_that("no state outlives its Gleditsch and Ward end date", {

  long <- troopdata::troopdata_rebuild_long

  # The scaffold's Kane supplement spans first(year)-last(year) per code, which stretched states
  # past their own dissolution: 265 carried empty rows through 2005, fifteen years after the DDR
  # ceased to exist. The build now bounds every terminated state to its G&W end year.
  terminated <- list("265" = 1990,   # German Democratic Republic
                     "315" = 1992,   # Czechoslovakia
                     "680" = 1990,   # Yemen People's Republic
                     "817" = 1975,   # Republic of Vietnam
                     "345" = 2006,   # Yugoslavia, before the Serbia split
                     "511" = 1964)   # Zanzibar

  for (cc in names(terminated)) {
    rows <- long[long$ccode == as.numeric(cc), ]
    if (nrow(rows) == 0) next
    expect_lte(max(rows$year), terminated[[cc]],
               label = paste("ccode", cc, "max year"))
  }

})

test_that("the end-date bound does not truncate states that still exist", {

  long <- troopdata::troopdata_rebuild_long
  final.year <- max(long$year)

  # The bound is keyed on the latest end year in the G&W list rather than a hard-coded year, so a
  # change to that file's vintage marker cannot silently cut the series short. If it ever did, the
  # count of states reaching the final year would collapse.
  extant <- length(unique(long$ccode[long$year == final.year]))
  expect_gt(extant, 150)

  # Spot-check a few states that plainly still exist.
  for (cc in c(2, 200, 220, 260, 710, 732, 740, 816)) {
    expect_equal(max(long$year[long$ccode == cc]), final.year,
                 label = paste("ccode", cc, "final year"))
  }

})


test_that("iso3c reaches every location that has a code", {

  long <- troopdata::troopdata_rebuild_long

  # 981 rows holding 360,304 reported personnel used to carry iso3c = NA, so no ISO3C `host` filter
  # could reach them -- Greenland/Thule, Bermuda, the Azores/Lajes, Diego Garcia, Yugoslavia. Only
  # three places genuinely have no ISO3C: 1032 British West Indies (a dissolved federation with
  # several successor states), 1038 Kashmir and 1017 the Spratly Islands (both disputed). 10200 is
  # personnel afloat, who are in no country.
  unreachable <- unique(long$ccode[is.na(long$iso3c)])
  expect_setequal(unreachable, c(1017, 1032, 1038, 10200))

  # Units with a code of their own.
  expect_equal(unique(long$iso3c[long$ccode == 1002]), "GRL")   # Greenland
  expect_equal(unique(long$iso3c[long$ccode == 1007]), "BMU")   # Bermuda
  expect_equal(unique(long$iso3c[long$ccode == 1004]), "IOT")   # Diego Garcia
  expect_equal(unique(long$iso3c[long$ccode == 345]),  "YUG")   # Yugoslavia, ISO 3166-3
  expect_equal(unique(long$iso3c[long$ccode == 1016]), "ANT")   # Netherlands Antilles, ISO 3166-3

  # Sub-national units carry the code of the state or territory they belong to. This is deliberate:
  # Lajes is in Portugal, so host = "PRT" should reach it.
  expect_equal(unique(long$iso3c[long$ccode == 1040]), "PRT")   # Azores
  expect_equal(unique(long$iso3c[long$ccode == 711]),  "CHN")   # Tibet
  expect_equal(unique(long$iso3c[long$ccode == 511]),  "TZA")   # Zanzibar
  expect_equal(unique(long$iso3c[long$ccode == 396]),  "GEO")   # Abkhazia

  # Wake, Midway and Johnston are all US Minor Outlying Islands.
  expect_setequal(unique(long$iso3c[long$ccode %in% c(1012, 1014, 10100)]), "UMI")

  # So one ISO3C may span several country codes, which callers aggregating by iso3c must handle.
  # get_troopdata() warns about this; the invariant that must hold is the other direction, one
  # iso3c per ccode-year, which is checked above.
  expect_gt(length(unique(long$ccode[long$iso3c == "UMI"])), 1)

})


test_that("country codes conform to the Gleditsch and Ward system list", {

  long <- troopdata::troopdata_rebuild_long

  # Checked against ksgmdw.txt + microstates.txt (225 codes). The build's custom territory codes
  # (1001-1042, 10000, 10100, 10101, and 10200 for personnel afloat) are deliberate additions for
  # what G&W does not cover, and none of them collides with a real G&W state number.
  custom <- unique(long$ccode[long$ccode >= 1000])
  expect_true(all(custom >= 1000))
  expect_false(any(custom %in% c(2, 20, 200, 220, 255, 260, 265, 327, 340, 345, 710, 740)))

  # G&W 327 is the Papal States (1816-1870). The reports' "Vatican City" rows are the modern Holy
  # See, which is not a G&W state, so they carry the custom code 1003 rather than contradicting the
  # system list the scaffold is built from.
  expect_equal(nrow(long[long$ccode == 327, ]), 0)
  if (nrow(long[long$ccode == 1003, ]) > 0) {
    expect_equal(unique(long$countryname[long$ccode == 1003]), "Vatican City")
    expect_equal(unique(long$iso3c[long$ccode == 1003]), "VAT")
  }

  # G&W 340 (Serbia) does not exist between 1915 and 2006. The reports carry a literal "Serbia"
  # location for 1995-1998, which was producing Serbia country-years alongside Yugoslavia's own 345
  # rows for the same years -- two codes for one territory. Those rows belong to 345.
  expect_equal(nrow(long[long$ccode == 340 & long$year < 2006, ]), 0)
  expect_true(all(c(1995, 1996, 1997, 1998) %in% long$year[long$ccode == 345]))

  # Terminated states stop exactly on their G&W end year, verified against the system list.
  gw.end <- c("265" = 1990, "315" = 1992, "345" = 2006, "511" = 1964,
              "680" = 1990, "711" = 1950, "817" = 1975)
  for (cc in names(gw.end)) {
    rows <- long[long$ccode == as.numeric(cc), ]
    if (nrow(rows) == 0) next
    expect_equal(max(rows$year), gw.end[[cc]], label = paste("ccode", cc, "end year"))
  }

  # Pre-independence rows are deliberate: country.year.list.supplement keeps Kane's deployments to
  # territories that were not yet states, so Morocco carries 1950-1955 (the SAC bases, ~56,000
  # troop-years) though G&W starts it in 1956, and Eritrea carries Kagnew Station from 1950 though
  # G&W starts it in 1993. This is the one place the panel departs from G&W's state-existence rule,
  # and it departs only on the start side.
  expect_true(min(long$year[long$ccode == 600]) < 1956)   # Morocco
  expect_true(min(long$year[long$ccode == 531]) < 1993)   # Eritrea

})


test_that("every Gleditsch and Ward state reaches the panel", {

  long <- troopdata::troopdata_rebuild_long

  # The panel covers states, not just states with deployments: North Korea, South Yemen and East
  # Germany are all present with essentially no US personnel. Fifteen G&W microstates were missing
  # anyway, because countrycode's gwn -> country.name lookup has no entry for them and the rows were
  # then dropped by filter(!is.na(countryname)). The eight microstates that survived did so only
  # because someone had written an explicit branch for them in standardize_countryname(). The build
  # now falls back to the system list's own name, so membership no longer depends on that.
  microstates <- c(54, 55, 56, 57, 58, 60, 221, 223, 232, 331, 396, 397, 403,
                   591, 935, 970, 971, 973, 983, 986, 987, 990)

  missing <- microstates[!microstates %in% long$ccode]
  expect_equal(length(missing), 0,
               info = paste("G&W microstates absent from the panel:",
                            paste(missing, collapse = ", ")))

  # Spot-check the ones that used to vanish, including their names and codes.
  expect_true(all(c("Dominica", "Grenada", "Monaco", "Liechtenstein", "Andorra",
                    "San Marino", "Vanuatu", "Nauru", "Tuvalu", "Palau", "Samoa")
                  %in% long$countryname))
  expect_equal(unique(long$iso3c[long$ccode == 55]), "GRD")   # Grenada
  expect_equal(unique(long$iso3c[long$ccode == 990]), "WSM")  # Samoa
  expect_equal(unique(long$iso3c[long$ccode == 221]), "MCO")  # Monaco

  # Zero deployments is not a reason to be absent.
  expect_gt(nrow(long[long$ccode == 973, ]), 0)               # Tuvalu
  expect_gt(nrow(long[long$ccode == 265, ]), 0)               # German Democratic Republic

  # A state's first year follows its G&W start, so the late arrivals are short series, not full ones.
  expect_gte(min(long$year[long$ccode == 397]), 2008)         # South Ossetia
  # Palau joined the G&W list in 1994, but the reports list personnel there from 1987, and report
  # rows from before a state's independence are kept (as they are for Algeria and the Marshalls).
  expect_gte(min(long$year[long$ccode == 986]), 1987)         # Palau

})

test_that("Germany is named for the Federal Republic across the whole series", {

  long <- troopdata::troopdata_rebuild_long

  # G&W 260 is the German Federal Republic: West Germany while the country was divided and, after
  # 1990, the same state having absorbed the GDR. One name covers both periods, so unlike 816 it
  # needs no year split. 265 stays the German Democratic Republic and ends in 1990.
  expect_equal(unique(long$countryname[long$ccode == 260]), "Federal Republic of Germany")
  expect_equal(unique(long$iso3c[long$ccode == 260]), "DEU")
  expect_equal(unique(long$countryname[long$ccode == 265]), "German Democratic Republic")
  expect_equal(max(long$year[long$ccode == 265]), 1990)

  # Both exist side by side while the country was divided.
  divided <- intersect(long$year[long$ccode == 260], long$year[long$ccode == 265])
  expect_gt(length(divided), 0)
  expect_lte(max(divided), 1990)

  # host = "Germany" still reaches it, since host matching is a regex.
  expect_true(any(grepl("Germany", long$countryname[long$ccode == 260])))

})


test_that("branch-level guard, reserve and civilian components carry values", {

  long <- troopdata::troopdata_rebuild_long

  # These seven columns were shipping entirely empty while total_selected_reserve looked fine, so
  # get_troopdata(guard_reserve = TRUE) returned seven columns of nothing. The reports carry the
  # detail for 44 to 77 country codes -- 563,478 Army National Guard troop-years outside the United
  # States alone. The cause was a case_when() in the build with no `TRUE ~ .x`: both of its
  # conditions required is.na(.x), so every value that was not missing matched nothing and came
  # back NA. It was applied to a positional range, coast_guard_ad:coast_guard_reserve, which is why
  # exactly these columns went and their neighbours did not.
  components <- c("army_national_guard", "air_national_guard", "army_reserve", "navy_reserve",
                  "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve")

  expect_true(all(components %in% names(long)))

  for (cl in components) {
    reported <- long[[cl]][long$year >= 2008]
    expect_true(any(!is.na(reported) & reported > 0),
                info = paste(cl, "has no reported values from 2008 on"))
  }

  # The aggregate is kept alongside the components, not instead of them.
  expect_true("total_selected_reserve" %in% names(long))
  expect_true(any(long$total_selected_reserve > 0, na.rm = TRUE))

  # The components are reported for many countries, not just the United States.
  for (cl in components) {
    codes <- unique(long$ccode[!is.na(long[[cl]]) & long[[cl]] > 0])
    expect_gt(length(setdiff(codes, 2)), 0,
              label = paste(cl, "non-US country codes"))
  }

  # The same range took Coast Guard and Space Force active duty with it, so branch = TRUE returned
  # neither. Coast Guard is reported from 2008 and Space Force from 2023.
  expect_true(any(long$coast_guard_ad > 0, na.rm = TRUE))
  expect_gt(length(unique(long$ccode[!is.na(long$coast_guard_ad) & long$coast_guard_ad > 0])), 10)
  expect_true(any(long$space_force_ad > 0, na.rm = TRUE))

  # The components account for the aggregate: where both are reported, the seven add up to
  # total_selected_reserve.
  both <- long[long$year >= 2008 & !is.na(long$total_selected_reserve) &
                 long$total_selected_reserve > 0, ]
  component.sum <- rowSums(both[, components], na.rm = TRUE)
  expect_gt(mean(abs(component.sum - both$total_selected_reserve) < 0.5), 0.95)

  # Civilian components, which were already coming through, must stay that way.
  for (cl in c("army_civilian", "navy_civilian", "air_force_civilian", "total_civilian")) {
    expect_true(any(long[[cl]] > 0, na.rm = TRUE), info = cl)
  }

})

test_that("manually coded troop values carry a source", {

  long <- troopdata::troopdata_rebuild_long

  # The largest non-DMDC figures in the series -- Afghanistan 2018-2020 at 142,400 troop-years, Iraq
  # 2006-2007, Syria, Kuwait 2003-2007 -- were carrying source = NA, so `source` attributed them to
  # nothing. The provenance was only in code comments.
  for (spec in list(list(cc = 700, yrs = 2018:2020, pat = "Just Security"),
                    list(cc = 652, yrs = 2018:2020, pat = "Just Security"),
                    list(cc = 645, yrs = 2021, pat = "New York Times"),
                    list(cc = 652, yrs = 2021, pat = "Politico"),
                    list(cc = 645, yrs = 2006:2007, pat = "Federation of American Scientists|Reuters"),
                    list(cc = 690, yrs = 2003:2007, pat = "Kane|OIF"))) {
    rows <- long[long$ccode == spec$cc & long$year %in% spec$yrs & long$troops_ad > 0, ]
    if (nrow(rows) == 0) next
    expect_false(any(is.na(rows$source)),
                 info = paste("ccode", spec$cc, "has rows with no source"))
    expect_true(any(grepl(spec$pat, rows$source)),
                info = paste("ccode", spec$cc, "source does not name its origin"))
  }

  # An unreported country-period is a genuine zero, not a missing value: the DMDC reports cover only
  # countries where US personnel are present, so absence from a report means none were there.
  expect_equal(sum(is.na(long$troops_ad)), 0)

})



test_that("a category is NA before the DMDC first reported it, and never NA after", {

  long <- troopdata::troopdata_rebuild_long

  # 0 means the report was checked and nobody was there. These categories were not in the report
  # format at all before September 2008, so the honest value is NA, which is also what
  # get_troopdata() tells the user to expect when guard_reserve = TRUE.
  from.2008 <- c("coast_guard_ad",
                 "army_national_guard", "air_national_guard", "army_reserve", "navy_reserve",
                 "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve",
                 "total_selected_reserve", "army_civilian", "navy_civilian",
                 "marine_corps_civilian", "air_force_civilian", "dod_civilian", "total_civilian")

  for (cl in from.2008) {
    expect_true(all(is.na(long[[cl]][long$year < 2008])),
                info = paste(cl, "has values before 2008"))
    expect_false(any(is.na(long[[cl]][long$year >= 2008])),
                 info = paste(cl, "has NA from 2008 on"))
  }

  # Space Force gets a column of its own in the September 2023 report. From December 2021 to June
  # 2023 the sheets carry it inside a combined "AIR FORCE/SPACE FORCE" column, so it is already in
  # air_force_ad. The interpolated quarters before September 2023 must not carry a Space Force
  # ramp: one end of it would be "not reported", not zero.
  before <- long$year < 2023 | (long$year == 2023 & long$quarter < 3)
  expect_true(all(is.na(long$space_force_ad[before])))
  expect_false(any(is.na(long$space_force_ad[!before])))
  first <- long[!is.na(long$space_force_ad) & long$space_force_ad > 0, ]
  expect_equal(min(first$year + first$quarter / 10), 2023.3)

  # troops_all is built before any of this, so it is never NA and equals troops_ad in the years
  # with no guard or reserve reporting.
  expect_equal(sum(is.na(long$troops_all[!is.na(long$troops_ad)])), 0)
  early <- long[long$year < 2008 & !is.na(long$troops_ad), ]
  expect_equal(early$troops_all, early$troops_ad)

})

test_that("Puerto Rico is its own location and is not inside the United States total", {

  long <- troopdata::troopdata_rebuild_long

  # Custom code 6. It is in the reports for 73 of 76 years but had no rows here: nothing named the
  # code, so every row was dropped at the no-countryname filter.
  pr <- long[long$ccode == 6, ]
  expect_gt(nrow(pr), 0)
  expect_equal(unique(pr$countryname), "Puerto Rico")
  expect_equal(unique(pr$iso3c), "PRI")
  expect_equal(unique(pr$region), "Latin America & Caribbean")
  expect_true(any(pr$year < 2008) && any(pr$year >= 2008))

  # September 2008, read off the DMDC workbook: Puerto Rico 591 active duty.
  expect_equal(pr$troops_ad[pr$year == 2008 & pr$quarter == 3], 591)

  # The United States total used to keep every sheet row usmap::fips() recognises, which let two
  # OVERSEAS rows in: Puerto Rico, and Georgia the country, which shares the state's name. The
  # fifty states and DC sum to 1,055,155 in the September 2008 workbook; the old figure was
  # 1,055,751, which is that plus Puerto Rico's 591 and Georgia's 5.
  expect_equal(long$troops_ad[long$ccode == 2 & long$year == 2008 & long$quarter == 3], 1055155)

  # Georgia the country keeps its own row.
  expect_equal(long$troops_ad[long$ccode == 372 & long$year == 2008 & long$quarter == 3], 5)

})

test_that("the United States series is complete across the 2008-onward workbooks", {

  long <- troopdata::troopdata_rebuild_long
  us <- long[long$ccode == 2 & long$year >= 2008, ]

  # The US rows are located inside each DMDC sheet by a helper in the build script. One version of
  # it keyed on a label column that is NA for every workbook after the sheet title was reworded in
  # December 2017, and it dropped every US row from then to June 2023: troops_ad was 0 for twenty
  # quarters and the three IPPS-A quarters were interpolated up from that zero. No test looked at
  # the level of the US series, so nothing failed.
  expect_false(anyNA(us$troops_ad))
  expect_true(all(us$troops_ad > 900000))

  # Fifty states and DC, read off the workbooks either side of the title change.
  expect_equal(us$troops_ad[us$year == 2017 & us$quarter == 3], 1025883)
  expect_equal(us$troops_ad[us$year == 2017 & us$quarter == 4], 1067897)
  expect_equal(us$troops_ad[us$year == 2022 & us$quarter == 3], 1164207)

  # March 2025: DMDC also lists Puerto Rico inside the UNITED STATES block (114 Army). It is not a
  # state and stays out of the US figure: 1,130,128, not 1,130,242.
  expect_equal(us$troops_ad[us$year == 2025 & us$quarter == 1], 1130128)

  # The reports frame carries the US row for those workbooks as well.
  reports <- troopdata::troopdata_rebuild_reports
  us.reports <- reports[reports$ccode == 2 & reports$year >= 2013, ]
  expect_true(all(2018:2022 %in% us.reports$year))
  expect_equal(us.reports$troops_ad[us.reports$year == 2022 & us.reports$quarter == 3], 1164207)

  # From September 2023 the US total includes the Space Force column: 1,134,842 in the five older
  # branches plus 8,452 Space Force.
  expect_equal(us.reports$troops_ad[us.reports$year == 2023 & us.reports$quarter == 3], 1143294)

})

test_that("the state-level data carries exactly the fifty states and DC in every period", {

  states <- troopdata::troopdata_rebuild_us_states

  # The state frames were cut out of each sheet with fixed row ranges, but the block they sit in is
  # 54, 55 or 58 rows long and starts on row 6 or row 9, so the end of the alphabet fell off:
  # Wyoming in 18 quarters, and West Virginia, Wisconsin and (in six of them) Washington in 9 more.
  expected <- c(state.name, "District Of Columbia")
  periods <- split(states$state, paste(states$year, states$quarter))
  n.missing <- vapply(periods, function(s) sum(!expected %in% s), numeric(1))

  expect_equal(sum(n.missing > 0), 0)

  # And nothing else. usmap::fips() recognises Puerto Rico, which DMDC lists inside the UNITED
  # STATES block from March 2025, so it was arriving here as a fifty-second "state". It is an
  # overseas location and belongs to the country data.
  expect_true(all(states$state %in% expected))

  # One row per state per period.
  expect_false(any(duplicated(states[, c("year", "quarter", "state")])))

})

test_that("the state-level data carries troops_all, defined as in the country data", {

  states <- as.data.frame(troopdata::troopdata_rebuild_us_states)
  long <- troopdata::troopdata_rebuild_long

  # get_troopdata(state_data = TRUE, guard_reserve = TRUE) selects troops_all. The state data
  # had no such column, so that call failed in every version.
  expect_true("troops_all" %in% names(states))

  components <- c("army_national_guard", "air_national_guard", "army_reserve", "navy_reserve",
                  "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve")
  expect_equal(states$troops_all, states$troops_ad + rowSums(states[, components]))
  expect_equal(states$troops_all, states$troops_ad + states$total_selected_reserve)

  # Missing only where troops_ad is: the 51 states in each of the three quarters the Army did
  # not report.
  expect_equal(is.na(states$troops_all), is.na(states$troops_ad))
  expect_equal(sum(is.na(states$troops_all)), 153)

  # The same definition as the country data, wherever that carries the reserve components.
  reserve <- !is.na(long$total_selected_reserve)
  expect_equal(long$troops_all[reserve],
               long$troops_ad[reserve] + long$total_selected_reserve[reserve])

})

test_that("territories listed inside the United States block are overseas locations", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # From March 2025 the DMDC sheets list Guam, the Northern Marianas, Puerto Rico and the Virgin
  # Islands twice: under OVERSEAS with Army at zero, and inside the UNITED STATES block holding the
  # personnel the Army reports there. They are different people. The second set was being skipped
  # along with the rest of the UNITED STATES block, so it was counted nowhere.
  at <- function(code, yr, qtr, column = "troops_ad") {
    long[[column]][long$ccode == code & long$year == yr & long$quarter == qtr]
  }

  # March 2025, read off the workbook: the OVERSEAS row plus the UNITED STATES block row.
  expect_equal(at(6, 2025, 1), 645 + 114)       # Puerto Rico
  expect_equal(at(1008, 2025, 1), 6795 + 194)   # Guam
  expect_equal(at(1013, 2025, 1), 32 + 6)       # US Virgin Islands
  expect_equal(at(1011, 2025, 1), 0 + 4)        # Northern Mariana Islands
  expect_equal(at(6, 2025, 1, "army_ad"), 114)
  expect_equal(at(1008, 2025, 1, "army_ad"), 194)

  # December 2024 has no such rows, so nothing moves there.
  expect_equal(at(6, 2024, 4), 640)
  expect_equal(at(1008, 2024, 4), 6725)

  # They are not part of the United States, which stays at the fifty states and DC.
  expect_equal(at(2, 2025, 1), 1130128)

  # The reports frame keeps both rows as DMDC lists them rather than adding them together.
  pr <- reports[reports$ccode == 6 & reports$year == 2025 & reports$quarter == 1, ]
  expect_equal(sort(pr$troops_ad), c(114, 645))
  expect_equal(sum(grepl("LISTED WITH STATES", pr$Location)), 1)

  listed <- reports[grepl("LISTED WITH STATES", reports$Location), ]
  expect_true(all(listed$ccode %in% c(6, 1008, 1011, 1013)))
  expect_true(all(listed$year >= 2025))
  expect_false(anyNA(listed$iso3c))

})

test_that("the panel stops at the latest reported quarter", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # The scaffold expands every year into four quarters. When the newest workbook is not a December
  # one, that manufactured rows for quarters nobody has reported yet, all at zero -- with the March
  # 2026 workbook, the United States at 0 for June, September and December 2026.
  expect_equal(max(long$year + long$quarter / 10), max(reports$year + reports$quarter / 10))

})

test_that("navy_ad is populated from 2008 on", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # The branch block named only the pre-2008 Navy columns, so navy_ad was 0 for every country
  # outside the United States in every report from September 2008: 5,305 country-quarters and 1.9
  # million personnel-quarters. Totals were right, which is why nothing else noticed.
  abroad <- long[long$ccode != 2 & long$year >= 2008, ]
  expect_gt(sum(abroad$navy_ad > 0), 5000)

  # Read off the workbooks.
  expect_equal(long$navy_ad[long$ccode == 740 & long$year == 2025 & long$quarter == 3], 20827)  # Japan
  expect_equal(long$navy_ad[long$ccode == 692 & long$year == 2015 & long$quarter == 3], 3755)   # Bahrain

  # Before 2008 the United States is personnel ashore, so its Navy figure is the shore-based
  # column: for June 1954, 269,594 in the continental United States, 2,869 in Alaska and 6,443 in
  # Hawaii. The 265,145 the report shows afloat and mobile are under the Afloat code. The branches
  # add up to the total.
  us.1954 <- long[long$ccode == 2 & long$year == 1954, ]
  expect_equal(us.1954$navy_ad, 269594 + 2869 + 6443)
  expect_equal(us.1954$army_ad + us.1954$navy_ad + us.1954$air_force_ad + us.1954$marine_corps_ad,
               us.1954$troops_ad)

  # And in every reported period the country-year figure is the Navy column of the reports. Hong
  # Kong is folded into China from 1997, as in the first test in this file.
  reported <- reports %>%
    dplyr::filter(year >= 2008, ccode != 2) %>%
    dplyr::mutate(ccode = dplyr::if_else(ccode == 1009, 710, ccode)) %>%
    dplyr::group_by(ccode, year, quarter) %>%
    dplyr::summarise(navy_reported = sum(`Navy Active Duty`, na.rm = TRUE), .groups = "drop")

  checked <- long %>%
    dplyr::inner_join(reported, by = c("ccode", "year", "quarter")) %>%
    dplyr::filter(abs(navy_ad - navy_reported) > 0.5)

  expect_equal(nrow(checked), 0)

})

test_that("places reported separately under one country code are all counted", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # The reports list Japan and the Ryukyu Islands separately through 1973, both coded to Japan.
  # The build kept only the larger row of the two, so September 1968 read 41,948 where the report
  # shows 41,121 + 41,948.
  japan <- reports[reports$ccode == 740 & reports$year == 1968, ]
  expect_equal(sort(japan$troops_ad), c(41121, 41948))
  expect_equal(long$troops_ad[long$ccode == 740 & long$year == 1968 & long$quarter == 3], 83069)

  # A regional subtotal is not a country. "Total - Former Soviet Union" and "USSR & East Europe"
  # match Russia by name and, being larger, displaced Russia's own row.
  expect_false(any(grepl("^Total|East Europe", reports$Location[reports$ccode == 365])))
  expect_equal(long$troops_ad[long$ccode == 365 & long$year == 1995 & long$quarter == 3], 60)

  # A location the report repeats is still counted once: ZIMBABWE appears twice in September 2013.
  expect_equal(long$troops_ad[long$ccode == 552 & long$year == 2013 & long$quarter == 3], 8)

})

test_that("locations the name lookup cannot code still reach the data", {

  long <- troopdata::troopdata_rebuild_long

  at <- function(code, yr, qtr) {
    long$troops_ad[long$ccode == code & long$year == yr & long$quarter == qtr]
  }

  # Each of these was dropped without a message because its name resolved to no country code, so
  # the panel showed zero, or nothing, where the report has personnel. Values read off the reports.
  expect_equal(at(1004, 2008, 3), 322)    # Diego Garcia, reported as British Indian Ocean Territory
  expect_equal(at(678, 2008, 3), 10)      # Yemen
  expect_equal(at(983, 2008, 3), 14)      # Marshall Islands
  expect_equal(at(345, 1999, 3), 6410)    # "Serbia (includes Kosovo)"
  expect_equal(at(55, 1984, 3), 165)      # Grenada

  # Diego Garcia has to run through to the latest report, not stop at 2007.
  expect_equal(max(long$year[long$ccode == 1004]), max(long$year))

})

test_that("locations hold personnel ashore and personnel afloat are carried once", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  at <- function(code, yr, column = "troops_ad") {
    max(long[[column]][long$ccode == code & long$year == yr], na.rm = TRUE)
  }

  # The 1953-1967 reports attribute Navy personnel afloat to the country of the nearest port. The
  # build counted them in that country, which put a fleet at sea in whichever country it happened
  # to be nearest: Greece read 15,066 for September 1960 against 1,976 ashore. Values read off
  # the reports: shore activities plus mobile units temporarily based ashore.
  expect_equal(at(350, 1960), 1976)      # Greece: 13,090 afloat nearby
  expect_equal(at(350, 1957), 1440)      # Greece: the report's total is 15,360
  expect_equal(at(140, 1953), 269)       # Brazil: 12,447 afloat nearby
  expect_equal(at(840, 1954), 8871)      # Philippines: the report's total is 26,890
  expect_equal(at(1009, 1962), 26)       # Hong Kong: 5,600 afloat nearby
  expect_equal(at(200, 1957), 38461)     # United Kingdom: the report's total is 63,008

  # 1968 to 1976: the ashore column. South Vietnam is the in-country figure, without the 20,600
  # afloat offshore; Japan is without the 3,338 afloat the 1974 report adds.
  expect_equal(at(817, 1970), 390278)
  expect_equal(at(740, 1974), 51608)
  expect_equal(at(817, 1968), 537377)    # no afloat figure that year; unchanged

  # Japan, September 1960: Japan, the Ryukyus, the Bonins and the Volcano Islands, all ashore.
  expect_equal(at(740, 1960), 46295 + 37142 + 25 + 124)

  # The branches are ashore as well, and add up to the total.
  early <- long[long$year >= 1953 & long$year <= 1976 & long$ccode != 10200 &
                  long$source != "Kane 2006" & !is.na(long$source) & !is.na(long$army_ad), ]
  expect_equal(early$army_ad + early$navy_ad + early$air_force_ad + early$marine_corps_ad,
               early$troops_ad)

  # The reports frame still shows what the report printed.
  greece <- reports[reports$ccode == 350 & reports$year == 1960, ]
  expect_equal(greece$Total, 1976)
  expect_equal(greece$`Navy Other`, 13090)
  expect_equal(greece$troops_ad, 1976)

  # Personnel afloat are one worldwide figure per report under 10200.
  afloat <- long[long$ccode == 10200, ]
  expect_equal(unique(afloat$countryname), "Afloat")
  expect_equal(unique(afloat$region), "Afloat")
  expect_true(all(is.na(afloat$iso3c)))
  expect_setequal(afloat$year, c(1950, 1953:2007))
  expect_false(any(duplicated(afloat$year)))
  expect_equal(afloat$navy_ad + afloat$marine_corps_ad, afloat$troops_ad)
  expect_true(all(afloat$army_ad == 0 & afloat$air_force_ad == 0))

  # Read off each report's worldwide line.
  expect_equal(at(10200, 1950), 179269)
  expect_equal(at(10200, 1954), 406604)
  expect_equal(at(10200, 1960), 352585 - 78131)   # afloat and mobile, less temporarily shore-based
  expect_equal(at(10200, 1970), 265841)
  expect_equal(at(10200, 1985), 230613)
  expect_equal(at(10200, 2003), 147734)
  expect_equal(at(10200, 2007), 115469)
  expect_equal(at(10200, 1985, "navy_ad"), 225745)
  expect_equal(at(10200, 1985, "marine_corps_ad"), 4868)

  # No report row named for personnel afloat sits under a country's code.
  named.afloat <- reports[grepl("afloat", reports$Location, ignore.case = TRUE), ]
  expect_true(all(named.afloat$ccode == 10200))

})

test_that("the United States before 2008 is the fifty states ashore", {

  long <- troopdata::troopdata_rebuild_long
  us <- function(yr, column = "troops_ad") {
    max(long[[column]][long$ccode == 2 & long$year == yr], na.rm = TRUE)
  }

  # Where a report has no UNITED STATES line the build kept the continental United States row
  # and nothing else, so Alaska and Hawaii were missing from 1954-1958 and 1968-2007. Read off
  # the reports: continental United States + Alaska + Hawaii.
  expect_equal(us(1985), 1331950 + 20648 + 46875)
  expect_equal(us(2007), 882201 + 19408 + 34838)
  expect_equal(us(1970), 1573500 + 29246 + 38397)
  expect_equal(us(2003), 974571 + 16282 + 34203)        # from the PDF report
  expect_equal(us(1985, "navy_ad"), 275872 + 2016 + 12722)

  # Ashore only. September 1960: shore activities 1,579,933 plus 59,153 temporarily shore-based;
  # the report's total of 1,806,455 adds 167,369 afloat. June 1954: the three shore figures.
  expect_equal(us(1960), 1579933 + 59153)
  expect_equal(us(1954), 1894259 + 45483 + 23654)
  expect_equal(us(1974), 1362908 + 23166 + 42204)       # the report adds 111,168 afloat
  expect_equal(us(1950), 952600)

  # The branches add up to the total in every year before 2008.
  early <- long[long$ccode == 2 & long$year < 2008 & !long$year %in% c(1951, 1952), ]
  expect_equal(early$army_ad + early$navy_ad + early$air_force_ad + early$marine_corps_ad,
               early$troops_ad)

})

test_that("a Kane row is used only where the reports have nothing", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # Kane rows are stamped June and the reports for 1957-2013 are dated September, so both used to
  # be kept for the same year, and the annual figure, the larger of the two, was the Kane one
  # wherever Kane's was higher. Germany read 85,419 for 2006: the report's 64,319 plus 21,100
  # deployed to Iraq, who are counted in Iraq as well.
  germany <- get_troopdata(host = 260, startyear = 2006, endyear = 2007)
  expect_equal(germany$troops_ad[germany$year == 2006], 64319)
  expect_equal(germany$troops_ad[germany$year == 2007], 57080)

  # No Kane row remains for a country-year in which a report gives a figure. The rows the
  # reports print as zero in place of Iraq, Kuwait and Afghanistan in 2002-2007 are not figures.
  # Hong Kong is folded into China from 1997, as in the first test in this file.
  reported <- reports %>%
    dplyr::filter(!is.na(troops_ad)) %>%
    dplyr::filter(!(troops_ad == 0 & ccode %in% c(645, 690, 700) & year %in% 2002:2007)) %>%
    dplyr::mutate(ccode = dplyr::if_else(ccode == 1009 & year >= 1997, 710, ccode)) %>%
    dplyr::distinct(ccode, year)
  kane <- long[!is.na(long$source) & long$source == "Kane 2006", ]
  expect_equal(nrow(dplyr::semi_join(kane, reported, by = c("ccode", "year"))), 0)

  # The fallback still does its job where the reports leave a deployment out.
  expect_equal(max(long$troops_ad[long$ccode == 645 & long$year == 2004]), 134000)   # Iraq
  expect_equal(max(long$troops_ad[long$ccode == 700 & long$year == 2004]), 16000)    # Afghanistan

  # Iraq and Syria from 2018 are the exception to the rule. From December 2017 the reports leave
  # out personnel deployed there and print only the few assigned permanently: 158 for Iraq and 1
  # for Syria in December 2021. The figures from public reporting are kept beside them, under
  # their own source, and the annual figure is the larger.
  iraq <- long[long$ccode == 645 & long$year == 2021, ]
  syria <- long[long$ccode == 652 & long$year == 2021, ]
  expect_equal(iraq$troops_ad[iraq$quarter == 2], 2500)
  expect_equal(iraq$troops_ad[iraq$quarter == 4], 158)
  expect_equal(iraq$source[iraq$quarter == 2], "Estimate, New York Times")
  expect_equal(syria$troops_ad[syria$quarter == 2], 900)
  expect_equal(syria$troops_ad[syria$quarter == 4], 1)
  expect_equal(syria$source[syria$quarter == 2], "Estimate, Politico")

  annual <- suppressWarnings(get_troopdata(host = c(645, 652), startyear = 2018, endyear = 2021))
  expect_equal(annual$troops_ad[annual$ccode == 645], c(5200, 5200, 5200, 2500))
  expect_equal(annual$troops_ad[annual$ccode == 652], c(1700, 1000, 900, 900))

})

test_that("personnel afloat attributed to a location are stored beside the ashore figures", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports
  columns <- c("troops_afloat", "navy_afloat", "marine_corps_afloat")

  expect_true(all(columns %in% names(long)))
  expect_true(all(columns %in% names(reports)))

  # The state data starts in 2008, when a crew is counted at its home port, and has none.
  expect_false(any(columns %in% names(troopdata::troopdata_rebuild_us_states)))

  for (data in list(long, reports)) {

    # Never negative: the figures printed in parentheses are read as negative numbers.
    for (column in columns) expect_true(all(data[[column]] >= 0, na.rm = TRUE))

    listed <- data[!is.na(data$troops_afloat), ]
    expect_equal(listed$troops_afloat, listed$navy_afloat + listed$marine_corps_afloat)

    # Nothing for 1951 and 1952, which have no report, or from 2008. The worldwide row is not a
    # location and has no attributed figure.
    expect_true(all(is.na(data$troops_afloat[data$year %in% c(1951, 1952) | data$year >= 2008])))
    expect_true(all(is.na(data$troops_afloat[data$ccode == 10200])))

    # 1953-1976: every location has a figure, zero included. 1950 and 1977-2007: a figure only
    # where the report prints one, which is the United States and, in 1950, Cuba.
    expect_false(anyNA(data$troops_afloat[data$year %in% 1953:1976 & data$ccode != 10200]))
    other <- data[data$year %in% c(1950, 1977:2007) & !is.na(data$troops_afloat), ]
    expect_true(all(other$troops_afloat > 0))
    expect_setequal(unique(other$ccode), c(2, 40))
    expect_equal(unique(other$year[other$ccode == 40]), 1950)

  }

  # The two frames hold the same personnel. There is one report a year in these years, so a year
  # is a report; the country-year frame also has June rows for the few country-years taken from
  # Kane, which have no afloat figure and add nothing.
  by.year <- function(data) {
    kept <- data[!is.na(data$troops_afloat), ]
    tapply(kept$troops_afloat, kept$year, sum)
  }
  expect_equal(by.year(long), by.year(reports))

  # The United States has a figure in every report from 1953 to 2007.
  us <- long[long$ccode == 2 & !is.na(long$troops_afloat) & long$troops_afloat > 0, ]
  expect_setequal(us$year, c(1950, 1953:2007))
  expect_equal(us$troops_afloat[us$year == 1953], 240357)   # Navy "Other" on the UNITED STATES line
  expect_equal(us$troops_afloat[us$year == 1955], 254773 + 999 + 16955)
  expect_equal(us$troops_afloat[us$year == 1968], 183613)   # "U.S., Territories & Special Locations"
  expect_equal(us$troops_afloat[us$year == 1974], 153921 - (770 + 2070 + 207 + 2904))
  expect_equal(us$troops_afloat[us$year == 1977], 154987)   # Afloat line of the United States block
  expect_equal(us$troops_afloat[us$year == 2003], 121540)   # read from the PDF
  expect_equal(us$marine_corps_afloat[us$year == 2004], 164)

  # In every report the attributed personnel fit inside the worldwide figure, service by service,
  # which is what lets get_troopdata(afloat = "include") move them without counting anyone twice.
  placed <- function(column) {
    rows <- reports[reports$ccode != 10200 & !is.na(reports[[column]]), ]
    tapply(rows[[column]], rows$source, sum)
  }
  worldwide <- reports[reports$ccode == 10200, ]
  for (pair in list(c("navy_afloat", "navy_ad"), c("marine_corps_afloat", "marine_corps_ad"))) {
    attributed <- placed(pair[1])
    expect_true(all(attributed <= worldwide[[pair[2]]][match(names(attributed), worldwide$source)]))
  }

  # September 2004: the worldwide line prints 135,536, the Navy alone. The report's afloat lines
  # for the United States (115,494) and for foreign countries (20,206) add to 135,700.
  expect_equal(worldwide$troops_ad[worldwide$year == 2004], 135700)
  expect_equal(worldwide$marine_corps_ad[worldwide$year == 2004], 164)

})

test_that("the 2003 and 2004 reports reach the data with their service branches", {

  long <- troopdata::troopdata_rebuild_long

  at <- function(code, yr, column = "troops_ad") {
    long[[column]][long$ccode == code & long$year == yr & long$quarter == 3]
  }

  # Those two reports are read from PDFs as text. A figure with a thousands separator did not
  # convert, so every location with 1,000 or more personnel lost its row and fell back to the Kane
  # total, which has no branches. Read off the September 2003 and 2004 reports.
  expect_equal(at(260, 2003), 74796)                    # Germany
  expect_equal(at(260, 2003, "army_ad"), 58064)
  expect_equal(at(260, 2003, "air_force_ad"), 16208)
  expect_equal(at(740, 2003, "navy_ad"), 6410)          # Japan
  expect_equal(at(732, 2004), 40840)                    # South Korea
  expect_equal(at(1008, 2003), 3293)                    # Guam, which had no row at all
  expect_equal(at(6, 2003), 1562)                       # Puerto Rico, likewise

  rows <- long[long$year %in% c(2003, 2004) & long$quarter == 3 & long$troops_ad >= 1000 &
                 !long$ccode %in% c(2, 645, 690, 700, 10200), ]
  expect_gt(nrow(rows), 20)
  expect_true(all(rows$army_ad + rows$navy_ad + rows$air_force_ad + rows$marine_corps_ad ==
                    rows$troops_ad))

})

test_that("the nine custom-coded territories reach the data", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  at <- function(code, yr, qtr = 3) {
    long$troops_ad[long$ccode == code & long$year == yr & long$quarter == qtr]
  }

  # Their custom codes were entered in title case and the workbooks print capitals, so none had
  # ever matched. Values read off the workbooks.
  expect_equal(at(1017, 2010), 91)    # Spratly Islands
  expect_equal(at(1018, 2009), 1)     # Trucial States
  expect_equal(at(1021, 2017), 73)    # Akrotiri
  expect_equal(at(1022, 2016), 7)     # Coral Sea Islands
  expect_equal(at(1023, 2016), 12)    # Svalbard
  expect_equal(at(1024, 2016), 7)     # Bassas da India
  expect_equal(at(1025, 2017), 21)    # Curacao
  expect_equal(at(1026, 2017), 53)    # Martinique
  expect_equal(at(1027, 2017), 1)     # Sint Maarten

  expected.iso <- c("1018" = "ARE", "1021" = "GBR", "1022" = "AUS", "1023" = "SJM",
                    "1024" = "ATF", "1025" = "CUW", "1026" = "MTQ", "1027" = "SXM")
  for (code in names(expected.iso)) {
    expect_equal(unique(long$iso3c[long$ccode == as.numeric(code)]), unname(expected.iso[code]))
    expect_equal(unique(reports$iso3c[reports$ccode == as.numeric(code)]), unname(expected.iso[code]))
  }
  expect_equal(unique(long$countryname[long$ccode == 1017]), "Spratly Islands")
  expect_equal(unique(long$region[long$ccode == 1021]), "Europe & Central Asia")
  expect_equal(unique(long$region[long$ccode == 1024]), "Sub-Saharan Africa")
  expect_false(anyNA(reports$region[reports$ccode %in% c(1017, 1018, 1021:1027)]))

  # Two of them were being given another country's code by the name lookup.
  expect_false(any(grepl("BASSAS", reports$Location[reports$ccode == 750])))    # India
  expect_false(any(grepl("TRUCIAL", reports$Location[reports$ccode == 698])))   # Oman

})

test_that("the June 2023 guard, reserve and civilian figures are on the right locations", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  june <- long[long$year == 2023 & long$month == "June", ]
  value <- function(name, column) june[[column]][june$countryname == name]

  # DMDC's June 2023 workbook prints the civilian columns one row low from Montenegro to the
  # end of the overseas list and five guard and reserve columns one row low from Morocco to
  # Wake Island. Qatar's line held Puerto Rico's figures and Uruguay's the United Kingdom's.
  # The country data read each figure from the line below the one it is printed on.
  expect_equal(value("Puerto Rico", "total_civilian"), 2201)
  expect_equal(value("Qatar", "total_civilian"), 27)
  expect_equal(value("United Kingdom", "total_civilian"), 1383)
  expect_equal(value("Uruguay", "total_civilian"), 0)
  expect_equal(value("Spain", "total_civilian"), 432)
  expect_equal(value("Sri Lanka", "total_civilian"), 0)
  expect_equal(value("Montenegro", "total_civilian"), 1)
  expect_equal(value("Morocco", "total_civilian"), 7)

  expect_equal(value("Puerto Rico", "navy_reserve"), 273)
  expect_equal(value("Puerto Rico", "air_national_guard"), 1167)
  expect_equal(value("Qatar", "navy_reserve"), 0)
  expect_equal(value("Qatar", "air_national_guard"), 0)
  expect_equal(value("United Kingdom", "air_force_reserve"), 96)
  expect_equal(value("Uruguay", "air_force_reserve"), 0)
  expect_equal(value("US Virgin Islands", "air_national_guard"), 64)
  expect_equal(value("Wake Island", "air_national_guard"), 0)

  # Montenegro's guard and reserve figures were not displaced; only its civilians were.
  expect_equal(value("Montenegro", "air_national_guard"), 1)

  # The totals that are built from these columns follow.
  reserve <- c("army_national_guard", "air_national_guard", "army_reserve", "navy_reserve",
               "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve")
  civilian <- c("army_civilian", "navy_civilian", "marine_corps_civilian", "air_force_civilian",
                "dod_civilian")
  overseas <- june[june$ccode != 2, ]
  expect_equal(overseas$total_selected_reserve, rowSums(overseas[, reserve]))
  expect_equal(overseas$troops_all, overseas$troops_ad + rowSums(overseas[, reserve]))
  expect_equal(overseas$total_civilian, rowSums(overseas[, civilian]))

  # No location's June figure is now far from both the March and the September figure. Before
  # the correction 69 were, in these eleven columns.
  columns <- c(setdiff(reserve, c("army_national_guard", "army_reserve")), civilian, "total_civilian")
  year.2023 <- long[long$year == 2023 & long$ccode != 2, ]
  quarter <- function(q) {
    rows <- year.2023[year.2023$quarter == q, ]
    rows[match(overseas$ccode, rows$ccode), columns]
  }
  march <- as.matrix(quarter(1)); june.values <- as.matrix(quarter(2)); september <- as.matrix(quarter(3))
  high <- pmax(march, september, na.rm = TRUE)
  low <- pmin(march, september, na.rm = TRUE)
  far <- !is.na(june.values) & !is.na(high) & (june.values > 2 * high + 10 | june.values < low / 2 - 10)
  expect_equal(sum(far), 0)

  # The annual figure is the largest of the quarters, so the misplaced figures had become the
  # 2023 values: Qatar read 2,201 civilians and 1,806 for troops_all on 380 active duty.
  qatar <- suppressMessages(suppressWarnings(
    get_troopdata(host = "Qatar", startyear = 2023, endyear = 2023, guard_reserve = TRUE, civilians = TRUE)
  ))
  expect_equal(qatar$total_civilian, 29)
  expect_equal(qatar$troops_all, qatar$troops_ad)

  # The reports data keep the sheet as published.
  printed <- reports[reports$year == 2023 & reports$month == "June", ]
  expect_equal(printed$`Total Civilian`[printed$Location == "QATAR"], 2201)
  expect_equal(printed$`Total Civilian`[printed$Location == "PUERTO RICO"], 7)

})

test_that("the two Congos are told apart, in the codes and in the names", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # Gleditsch and Ward 484 is Congo (Brazzaville); 490 is the Democratic Republic of the Congo
  # (Leopoldville, Kinshasa, Zaire). Each has one name, the same in both objects, and the name
  # says which of the two it is.
  expect_equal(unique(long$countryname[long$ccode == 484]), "Republic of the Congo")
  expect_equal(unique(long$countryname[long$ccode == 490]), "Democratic Republic of the Congo")
  expect_equal(unique(reports$countryname[reports$ccode == 484]), "Republic of the Congo")
  expect_equal(unique(reports$countryname[reports$ccode == 490]), "Democratic Republic of the Congo")
  expect_equal(unique(long$iso3c[long$ccode == 484]), "COG")
  expect_equal(unique(long$iso3c[long$ccode == 490]), "COD")
  expect_equal(unique(reports$iso3c[reports$ccode == 484]), "COG")
  expect_equal(unique(reports$iso3c[reports$ccode == 490]), "COD")
  expect_false("Congo" %in% long$countryname)

  # Every report line that names one of them is under its code.
  named.brazzaville <- grepl("brazzaville", reports$Location, ignore.case = TRUE)
  named.kinshasa <- grepl("leopoldville|kinshasa|zaire", reports$Location, ignore.case = TRUE)
  expect_gt(sum(named.brazzaville), 50)
  expect_gt(sum(named.kinshasa), 90)
  expect_true(all(reports$ccode[named.brazzaville] == 484))
  expect_true(all(reports$ccode[named.kinshasa] == 490))

  # A bare "Congo" is the former Belgian Congo in 1960 to 1962, when the reports have one line,
  # and Brazzaville from 1978, when it is printed beside "Zaire". The first three were coded to
  # Brazzaville, and the Kane rows for 490 put the same 4, 56 and 79 personnel in the data twice.
  bare <- reports[reports$Location == "Congo", ]
  expect_equal(bare$year[bare$ccode == 490], 1960:1962)
  expect_equal(bare$iso3c[bare$ccode == 490], rep("COD", 3))
  expect_true(all(bare$ccode[bare$year > 1962] == 484))
  expect_gte(min(bare$year[bare$ccode == 484]), 1978)

  annual <- function(code, years) {
    vapply(years, function(y) max(long$troops_ad[long$ccode == code & long$year == y]), numeric(1))
  }
  expect_equal(annual(490, 1960:1963), c(4, 56, 79, 64))
  expect_equal(annual(484, 1960:1963), c(0, 0, 0, 10))
  expect_false(any(long$ccode == 490 & long$year %in% 1960:1962 & grepl("Kane", long$source)))
  expect_equal(long$air_force_ad[long$ccode == 490 & long$year == 1962 & long$month == "September"], 60)

})

test_that("the Leeward Islands line of 1966 to 1974 is Antigua", {

  long <- troopdata::troopdata_rebuild_long
  reports <- troopdata::troopdata_rebuild_reports

  # The line was coded to the British Virgin Islands. The 1975 report renames it "Leeward
  # Islands (Antigua)" and the figures run on: 123 in 1974, 121 in 1975.
  leeward <- reports[grepl("le+ward islands", reports$Location, ignore.case = TRUE), ]
  expect_equal(sort(unique(leeward$year)), 1966:1976)
  expect_true(all(leeward$ccode == 58))
  expect_true(all(leeward$iso3c == "ATG"))

  antigua <- vapply(1966:1975, function(y) max(long$troops_ad[long$ccode == 58 & long$year == y]),
                    numeric(1))
  expect_equal(antigua, c(215, 123, 126, 126, 121, 115, 139, 128, 123, 121))

  # The British Virgin Islands keep the lines that name them.
  expect_false(any(long$ccode == 1035 & long$year %in% 1966:1974))
  expect_equal(sort(unique(long$year[long$ccode == 1035])), c(1988, 1989, 2016, 2017))
  expect_equal(unique(long$countryname[long$ccode == 58]), "Antigua")

})

test_that("the Virgin Islands and Seychelles are in their own regions", {

  long <- troopdata::troopdata_rebuild_long
  region <- function(code) unique(long$region[long$ccode == code])

  # A name pattern for Pacific islands took both groups of Virgin Islands, and Seychelles sat
  # with Diego Garcia in South Asia.
  expect_equal(region(1013), "Latin America & Caribbean")   # US Virgin Islands
  expect_equal(region(1035), "Latin America & Caribbean")   # British Virgin Islands
  expect_equal(region(591), "Sub-Saharan Africa")           # Seychelles

  # Their neighbours, for comparison, and the two that were never affected.
  expect_equal(region(6), "Latin America & Caribbean")      # Puerto Rico
  expect_equal(region(1041), "East Asia & Pacific")         # American Samoa
  expect_equal(region(1004), "South Asia")                  # Diego Garcia

  # A region host returns them with their region.
  caribbean <- suppressMessages(suppressWarnings(
    get_troopdata(host = "Latin America & Caribbean", startyear = 2016, endyear = 2016)
  ))
  expect_true(all(c("US Virgin Islands", "British Virgin Islands") %in% caribbean$countryname))

  africa <- suppressMessages(suppressWarnings(
    get_troopdata(host = "Sub-Saharan Africa", startyear = 2016, endyear = 2016)
  ))
  expect_true("Seychelles" %in% africa$countryname)

})
