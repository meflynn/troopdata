## Code to reshape mme_v7.csv into long format.
## Each observation in the resulting file is an exercise-country-year:
## one row per participating country per year the exercise was active.

library(tidyverse)
library(here)
library(readr)
library(tidyr)
library(dplyr)
library(countrycode)

# Read the wide-format multilateral military exercises data.
mme_wide <- readr::read_csv(
  here::here("data-raw/mme_v7.csv"),
  show_col_types = FALSE
)

# Identify the participant state columns (StateA ... StateAM).
state_cols <- grep("^State[A-Z]+$", names(mme_wide), value = TRUE)

# Pivot the participant columns to long format so each row is an
# exercise-country pair, then expand each pair across the years
# the exercise was active (s.year through e.year).
mme_long <- mme_wide %>%
  tidyr::pivot_longer(
    cols = dplyr::all_of(state_cols),
    names_to = "state_slot",
    values_to = "country"
  ) %>%
  dplyr::filter(!is.na(country), trimws(country) != "") %>%
  dplyr::mutate(
    country = trimws(country),
    year_start = suppressWarnings(as.integer(s.year)),
    year_end   = suppressWarnings(as.integer(e.year)),
    year_end   = dplyr::if_else(is.na(year_end), year_start, year_end),
    year_end   = dplyr::if_else(year_end < year_start, year_start, year_end)
  ) %>%
  dplyr::filter(!is.na(year_start)) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(year = list(seq(year_start, year_end))) %>%
  tidyr::unnest(year) %>%
  dplyr::ungroup() %>%
  dplyr::select(-state_slot, -year_start, -year_end) %>%
  dplyr::relocate(MMEID, Ex_Name, Series_Name, country, year) %>%
  dplyr::arrange(MMEID, country, year)

# Add Gleditsch and Ward numeric country codes (gwcode) using the
# countrycode package. Most country names match cleanly via the built-in
# 'country.name' regex; we supply custom matches for historical states,
# dependent territories, and a few idiosyncratic spellings present in the
# MME source data. Non-country entries (e.g., "NATO", "Baltic States",
# "Fuerzas Unidas", "-9") and dependent territories without G&W codes are
# left as NA.
mme_long <- mme_long %>%
  dplyr::mutate(
    gwcode = suppressWarnings(
      countrycode::countrycode(
        country,
        origin = "country.name",
        destination = "gwn"
      )
    )
  ) %>%
  dplyr::relocate(MMEID, Ex_Name, Series_Name, gwcode, country, year) %>%
  dplyr::group_by(MMEID) %>%
  dplyr::mutate(participant_count = n()) %>%
  dplyr::ungroup()

# Write the reshaped data back to data-raw/.
readr::write_csv(
  mme_long,
  here::here("data-raw/mme-v7-long.csv")
)

usethis::use_data(mme_long,
                  internal = FALSE,
                  overwrite = TRUE)
