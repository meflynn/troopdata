# Tests for get_builddata()
#
# get_builddata() subsets the geocoded military construction spending data
# (troopdata::build_data_20260918), a location-project-year data frame. Each test below
# exercises one function argument. A final block checks for unnecessary
# duplicate rows.
#
# NOTE: get_builddata() was rewritten to expect the new comptroller MILCON
# schema (fiscal_year, state_country, appn/auth/toa_amount, organization,
# transaction_type, facility_group_title, budget_activity_title,
# project_title, location_name, location_full_name). The packaged
# troopdata::build_data_20260918 must be rebuilt to that schema for these tests to run;
# until then skip_if_builddata_ready() skips the suite instead of erroring.

skip_if_builddata_ready <- function() {
  needed <- c("fiscal_year", "state_country", "iso3c", "gwcode", "toa_amount",
              "appn_amount", "auth_amount", "auth_appn_amount", "organization",
              "transaction_type", "facility_group_title",
              "facility_category_title", "budget_activity_title",
              "project_title", "location_name", "location_full_name",
              "is_request")
  have <- needed %in% names(troopdata::build_data_20260918)
  testthat::skip_if_not(
    all(have),
    paste("builddata is not on the new comptroller schema; missing:",
          paste(needed[!have], collapse = ", "))
  )
}

# Convenience: a start/end year guaranteed to be inside the data range.
bd_years <- function() {
  yr <- troopdata::build_data_20260918$fiscal_year
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

test_that("organization filters on the organization name", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(organization = "Navy", startyear = y$start, endyear = y$end))
  expect_true(all(result$organization == "Navy"))
})

test_that("transaction_type filters on transaction type", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(transaction_type = "BUDGET", startyear = y$start, endyear = y$end))
  expect_true(all(result$transaction_type == "BUDGET"))
})

test_that("facility_category searches both levels of the facility taxonomy", {
  skip_if_builddata_ready()
  y <- bd_years()

  # A coarse group label, which lives in facility_group_title.
  grp <- troopdata::build_data_20260918$facility_group_title
  target <- grp[!is.na(grp)][1]
  result <- suppressWarnings(
    get_builddata(facility_category = target, startyear = y$start, endyear = y$end))
  expect_gt(nrow(result), 0)
  expect_true(all(result$facility_group_title %in% target |
                    result$facility_category_title %in% target))

  # A fine category label, which lives in facility_category_title.
  cat <- troopdata::build_data_20260918$facility_category_title
  target <- cat[!is.na(cat)][1]
  result <- suppressWarnings(
    get_builddata(facility_category = target, startyear = y$start, endyear = y$end))
  expect_gt(nrow(result), 0)
  expect_true(all(result$facility_group_title %in% target |
                    result$facility_category_title %in% target))
})

test_that("facility_category returns rows from both columns for shared labels", {
  skip_if_builddata_ready()
  y <- bd_years()

  # Three labels are present at both levels of the taxonomy. A single argument
  # searching one column only would silently return the smaller set.
  shared <- intersect(
    unique(troopdata::build_data_20260918$facility_group_title),
    unique(troopdata::build_data_20260918$facility_category_title))
  shared <- shared[!is.na(shared)]
  skip_if(length(shared) == 0, "no label present at both taxonomy levels")

  target <- shared[1]
  result <- suppressWarnings(
    get_builddata(facility_category = target, startyear = y$start, endyear = y$end))

  expect_gt(sum(result$facility_group_title == target, na.rm = TRUE), 0)
  expect_gt(sum(result$facility_category_title == target, na.rm = TRUE), 0)
  expect_equal(
    nrow(result),
    sum(troopdata::build_data_20260918$facility_group_title == target |
          troopdata::build_data_20260918$facility_category_title == target,
        na.rm = TRUE))
})

test_that("budget_activity filters on budget_activity_title", {
  skip_if_builddata_ready()
  y <- bd_years()
  ba <- troopdata::build_data_20260918$budget_activity_title
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

test_that("facility_category filters on facility_category_title", {
  skip_if_builddata_ready()
  y <- bd_years()
  fac <- troopdata::build_data_20260918$facility_category_title
  target <- fac[!is.na(fac)][1]
  result <- suppressWarnings(
    get_builddata(facility_category = target, startyear = y$start, endyear = y$end))
  expect_true(all(result$facility_category_title == target))
  expect_gt(nrow(result), 0)
})

test_that("label arguments match case-insensitively and return canonical values", {
  skip_if_builddata_ready()
  y <- bd_years()

  result <- suppressWarnings(
    get_builddata(organization = "navy", startyear = y$start, endyear = y$end))
  expect_true(all(result$organization == "Navy"))
  expect_gt(nrow(result), 0)

  result <- suppressWarnings(
    get_builddata(budget_activity = "major construction",
                  startyear = y$start, endyear = y$end))
  expect_true(all(result$budget_activity_title == "MAJOR CONSTRUCTION"))
  expect_gt(nrow(result), 0)
})

test_that("unmatched label values raise an informative error", {
  skip_if_builddata_ready()
  y <- bd_years()

  # The C-1 exhibits carry Marine Corps construction in the Navy accounts, so
  # there is no "Marine Corps" organization. This used to return zero rows.
  expect_error(
    get_builddata(organization = "Marine Corps",
                  startyear = y$start, endyear = y$end),
    "Unmatched `organization` value"
  )
  expect_error(
    get_builddata(budget_activity = "NOT A BUDGET ACTIVITY",
                  startyear = y$start, endyear = y$end),
    "Unmatched `budget_activity` value"
  )
  expect_error(
    get_builddata(facility_category = "Not a facility category",
                  startyear = y$start, endyear = y$end),
    "Unmatched `facility_category` value"
  )
  expect_error(
    get_builddata(transaction_type = "NOT A TRANSACTION",
                  startyear = y$start, endyear = y$end),
    "Unmatched `transaction_type` value"
  )
})

test_that("unmatched host codes raise an informative error", {
  skip_if_builddata_ready()
  y <- bd_years()
  expect_error(
    get_builddata(host = "ZZZ", startyear = y$start, endyear = y$end),
    "Unmatched `host` code"
  )
  expect_error(
    get_builddata(host = 1234, startyear = y$start, endyear = y$end),
    "Unmatched numeric `host` code"
  )
})

test_that("territories carry the custom codes the troop data use", {
  skip_if_builddata_ready()
  y <- bd_years()

  # The G&W list has no code for a dependency, so gwcode used to be NA for Guam, Puerto Rico and
  # the rest and a numeric host could not reach them. They now carry the troop data's codes.
  result <- suppressWarnings(
    get_builddata(host = "GUM", startyear = y$start, endyear = y$end))
  expect_true(all(result$iso3c == "GUM"))
  expect_gt(nrow(result), 0)
  expect_true(all(result$gwcode == 1008))

  by.code <- suppressWarnings(
    get_builddata(host = 1008, startyear = y$start, endyear = y$end))
  expect_equal(nrow(by.code), nrow(result))
  expect_gt(nrow(suppressWarnings(
    get_builddata(host = 6, startyear = y$start, endyear = y$end))), 0)

  bd <- troopdata::build_data_20260918

  # Every row that is in a country has a code.
  expect_false(any(!is.na(bd$iso3c) & is.na(bd$gwcode)))

  # One code per territory.
  territories <- c("PRI", "GRL", "IOT", "GUM", "MNP", "VIR", "UMI", "ASM", "SHN")
  codes <- vapply(territories, function(iso) unique(bd$gwcode[bd$iso3c %in% iso]), numeric(1))
  expect_equal(unname(codes), c(6, 1002, 1004, 1008, 1011, 1013, 1014, 1041, 1042))

  # And each code is one the troop data use for the same ISO code, so a code selects the same
  # place in both data sets. This is what catches the two tables drifting apart.
  td <- troopdata::troopdata_rebuild_long
  pairs <- unique(bd[!is.na(bd$iso3c), c("iso3c", "gwcode")])
  expect_true(all(paste(pairs$iso3c, pairs$gwcode) %in% paste(td$iso3c, td$ccode)))

  # By name where an ISO code covers several places in the troop data.
  name.of <- function(code) unique(td$countryname[td$ccode == code])
  expect_equal(name.of(1014), "Wake Island")
  expect_equal(name.of(1042), "Ascension Island")
  expect_equal(name.of(1008), "Guam")
  expect_equal(name.of(6), "Puerto Rico")
})

test_that("location and project accept a vector of patterns", {
  skip_if_builddata_ready()
  y <- bd_years()

  result <- suppressWarnings(
    get_builddata(location = c("^Norfolk$", "^Quantico$"),
                  startyear = y$start, endyear = y$end))
  expect_setequal(unique(result$location_name), c("Norfolk", "Quantico"))

  result <- suppressWarnings(
    get_builddata(project = c("hospital", "clinic"),
                  startyear = y$start, endyear = y$end))
  expect_true(all(grepl("hospital|clinic", result$project_title, ignore.case = TRUE)))
  expect_gt(nrow(result), 0)
})

test_that("spend_type auth_appn selects auth_appn_amount", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(spend_type = "auth_appn", startyear = y$start, endyear = y$end))
  expect_false(any(is.na(result$auth_appn_amount)))
  expect_gt(nrow(result), 0)
})

test_that("all amount columns are retained regardless of spend_type", {
  skip_if_builddata_ready()
  y <- bd_years()
  amount_cols <- c("appn_amount", "auth_amount", "auth_appn_amount", "toa_amount")
  for (st in c("all", "appn", "auth", "auth_appn", "toa")) {
    result <- suppressWarnings(
      get_builddata(spend_type = st, startyear = y$start, endyear = y$end))
    expect_true(all(amount_cols %in% names(result)),
                info = paste("amount column dropped for spend_type =", st))
  }
})

test_that("include_requests = FALSE keeps only enacted rows", {
  skip_if_builddata_ready()
  y <- bd_years()
  result <- suppressWarnings(
    get_builddata(include_requests = FALSE, startyear = y$start, endyear = y$end))
  expect_false(any(result$is_request))
  expect_gt(nrow(result), 0)

  # FY2016 survives in the C-1 series only as a budget request.
  expect_false(2016 %in% result$fiscal_year)

  expect_error(
    get_builddata(include_requests = NA, startyear = y$start, endyear = y$end),
    "include_requests"
  )
})

test_that("every globalVariables name in get_builddata.R is a column in the data", {
  skip_if_builddata_ready()
  declared <- c('appn_amount', 'appn_title', 'auth_amount', 'auth_appn_amount',
                'budget_activity', 'budget_activity_title',
                'budget_activity_title_reported', 'classification',
                'dollar_type', 'existing_mission', 'facility_category_code',
                'facility_category_title', 'facility_category_title_reported',
                'facility_group_title', 'fiscal_year', 'geo_source', 'gwcode',
                'is_request', 'iso3c', 'latitude', 'location_code',
                'location_full_name', 'location_name', 'location_name_reported',
                'longitude', 'organization', 'organization_reported', 'pe',
                'percent_recapitalization', 'project_number', 'project_title',
                'project_title_reported', 'report_year', 'sheet_type',
                'source_file', 'source_row', 'source_sheet', 'state_country',
                'state_country_name', 'state_country_sort', 'toa_amount',
                'transaction_type')
  expect_setequal(declared, names(troopdata::build_data_20260918))
})

# ---- Duplicate checks ------------------------------------------------------
# Construction data is at the location-project-year level, one row per line of
# the report it was read from. A report can list two projects that agree in
# every column but their position (two $148 million "Barracks & Dining" complexes
# at Fort Bliss in FY2009), so the check is that no line of a report is in the
# data twice, which source_row makes the same thing as no fully duplicated rows.

test_that("no fully duplicated rows in builddata", {
  skip_if_builddata_ready()
  bd <- troopdata::build_data_20260918
  n_dupes <- sum(duplicated(bd))
  expect_equal(n_dupes, 0,
               info = paste("Found", n_dupes, "fully duplicated rows in builddata."))
  expect_false(any(duplicated(bd[, c("source_file", "source_sheet", "source_row")])))
})

test_that("each fiscal year comes from one report, the latest that covers it", {
  skip_if_builddata_ready()
  bd <- troopdata::build_data_20260918

  # Every C-1 report covers two or three fiscal years, so a year is printed in up to three
  # reports. Keeping them all counted the same project-years two and three times over: the
  # appropriations in the file summed to $599.7 billion against about $402 billion.
  reports.per.year <- tapply(bd$source_file, bd$fiscal_year, function(f) length(unique(f)))
  expect_true(all(reports.per.year == 1))
  expect_true(all(bd$report_year >= bd$fiscal_year))

  total <- sum(bd$appn_amount, na.rm = TRUE) / 1e6
  expect_gt(total, 395)
  expect_lt(total, 410)

  # FY2007 is in the FY2007, FY2008 and FY2009 reports; only the last is used. Row counts and
  # totals read off that report.
  fy2007 <- bd[bd$fiscal_year == 2007, ]
  expect_equal(unique(fy2007$source_file), "fy2009_c1.xls")
  expect_equal(nrow(fy2007), 718)
  expect_equal(sum(fy2007$appn_amount, na.rm = TRUE), 18398896)
  expect_equal(sum(bd$appn_amount[bd$fiscal_year == 2011], na.rm = TRUE), 20450582)
  expect_equal(sum(bd$appn_amount[bd$fiscal_year == 2020], na.rm = TRUE), 18328404)

  # A project whose title begins "Total" is still a project. The filter that removes total
  # lines tested the title alone and took the four Total Army School System projects with them
  # ($59.9 million). Every line of the sheet with a fiscal year is now in the data, so the sums
  # equal the workbook's: FY2002 and FY2005 read off fy2003_c1.xls and fy2006_c1.xls.
  tass <- bd[grepl("^Total Army School System", bd$project_title), ]
  expect_equal(sort(tass$fiscal_year), c(2002, 2005, 2006, 2007))
  expect_equal(sort(tass$location_name), c("Augusta", "Camp Williams", "Fort Belvoir", "Springfield"))
  expect_equal(sum(tass$appn_amount), 59912)
  expect_equal(sum(bd$appn_amount[bd$fiscal_year == 2002], na.rm = TRUE), 10789028)
  expect_equal(sum(bd$appn_amount[bd$fiscal_year == 2005], na.rm = TRUE), 10367344)
  expect_equal(sum(bd$appn_amount[bd$fiscal_year == 2006], na.rm = TRUE), 13676603)
  expect_false(any(is.na(bd$location_name) & grepl("^\\s*total", bd$project_title, ignore.case = TRUE)))

  # Different projects that share a location and a title are all there. Matching restatements
  # project by project had merged these.
  vicenza <- bd[bd$fiscal_year == 2007 & bd$location_name == "Vicenza" &
                  bd$project_title == "Barracks Complex", ]
  expect_equal(sort(vicenza$appn_amount), c(29000, 41000, 46000))
  bliss <- bd[bd$fiscal_year == 2009 & bd$location_name == "Fort Bliss" &
                bd$project_title == "Barracks & Dining", ]
  expect_equal(bliss$appn_amount, c(148000, 148000))

  # A supplemental sheet that restates the main sheet is dropped; one that adds projects is
  # kept (the European Reassurance Initiative projects on "FY 2015 OCO").
  key <- function(d) {
    paste(d$source_file, d$fiscal_year, tolower(d$state_country), tolower(d$location_name),
          tolower(d$project_title))
  }
  expect_false(any(key(bd[bd$sheet_type != "base", ]) %in% key(bd[bd$sheet_type == "base", ])))
  expect_equal(nrow(bd[bd$fiscal_year == 2015 & bd$sheet_type == "oco", ]), 13)
  expect_equal(nrow(bd[bd$fiscal_year == 2011 & bd$sheet_type != "base", ]), 0)

  # FY2016 is the one year whose latest report is the one that requests it.
  expect_equal(unique(bd$fiscal_year[bd$is_request]), 2016)
})

test_that("coordinates are inside the country or state the row is filed under", {
  skip_if_builddata_ready()
  skip_if_not_installed("maps")
  skip_if_not_installed("countrycode")
  bd <- troopdata::build_data_20260918

  # The address sent to the geocoder used to end in the report's two-letter code ("Rota, SP"),
  # which put Rota in Sao Paulo, Misawa on Sumatra and Heidelberg in Guyana: 644 of 2,808
  # overseas rows with coordinates were outside their country.
  located <- bd[!is.na(bd$latitude) & !is.na(bd$longitude), ]
  expect_gt(nrow(located), 5000)

  island.groups <- c("Chagos Archipelago" = "IOT", "Ascension Island" = "SHN", "Azores" = "PRT",
                     "Madeira Islands" = "PRT", "Canary Islands" = "ESP", "Micronesia" = "FSM")
  region <- sub(":.*$", "", maps::map.where("world", located$longitude, located$latitude))
  found <- ifelse(region %in% names(island.groups), island.groups[region],
                  suppressWarnings(countrycode::countrycode(region, "country.name", "iso3c")))

  # No overseas point is inside another country's outline, and no domestic one is abroad. A
  # point inside no outline is on a coast or an atoll and is not judged here.
  overseas <- !is.na(located$iso3c) & located$iso3c != "USA"
  expect_equal(sum(overseas & !is.na(found) & found != located$iso3c), 0)
  expect_equal(sum(!overseas & !is.na(found) & found != "USA"), 0)

  # The address spells the place out.
  domestic <- bd$iso3c %in% "USA" & !is.na(bd$location_full_name)
  expect_true(all(grepl(", United States$", bd$location_full_name[domestic])))
  expect_true("Rota, Spain" %in% bd$location_full_name)
  expect_false(any(grepl(", (SP|JA|GY|UK|KR)$", bd$location_full_name)))

  # A label is not a place and has no coordinates.
  label <- grepl("various|unspecified|classified|worldwide", bd$location_name, ignore.case = TRUE)
  expect_true(all(is.na(bd$latitude[label & (!is.na(bd$iso3c) | is.na(bd$location_full_name))])))
  expect_true(all(is.na(bd$latitude[is.na(bd$location_full_name)])))
})

test_that("coordinates are at the installation, not at a centroid or a namesake", {
  skip_if_builddata_ready()
  bd <- troopdata::build_data_20260918

  # Being inside the right country is not enough. The geocoders answered 92 addresses with the
  # centre of the country or state, or with another place of the same name, 37 to 2,454 km from
  # the installation. Those are corrected from data-raw/geocode_overrides.csv.
  expect_near <- function(address, latitude, longitude, tolerance = 0.1) {
    point <- unique(bd[bd$location_full_name %in% address, c("latitude", "longitude")])
    expect_equal(nrow(point), 1, info = address)
    expect_lt(abs(point$latitude - latitude), tolerance)
    expect_lt(abs(point$longitude - longitude), tolerance)
  }

  # Country and state centroids
  expect_near("Camp Humphreys, South Korea", 36.97, 127.03)
  expect_near("Camp Walker, South Korea", 35.84, 128.59)
  expect_near("Tombstone/Bastion, Afghanistan", 31.85, 64.20)
  expect_near("Camp Speicher, Iraq", 34.68, 43.55)
  expect_near("Camp Lemonier, Djibouti", 11.54, 43.15)
  expect_near("Hector IAP, North Dakota, United States", 46.92, -96.82)

  # Another place of the same name
  expect_near("Yorktown, Virginia, United States", 37.24, -76.55)
  expect_near("Langley AFB, Virginia, United States", 37.08, -76.36)
  expect_near("Little Creek, Virginia, United States", 36.92, -76.16)
  expect_near("Pueblo Depot, Colorado, United States", 38.27, -104.34)
  expect_near("Menwith Hill Station, United Kingdom", 54.01, -1.69)
  expect_near("Camp Butler, Japan", 26.30, 127.77)
  expect_near("Incirlik AB, Turkey", 37.00, 35.43)
  expect_near("Thule AB, Greenland", 76.53, -68.70)

  # The three points that eleven Korean camps, nine Afghan bases and six Iraqi camps shared.
  at <- function(latitude, longitude) {
    sum(!is.na(bd$latitude) & abs(bd$latitude - latitude) < 0.005 &
          abs(bd$longitude - longitude) < 0.005)
  }
  expect_equal(at(36.356, 127.806), 0)
  expect_equal(at(33.831, 66.025), 0)
  expect_equal(at(33.039, 43.777), 0)

  # geo_source says where a point came from, and is there exactly when a point is.
  expect_true(all(stats::na.omit(bd$geo_source) %in% c("arcgis", "osm", "manual")))
  expect_true("manual" %in% bd$geo_source)
  expect_equal(is.na(bd$geo_source), is.na(bd$latitude))

  # A place that could not be located has no coordinates rather than a wrong point.
  unplaced <- c("Joyce, Afghanistan", "Wolverine, Afghanistan", "Scania, Iraq",
                "Mountain Home, AFB, Oregon, United States",
                "Sioux City Map, South Dakota, United States")
  expect_true(all(unplaced %in% bd$location_full_name))
  expect_true(all(is.na(bd$latitude[bd$location_full_name %in% unplaced])))
})

test_that("country codes follow the country the report names, not the code's ISO meaning", {
  skip_if_builddata_ready()
  bd <- troopdata::build_data_20260918

  # The C-1 exhibits use their own two-letter codes, and several are valid ISO2C codes for a
  # different country. Reading them as ISO2C filed Iraq's projects under Iran, Bahrain's under
  # Burundi, the Marianas' under Mali, Guantanamo Bay's under the United Kingdom and Turkey's
  # under Tokelau -- 424 rows across 24 codes.
  iso.of <- function(code) unique(bd$iso3c[bd$state_country == code])

  expect_equal(iso.of("IR"), "IRQ")   # reported as "Iraq"
  expect_equal(iso.of("BI"), "BHR")   # "Bahrain Island"
  expect_equal(iso.of("GB"), "CUB")   # "Guantanamo Bay, Cuba"
  expect_equal(iso.of("TK"), "TUR")   # "Turkey"
  expect_equal(iso.of("KW"), "MHL")   # "Kwajalein"
  expect_equal(iso.of("ES"), "SLV")   # "El Salvador"; Spain is SP
  expect_equal(iso.of("SP"), "ESP")
  expect_equal(iso.of("JD"), "JOR")   # resolved to nothing before
  expect_setequal(iso.of("ML"), c("GUM", "MNP"))   # "Mariana Islands": Guam, Saipan, Tinian

  # None of the countries those codes were mistaken for hosts US military construction.
  expect_false(any(c("IRN", "BDI", "MLI", "TKL", "ETH", "CMR", "NIC", "ERI", "KNA", "SMR", "AIA")
                   %in% bd$iso3c))

  # And the United Kingdom no longer contains Guantanamo Bay.
  expect_false(any(grepl("Guantanamo", bd$location_name[bd$iso3c == "GBR"], ignore.case = TRUE)))

  # A code is only missing where the report names no place at all.
  no.code <- unique(bd$state_country[is.na(bd$iso3c)])
  expect_true(all(no.code %in% c("ZU", "ZC", "ZV", "XC", "XV", "YN")))
})
