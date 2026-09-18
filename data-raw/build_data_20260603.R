# ---------------------------------------------------------------------------
# Import & geocode Comptroller Annual Report MILCON projects
#
# - Reads every .xlsx / .xls in the Comptroller Annual Reports folder
#   (PDFs and FY1998/FY1999 are skipped)
# - Standardizes column names so synonymous headers across years collapse
#   into a single canonical column
# - Row-binds everything into one long file of military construction projects
# - Geocodes each project (lon/lat) from its city/state/country
# - Adds country name + Gleditsch & Ward code via {countrycode}
# - Final output is restricted to <=20 analytic columns
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(readxl)
  library(fs)
  library(tidygeocoder)
  library(countrycode)
  library(readr)
  library(tictoc)
})


# First read in a list of relevant files --------------------------------------

file.list <- list.files("~/Dropbox/Projects/Troop Data/Data Files/Construction Spending/Comptroller Annual Reports/",
                        full.names = TRUE)




# Now read in all of the excel files that match the xls file type.
files.xls <- map(
  .x = file.list,
  .f = possibly(read_xls)   # Use this so encountering a bad file doesn't break it.
) %>%
  discard(is.null)   %>%    # drop null entries in file list from file types that don't match.
  discard_at(c(1,2))        # Discard 1998 and 1998 lists because they don't contain useful spending data.


files.xls <- files.xls %>%
  map(.f = janitor::clean_names)


# Apply names for columns to subset of list that doesn't work with the automated line above.

names.2001.2002 <-  c("fiscal_year", "location_code", "location_title", "project_number", "project_title", "state_country", "appn", "comp", "appn_title", "ba", "ba_title", "transaction_type", "auth_amount", "auth_for_appn", "appn_amount", "toa_amount")

files.xls[c(1:2)] <- map(
  files.xls[c(1:2)],
  set_names,
  names.2001.2002
) %>%
  map(.f = janitor::clean_names)




# Do the same for xlsx files

files.xlsx <- map(
  .x = file.list,
  .f = possibly(\(f) read_xlsx(f, skip = 1))   # Use this so encountering a bad file doesn't break it.
) %>%
  discard(is.null)   %>%    # drop null entries in file list from file types that don't match.
  discard_at(c(1,2))        # Discard 1998 and 1998 lists because they don't contain useful spending data.


# Standardize the names using janitor
files.xlsx <- files.xlsx %>%
  map(janitor::clean_names)


# Combine all of the data frames from both lists.
# Must convert all variables to characters so there are no conflicts.
files.combined.df <- c(files.xls, files.xlsx) %>%
  map(\(d) mutate(d, across(everything(),
                            as.character))) %>%
  dplyr::bind_rows() %>%
  dplyr::select(sort(names(.)))



# Coalesce columns with different names but same values into a single column
#
merge_cols <- function(df, into, from) {
df[[into]] <- do.call(coalesce, df[, from, drop = FALSE])
df[, !(names(df) %in% setdiff(from, into))]
}

files.combined.df <- files.combined.df |>
  merge_cols("account_name",
             c("account", "account_title")) |>
  merge_cols("appn_amount",
             c("appropriation_amount", "appn_amount", "appn")) |>

  # ---- authorization ----
  merge_cols("auth_appn_amount",
             c("auth_for_appn",
               "auth_for_appn_amount",
               "authorized_for_appn",
               "authorization_of_approp_amount",
               "authorization_of_appropriation_amount",
               "authorized_for_appropriation_amount"
               )) |>
  merge_cols("auth_amount",
             c("authorization", "authorization_amount")) |>

  # ---- budget activity (code vs title) ----
merge_cols("budget_activity",
           c("budget_activity", "ba")) |>
  merge_cols("budget_activity_title",
             c("budget_activity_title", "ba_title")) |>

  # ---- project (number vs title) ----
merge_cols("project_number",
           c("project_number")) |>
  merge_cols("project_title",
             c("project_title",
               "construction_project_title")) |>

  # ---- facility category (code vs title) ----
merge_cols("facility_category_code",
           c("facility_category_code", "facility_category", "category_code")) |>
  merge_cols("facility_category_title",
             c("facility_category_title", "facility_group_title")) |>

  # ---- location ----
merge_cols("location_name",
           c("location_title")) |>

merge_cols("location_code",
           c("location", "location_code")) |>

  # ---- state / country ----
merge_cols("state_country",
           c("state_country", "state_country_title")) |>

  # ---- organization ----
merge_cols("organization",
           c("organization", "org", "mil_dept_dw", "comp")) |>

  # ---- total obligation authority ----
merge_cols("toa_amount",
           c("toa_amount", "toa", "total_obligation_authority")) %>%

merge_cols("project_number",
           c("project", "project_number"))


# List of names to preserve for the final compilation.
names.preserve <- c(
  "fiscal_year", "appn_amount", "appn_title", "auth_amount", "auth_appn_amount",
  "budget_activity", "budget_activity_short_title",
  "budget_activity_title", "classification", "comp", "construction_project",
  "fiscal_category_title", "dollar_type", "existing_footprint",
  "existing_mission", "facility_category_code", "facility_category_title",
  "location_code", "location_name", "organization", "pe",
  "percent_recapitalization", "project", "project_number", "project_title",
  "state_country", "state_country_sort", "toa_amount", "transaction_type"
)

files.combined.df <- files.combined.df %>%
  dplyr::select(any_of(sort(names.preserve)))



write_csv(files.combined.df,
          here::here("data-raw/build_data_20260604.csv"))

# ----- Geocode locations ----------------------------------------------------

# New function to extract location names
extract_location <- function(x) {
  # 1. Strip "USA-###:" / "DoN-32:" / "USAREUR-12:" prefix (mixed case)
  x <- sub("^[A-Za-z]{2,8}-\\d+:\\s*", "", x)

  # 2. Patterns in priority order. Each pattern is reasonably specific to
  #    a real installation type, so a non-match means "no location info".
  patterns <- c(
    "\\b(?:Fort|Ft\\.?)\\s+[A-Z][A-Za-z'-]+(?:[- ][A-Z][A-Za-z'-]+)?(?:\\s*,\\s*[A-Z]{2}\\b)?",
    "\\bCamp\\s+[A-Z][A-Za-z'-]+(?:\\s*,\\s*[A-Z]{2}\\b)?",
    paste0("\\b(?:NAS|NS|NSB|NWS|NAVSTA|NSA|NSWC|NCBC|NMCRC|NSWCDD)",
           "\\s+[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+){0,2}",
           "(?:\\s*,\\s*[A-Z]{2}\\b)?"),
    paste0("\\b(?:MCAS|MCB|MCRD|MCLB|MCSA)",
           "\\s+[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+){0,2}",
           "(?:\\s*,\\s*[A-Z]{2}\\b)?"),
    paste0("\\b[A-Z][A-Za-z'-]+(?:[- ][A-Z][A-Za-z'-]+)?",
           "\\s+(?:AFB|ANGB|ARB|AAF|ANG)",
           "(?:\\s*,\\s*[A-Z]{2}\\b)?"),
    "\\b[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+)?\\s+Arsenal(?:\\s*,\\s*[A-Z]{2}\\b)?",
    paste0("\\b[A-Z][A-Za-z'-]+",
           "(?:\\s+(?:Army|Naval|Marine|Air|Chemical|Logistics))?",
           "\\s+Depot(?:\\s*,\\s*[A-Z]{2}\\b)?"),
    "\\b[A-Z][A-Za-z'-]+\\s+(?:Naval\\s+)?Shipyard(?:\\s*,\\s*[A-Z]{2}\\b)?",
    "\\b(?:Pentagon|Quantico)\\b",
    "\\b[A-Z][A-Za-z .'-]+?,\\s*[A-Z]{2}\\b"
  )

  out <- rep(NA_character_, length(x))
  for (pat in patterns) {
    todo <- is.na(out)
    if (!any(todo)) break
    matches <- stringr::str_extract_all(x[todo], pat)
    joined <- vapply(matches, function(m)
      if (length(m)) paste(stringr::str_squish(m), collapse = ", ") else NA_character_,
      character(1)
    )
    out[todo] <- joined
  }

  stringr::str_squish(out)   # NA stays NA
}



# Use new function to extract locations

files.combined.df <- files.combined.df %>%
  dplyr::mutate(location_full_name = usdata::abbr2state(state_country),
                location_full_name = case_when(
                  is.na(location_full_name) ~ countrycode::countrycode(state_country, "iso2c", "country.name"),
                  TRUE ~ location_full_name
                ),
                location_full_name = case_when(
                   state_country == "GY" ~ "Germany",
                   TRUE ~ location_full_name
                ),
                location_full_name = extract_location(project_title),
                location_full_name = case_when(
                  is.na(location_full_name) ~ glue::glue("{location_name}, {state_country}"),
                  TRUE ~ glue::glue("{location_name}, {state_country}, {location_full_name}")
                  ),
                location_full_name = case_when(
                  grepl("^NA, NA$", location_full_name) ~ NA,
                  TRUE ~ location_full_name
                ))

# Geocode unique addresses once, then join back -- avoids hammering the API
# with duplicates.

# Wrapper: geocode ONE address with a given method; return NA on any error
# so a single timeout or rate-limit doesn't kill the whole loop.
safe_geocode <- function(address, method) {
  fn <- possibly(\(a) {
    tibble(location_full_name = a) |>
      geocode(address = location_full_name,
              method = method,
              lat = "latitude",
              long = "longitude",
              quiet = TRUE)
  }, otherwise = tibble(location_full_name = address,
                        latitude = NA_real_, longitude = NA_real_))
  fn(address)
}

tic()

# Unique addresses to look up (skip NAs)
addrs <- files.combined.df |>
  distinct(location_full_name) |>
  filter(!is.na(location_full_name)) |>
  pull(location_full_name)

# Pass 1: ArcGIS for everything
arcgis_results <- map_dfr(addrs, safe_geocode, method = "arcgis") |>
  mutate(geo_source = if_else(!is.na(latitude), "arcgis", NA_character_))

# Pass 2: OSM as backstop for addresses ArcGIS couldn't resolve
holdouts <- arcgis_results |> filter(is.na(latitude)) |> pull(location_full_name)

osm_results <- map_dfr(holdouts, safe_geocode, method = "osm") |>
  mutate(geo_source = if_else(!is.na(latitude), "osm", NA_character_))

# Combine: keep ArcGIS hits, fill misses with OSM hits
geo_lookup <- arcgis_results |>
  filter(!is.na(latitude)) |>
  bind_rows(osm_results)

# Join back to the original df
files.combined.df <- files.combined.df |>
  left_join(geo_lookup, by = "location_full_name")

toc()


# Convert variables to numeric where appropriate

numeric_cols <- c(
  "appn_amount",
  "auth_amount",
  "auth_appn_amount",
  "toa_amount",
  "existing_footprint",
  "percent_recapitalization",
  "budget_activity",
  "fiscal_year",
  "latitude",
  "longitude"
)

# Convert numeric columns to numeric. The rest are all character columns.
files.combined.df <- files.combined.df |>
  mutate(across(
    any_of(numeric_cols),
    \(x) suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", x)))
  )) %>%
  dplyr::filter(!grepl("NA, NA*", location_full_name)) # Redundant but just making sure we drop NA locations.


# ----- Add standardized country identifiers ---------------------------------
# state_country mixes US state postal abbreviations (domestic construction) with
# overseas country codes. The overseas codes are themselves a mix of ISO2C
# (e.g. "KW", "PL", "IT") and legacy FIPS 10-4 / DoD codes (e.g. "JA" Japan,
# "UK" United Kingdom, "SP" Spain, "IC" Iceland, "HO" Honduras, "PO" Portugal),
# plus a custom "GY" for Germany. Derive clean Gleditsch and Ward (gwcode) and
# ISO3C identifiers so downstream functions can filter on standard country codes
# rather than the raw two-letter field. US state abbreviations map to the United
# States (gwcode 2, iso3c "USA").

# Custom/ambiguous codes that must be pinned before automatic conversion.
# ("GY" is Guyana in both ISO2C and FIPS, but denotes Germany in this data.)
custom_iso2c <- c(GY = "DE")
state_country_fixed <- dplyr::recode(files.combined.df$state_country,
                                     !!!custom_iso2c)

# Resolve each code by trying ISO2C first, then falling back to FIPS 10-4 for
# the legacy DoD codes. coalesce() keeps the ISO2C hit where both resolve.
to_iso3c <- function(x) {
  dplyr::coalesce(
    suppressWarnings(countrycode::countrycode(x, "iso2c", "iso3c")),
    suppressWarnings(countrycode::countrycode(x, "fips",  "iso3c"))
  )
}
to_gwn <- function(x) {
  dplyr::coalesce(
    suppressWarnings(countrycode::countrycode(x, "iso2c", "gwn")),
    suppressWarnings(countrycode::countrycode(x, "fips",  "gwn"))
  )
}

# US state (and territory) postal abbreviations resolve to a state name via
# usdata::abbr2state(); those rows are domestic and map to the United States.
is_us_state <- !is.na(usdata::abbr2state(files.combined.df$state_country))

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    iso3c  = dplyr::if_else(is_us_state, "USA", to_iso3c(state_country_fixed)),
    gwcode = dplyr::if_else(is_us_state, 2,     to_gwn(state_country_fixed))
  )

# Surface any overseas codes that still failed to resolve so they can be added
# to custom_iso2c above rather than silently dropped from country filtering.
unresolved <- files.combined.df %>%
  dplyr::filter(!is_us_state & is.na(iso3c)) %>%
  dplyr::distinct(state_country) %>%
  dplyr::pull(state_country)
if (length(unresolved) > 0) {
  warning("Unresolved state_country codes (no ISO3C/gwcode): ",
          paste(sort(unresolved), collapse = ", "))
}


write_csv(files.combined.df,
          here::here("data-raw/build_data_20260604.csv"))


library(tidyverse)
library(ggplot2)
library(rnaturalearth)

map.data <- rnaturalearth::ne_countries(scale = 50L, type = "countries")

ggplot() +
  geom_sf(data = map.data, aes(geometry = geometry),
          fill = "white",
          color = "black",
          linewidth = 0.2) +
  geom_point(data = build_data_20260604, aes(x = longitude, y = latitude, color = toa_amount, size = toa_amount))
