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
  dplyr::mutate(year = as.numeric(year)) %>%
  dplyr::ungroup() %>%
  dplyr::select(-state_slot, -year_start, -year_end) %>%
  dplyr::relocate(MMEID, Ex_Name, Series_Name, country, year) %>%
  dplyr::arrange(MMEID, country, year)

# Add Gleditsch and Ward numeric country codes (gwcode) using the
# countrycode package. Most country names match cleanly via the built-in
# 'country.name' regex; the names it cannot code, or codes wrongly, are
# corrected in the step that follows. Non-country entries (e.g., "NATO",
# "Baltic States", "-9") and dependent territories without G&W codes are
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
  # The lookup alone leaves three kinds of error, all corrected here. It has no gwn entry for
  # Yemen or for the G&W microstates, so 122 rows for twelve member states carried no code. It
  # sends "Vietnam" to 815, which in the G&W list is a nineteenth century polity, not the modern
  # state (816). And it codes Serbia as 340 in every year, though the G&W list has no Serbia
  # before 2006; the state in those years is Yugoslavia (345), as in the troop data.
  # Keyed on an ASCII, lower-case copy of the name so accents and capitalization cannot miss.
  dplyr::mutate(
    country_key = tolower(stringi::stri_trans_general(country, "Latin-ASCII")),
    gwcode = dplyr::case_when(
      country_key == "vietnam" ~ 816,
      country_key == "yemen" ~ 678,
      country_key == "dominica" ~ 54,
      country_key == "grenada" ~ 55,
      country_key == "st. lucia" ~ 56,
      country_key == "st. vincent & grenadines" ~ 57,
      country_key == "antigua & barbuda" ~ 58,
      country_key %in% c("st. kitts & nevis", "st. christopher") ~ 60,
      country_key == "sao tome & principe" ~ 403,
      country_key == "seychelles" ~ 591,
      country_key == "vanuatu" ~ 935,
      country_key == "tonga" ~ 972,
      country_key == "palau" ~ 986,
      gwcode == 340 & year < 2006 ~ 345,
      TRUE ~ as.numeric(gwcode)
    )
  ) %>%
  dplyr::select(-country_key) %>%
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
