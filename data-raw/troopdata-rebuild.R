## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(tidyselect)
library(data.table)
library(haven)
library(here)
library(readxl)
library(furrr)
library(furrr)
library(stringr)
library(countrycode)
library(usmap)
library(pdftools)
#
#
#### Load data and generate names for individual list objects ####
#
# Using the tidyverse package and the read_xlsx function, write a code chunk to load every .xls file in the /Users/michaelflynn/Library/CloudStorage/Dropbox/Projects/Troop Data/Data Files/M05 Military Only folder.
# Load each individual xls file into a list that contains all of the xls files in this folder.
# The list object chould be named "datalist".
#
#


# Load data files from 1950 to 1976
datalist.1950.1977 <- list.files(here("../../Projects/Troop Data/Data Files/M05 Military Only"), pattern = "xls", full.names = TRUE) %>%
  furrr::future_map(.f = readxl::read_xls)

# Read file names into list for 1977 to 2010.
# Use this list to extract dates and names later on.
datalist.1977.2010.names <- list.files(here("../../Projects/Troop Data/Data Files/309A_Reports_1977-2011"), pattern = "\\.xls$", full.names = TRUE)

# Read in actual files from the list
datalist.1977.2010 <- datalist.1977.2010.names %>%
  furrr::future_map(.f = readxl::read_xls)


# Read in file names for 2011 to 2023
datalist.2008.Present.names <- list.files(here("../../Projects/Troop Data/Data Files/2008-Present"), pattern = "\\.xlsx$", full.names = TRUE)

# Read in data files for 2011 to 2023 from the list of file names.
datalist.2008.Present <- datalist.2008.Present.names %>%
  furrr::future_map(.f = readxl::read_xlsx)


# Read in PDF file path for 2003 data and extract relevant information.
datalist.2003.names <- here::here("../../Projects/Troop Data/Data Files/M05 Military Only/m05sep03.pdf")

# Read in PDF file path for 2004 data and extract relevant information.
datalist.2004.names <- here::here("../../Projects/Troop Data/Data Files/M05 Military Only/m05sep04.pdf")




# Add previously cleaned data for 1951, 1952, 2003, and 2004.
# # Also use back values for Iraq and Afghanistan to fill in missing time periods not reported in DoD reports.
# Filter only relevant years
data.gaps <- read_csv(here("../../Projects/Troop Data/Data Files/troopdata_1950_2021.csv")) %>%
  janitor::clean_names() %>%
  #janitor::remove_empty("rows") %>%
  #janitor::remove_empty("cols") %>%
  dplyr::mutate(ccode = countrycode::countrycode(sourcevar = countryname,
                                                 origin = "country.name",
                                                 destination = "gwn",
                                                 warn = TRUE),
                iso3c = countrycode::countrycode(sourcevar = ccode,
                                                 origin = "gwn",
                                                 destination = "iso3c",
                                                 warn = TRUE),
                quarter = 2,
                month =  "June",
                source = "Kane 2006"
  ) %>%
  # Kane codes Serbia as 345 and Vietnam as 817 for the whole series. The G&W system list and the
  # DMDC reports switch to 340 (Serbia) after the 2006 split and 816 (unified Vietnam) after 1975.
  # Without this recode the Kane rows form a parallel series under the superseded code.
  dplyr::mutate(ccode = dplyr::case_when(
    # From 2006, not 2007: the reports frame puts the 2006 Serbia row on 340, and a Kane row is
    # only dropped in favour of the report when the two carry the same code.
    ccode == 345 & year >= 2006 ~ 340,
    ccode == 327 ~ 1003,                # Holy See; the reports frame makes the same recode
    # Kane codes Vietnam as 817 for the whole series, so the post-1975 rows move to 816. 815 is
    # countrycode's answer for a bare "Vietnam". 816 is left alone -- see the note at the long-frame
    # recode below: pre-1976 it is North Vietnam, a state in its own right.
    ccode == 815 & year <= 1975 ~ 817,
    ccode %in% c(815, 817) & year > 1975 ~ 816,
    TRUE ~ ccode
  )) %>%
  dplyr::rename(troops_ad = troops) %>%
  dplyr::filter(ccode != 2) %>%
  dplyr::select(countryname, ccode, iso3c, year, month, quarter, source, troops_ad)




#### Base Dataframe ####
# Add base country-year data frame using COW country codes for 1950 through the present.
year.position <- as.numeric(length(datalist.2008.Present.names))
current.end.year <- str_extract(datalist.2008.Present.names[[year.position]], pattern = "[0-9]{4}.xlsx")
current.end.year <- 2000 + as.numeric(str_extract(current.end.year, pattern = "^[0-9]{2}"))

# Quarter of that same workbook. File names end in YYMM, so 03 -> 1, 06 -> 2, 09 -> 3, 12 -> 4.
# The scaffold below stops here. Without this the March 2026 workbook produced a full set of country
# rows for June, September and December 2026 -- quarters nobody has reported yet -- all holding
# zero, the United States included.
current.end.quarter <- str_extract(datalist.2008.Present.names[[year.position]], pattern = "[0-9]{4}.xlsx")
current.end.quarter <- as.numeric(substr(current.end.quarter, 3, 4)) / 3
stopifnot(current.end.quarter %in% 1:4)


# Use Gleditsch and Ward system data
gw.system.list <- read_delim(here("../../Data Files/Gleditsch System List/ksgmdw.txt"),
                             delim = "\t", locale = readr::locale(encoding = "CP1252")) %>%
  dplyr::bind_rows(
    read_delim(here("../../Data Files/Gleditsch System List/microstates.txt"),
               delim = "\t", locale = readr::locale(encoding = "CP1252"))
  )

# The G&W list is the authority on which states exist, and it is also the fallback for naming them.
# countrycode's gwn -> country.name lookup has no entry for most of the G&W microstates, so those rows
# came out with countryname = NA and were then dropped by filter(!is.na(countryname)) further down:
# 15 states vanished from the panel entirely (Dominica, Grenada, St Lucia, St Vincent, Monaco,
# Liechtenstein, Andorra, San Marino, South Ossetia, Vanuatu, Kiribati, Nauru, Tuvalu, Palau, Samoa)
# while the eight microstates that happen to have an explicit branch in standardize_countryname()
# survived. Which ones made it was an accident of who had written a branch.
#
# Taking the fallback from the system list itself means every G&W state is named, and a state added to
# a future edition of the list is carried automatically rather than silently dropped. Values are
# transliterated to ASCII because the file is CP1252 ("Wurttemberg", "Sao Tome"), and a couple of G&W
# spellings are normalised to the form this package uses elsewhere.
gw.state.names <- gw.system.list %>%
  dplyr::distinct(statenumber, countryname) %>%
  dplyr::group_by(statenumber) %>%
  dplyr::summarise(gw_name = dplyr::first(countryname), .groups = "drop") %>%
  dplyr::mutate(
    gw_name = stringi::stri_trans_general(gw_name, "Latin-ASCII"),
    gw_name = dplyr::case_when(
      statenumber == 990 ~ "Samoa",          # G&W: "Samoa/Western Samoa"
      statenumber == 970 ~ "Kiribati",
      statenumber == 54  ~ "Dominica",       # distinct from 42, the Dominican Republic
      TRUE ~ gw_name
    )
  )

country.year.list <- gw.system.list %>%
  dplyr::rename("ccode" = "statenumber",
                "startyear" = "start",
                "endyear" = "end") %>%
  dplyr::mutate(startyear = as.numeric(format(as.Date(startyear), "%Y")),
                endyear = as.numeric(format(as.Date(endyear), "%Y"))) %>%
  rowwise() %>%
  dplyr::mutate(endyear = case_when(
    endyear == 2020 ~ current.end.year,
    TRUE ~ endyear
  ),
  year = list(seq(startyear, endyear))
  ) %>%
  unnest(year) %>%
  dplyr::filter(year >= 1950) %>%
  dplyr::select(ccode, countryname, year) %>%
  dplyr::group_by(ccode, countryname, year) %>%
  tidyr::expand(month = c("March", "June", "September", "December")) %>%
  dplyr::mutate(quarter = case_when(
    month == "March" ~ 1,
    month == "June" ~ 2,
    month == "September" ~ 3,
    month == "December" ~ 4
  ))

# Generate additional country-year-list containing observations from Kane data that predate states' independent state dates. For example, deployments to Algeria in the 1950s aren't picked up in the GW system because Algeria isn't an independent state at that point. But we don't want to lose those values.

country.year.list.supplement <- data.gaps %>%
  dplyr::filter(troops_ad > 0) %>%
  dplyr::group_by(ccode) %>%
  dplyr::mutate(startyear = first(year),
                endyear = last(year)) %>%
  dplyr::summarise(startyear = mean(startyear),
                   endyear = mean(endyear)) %>%
  dplyr::mutate(endyear = case_when(
    endyear == 2021 ~ current.end.year,
    TRUE ~ endyear
  ),
  duration = endyear - startyear) %>%
  filter(duration > 0) %>%
  rowwise() %>%
  dplyr::mutate(
    year = list(seq(startyear, endyear))
  ) %>%
  unnest(year) %>%
  dplyr::select(ccode, year) %>%
  dplyr::group_by(ccode, year) %>%
  tidyr::expand(month = c("March", "June", "September", "December")) %>%
  dplyr::mutate(quarter = case_when(
    month == "March" ~ 1,
    month == "June" ~ 2,
    month == "September" ~ 3,
    month == "December" ~ 4
  )) %>%
  dplyr::mutate(countryname = countrycode::countrycode(ccode,
                                                       origin = "gwn",
                                                       destination = "country.name"))

# Now we join the two data frames and filter out the distinct country year quarter observations.
#
# NOTE: country.year.list is still grouped by (ccode, countryname, year) from the group_by() +
# expand() above, and distinct() silently adds the grouping variables to its key. That kept two
# scaffold rows for every state whose G&W list spelling differs from the countrycode spelling
# ("Rumania"/Romania, "Korea, Republic of"/South Korea, "Cote D'Ivoire"/Ivory Coast, ...). Each
# report row then joined to both, and the summarise(sum) below added them, doubling ~23 countries
# in every year. Ungroup and drop countryname here; countryname is rebuilt from ccode downstream.
country.year.list.base <- country.year.list %>%
  dplyr::ungroup() %>%
  dplyr::select(ccode, year, month, quarter)

# Last year the Gleditsch and Ward system list says each state existed. Derived from the G&W
# expansion BEFORE the Kane supplement is bound in, so a stray supplement row cannot stretch a state
# past its own dissolution: ccode 265 (East Germany) carried empty rows through 2005, fifteen years
# after the DDR ceased to exist, because the supplement spans first(year)-last(year) per code.
gw.state.endyear <- country.year.list.base %>%
  dplyr::group_by(ccode) %>%
  dplyr::summarise(gw_endyear = max(year), .groups = "drop")

# A state whose end year is the latest in the list has not ended -- the G&W file marks a still-extant
# state with its own vintage year, which the read above remaps to current.end.year. Comparing against
# the maximum rather than a hard-coded year is self-calibrating: if that marker ever changes, extant
# states still come out unbounded instead of having the series silently truncated. Only terminated
# states are kept here, so every other code (and every custom territory code the G&W list does not
# carry at all) is absent from the lookup and goes unbounded.
gw.extant.endyear <- max(gw.state.endyear$gw_endyear)

gw.state.endyear <- gw.state.endyear %>%
  dplyr::filter(gw_endyear < gw.extant.endyear)

message("Binding ", nrow(gw.state.endyear), " terminated states to their G&W end year; ",
        "states extant through ", gw.extant.endyear, " are left unbounded.")

# The supplement exists only to cover years the G&W system list does not (deployments to states
# before independence). Restricting it to state-years the base list lacks stops it from
# manufacturing a second series for states that are already covered under a different code.
country.year.list.supplement <- country.year.list.supplement %>%
  dplyr::ungroup() %>%
  dplyr::select(ccode, year, month, quarter) %>%
  dplyr::anti_join(dplyr::distinct(country.year.list.base, ccode, year),
                   by = c("ccode", "year"))

country.year.list <- country.year.list.base %>%
  bind_rows(country.year.list.supplement) %>%
  distinct(ccode, year, quarter, month) %>%
  # Nothing past the latest workbook: a quarter with no report is absent, not zero.
  dplyr::filter(!(year == current.end.year & quarter > current.end.quarter)) %>%
  arrange(ccode, year, quarter)

# Guard: the scaffold must be unique on ccode-year-month-quarter or every joined report value is
# counted once per duplicate row.
stopifnot(!any(duplicated(country.year.list)))


# Pull names from the data frames and use them to generate names for each data frame in the list.
names.1950.1977 <- future_map(.x = seq_along(datalist.1950.1977),
                              .f = ~ str_extract(datalist.1950.1977[[.x]][[1]],
                                                 pattern = "September\\s{1}([0-9]{4})|June\\s{1}([0-9]{4})") %>%
                                as.data.frame()
) %>%
  bind_rows() %>%
  drop_na()

listnames.1950.1977 <- as.vector(names.1950.1977[[1]])

# Basic data cleaning for 1950 to 1977
data.clean.1950.1977 <- datalist.1950.1977 %>%
  furrr::future_map(.f = ~ .x %>%
                      janitor::clean_names() %>%
                      janitor::remove_empty("rows") %>%
                      janitor::remove_empty("cols")
  )

# Assign names to the data frames
names(data.clean.1950.1977) <- listnames.1950.1977



# Basic data cleaning for 1977 to 2011
data.clean.1977.2010 <- datalist.1977.2010 %>%
  furrr::future_map(.f = ~ .x %>%
                      janitor::clean_names() %>%
                      janitor::remove_empty("rows") %>%
                      janitor::remove_empty("cols")
  )

# Pull years from file list for the 1976 to 2011 data.
listnames.1977.2010 <- future_map(.x = seq_along(datalist.1977.2010.names),
                                  .f = ~ str_extract(datalist.1977.2010.names[[.x]],
                                                     pattern = "September_([0-9]{4})|June_([0-9]{4})") %>%
                                    as.data.frame()
) %>%
  bind_rows() %>%
  drop_na()

# Create an actual list of the months and years for naming list
listnames.1977.2010 <- as.vector(listnames.1977.2010[[1]]) %>%
  str_replace_all(pattern = "_", replacement = " ")

names(data.clean.1977.2010) <- listnames.1977.2010



# Basic data cleaning for 2008 to Present

data.clean.2008.Present <- datalist.2008.Present %>%
  furrr::future_map(.f = ~ .x %>%
                      janitor::clean_names() %>%
                      janitor::remove_empty("rows") %>%
                      janitor::remove_empty("cols")
  )

# Pull years and months from the file list for the 2008 to Present Data
listnames.2008.Present <- future_map(.x = seq_along(datalist.2008.Present.names),
                                     .f = ~ str_extract(datalist.2008.Present.names[[.x]],
                                                        pattern = "_([0-9]{4})") %>%
                                       as.data.frame()
) %>%
  bind_rows() %>%
  drop_na() %>%
  dplyr::rename("Date" = 1) %>%
  dplyr::mutate(Date = str_replace_all(Date, pattern = "_", replacement = "20"),
                Year = str_extract(Date, pattern = "^[0-9]{4}"),
                Month = str_extract(Date, pattern = "[0-9]{2}$"),
                Month = month.name[as.numeric(Month)],
                Date = glue::glue("{Month} {Year}"))

listnames.2008.Present <- as.vector(listnames.2008.Present[[1]])

names(data.clean.2008.Present) <- listnames.2008.Present



#### Name Columns ####

# Create separate list objects containing the data frames for time periods that have the same spreadsheet formatting.
# Each list object should only contain data frames with the same formatting and number of columns.

# Subset data for 1950 to 1953, 1954 to 1956, 1957 to 1967, and 1968 to 1976.
data.clean.1950.1953 <- data.clean.1950.1977[c(1:2)]

data.clean.1954.1956 <- data.clean.1950.1977[c(3:5)]

data.clean.1957.1967 <- data.clean.1950.1977[c(6:16)]

data.clean.1968.1976 <- data.clean.1950.1977[c(17:25)]

# Subset the data for 2008 to 2023 to only include data from September 2008 to June 2023. This is all of the pre-Space Force data.
data.clean.September.2008.June.2023 <- data.clean.2008.Present[c(1:45)]

# This is where space force comes into the data
data.clean.September.2023.Present <- data.clean.2008.Present[c(46:length(data.clean.2008.Present))]


# Create names to match the column orderings from the four lists of data frames.

names.1950.1953 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                     "Navy Ashore", "Navy Temporary Ashore", "Navy Other", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1954.1956 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                     "Navy Ashore", "Navy Afloat", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1957.1967 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                     "Navy Ashore", "Navy Temporary Ashore", "Navy Other", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1968.1976 <- c("Location", "Total Ashore", "Total Afloat", "Total", "Army Total", "Navy Ashore", "Navy Afloat", "Navy Total", "Marine Corps Ashore", "Marine Corps Afloat", "Marine Corps Total", "Air Force Total")

names.1977.2010 <- c("Location", "Total", "Army Total", "Navy Total", "Marine Corps Total", "Air Force Total")

names.2008.2023 <- c("Macro Location", "Location", "Army Active Duty", "Navy Active Duty", "Marine Corps Active Duty", "Air Force Active Duty", "Coast Guard Active Duty", "Total Active Duty", "Army National Guard", "Army Reserve", "Navy Reserve", "Marine Corps Reserve", "Air National Guard", "Air Force Reserve", "Coast Guard Reserve", "Total Selected Reserve", "Army Civilian", "Navy Civilian", "Marine Corps Civilian", "Air Force Civilian", "DOD Civilian", "Total Civilian", "Grand Total")

names.2023.Present <- c("Macro Location", "Location", "Army Active Duty", "Navy Active Duty", "Marine Corps Active Duty", "Air Force Active Duty", "Space Force Active Duty", "Coast Guard Active Duty", "Total Active Duty", "Army National Guard", "Army Reserve", "Navy Reserve", "Marine Corps Reserve", "Air National Guard", "Air Force Reserve", "Coast Guard Reserve", "Total Selected Reserve", "Army Civilian", "Navy Civilian", "Marine Corps Civilian", "Air Force Civilian", "DOD Civilian", "Total Civilian", "Grand Total")



# Apply names and remove uninformative or rows
data.clean.1950.1953 <- data.clean.1950.1953 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.1950.1953) %>%
                      slice(-c(1:2)) %>%
                      filter(!is.na(Location))
  )

data.clean.1954.1956 <- data.clean.1954.1956 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.1954.1956) %>%
                      slice(-c(1:2)) %>%
                      filter(!is.na(Location))
  )

data.clean.1957.1967 <- data.clean.1957.1967 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.1957.1967) %>%
                      slice(-c(1:2)) %>%
                      filter(!is.na(Location))
  )

data.clean.1968.1976 <- data.clean.1968.1976 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.1968.1976) %>%
                      slice(-c(1:2)) %>%
                      filter(!is.na(Location))
  )

data.clean.1977.2010 <- data.clean.1977.2010 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.1977.2010) %>%
                      slice(-c(1:2)) %>%
                      filter(!is.na(Location)) %>%
                      slice_head(n = 196) # Remove the last rows that show OIF and OEF totals for select countries. These values represent the portion of the total deployed force that is dedicated to Iraq and Afghanistan. We don't need to add these in.
  )

data.clean.September.2008.June.2023 <- data.clean.September.2008.June.2023 %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.2008.2023) %>%
                      slice(-c(1:5)) %>%
                      filter(!is.na(Location))
  )


# Territories that DMDC lists inside the UNITED STATES block.
#
# From March 2025 the sheets carry Guam, the Northern Marianas, Puerto Rico and the Virgin Islands
# twice: once inside the UNITED STATES block, holding the personnel the Army reports there (plus
# three Coast Guard for the Northern Marianas), and once under OVERSEAS, holding every other service
# with Army at zero. The two rows are different people, not a duplicate. The country pipeline skips
# the whole UNITED STATES block by row position, so the first set was counted nowhere: Puerto Rico
# for March 2025 came out at 645 rather than 759, Guam at 6,795 rather than 6,989.
#
# These are overseas locations, not part of the United States. The rows are kept under their own
# territory's country code and relabeled so they stay distinct from the OVERSEAS row of the same
# name: "GUAM" and "PUERTO RICO" are spelled identically in both blocks, and the international
# frame keeps only the largest row for a given code and name. The reports frame therefore shows
# both rows, as DMDC lists them, and the country-year frame, which sums the report rows under a
# code, carries the territory's full figure.
us.block.territories <- c("GUAM" = "GUAM (LISTED WITH STATES)",
                          "NORTHERN MARIANA" = "NORTHERN MARIANA (LISTED WITH STATES)",
                          "PUERTO RICO" = "PUERTO RICO (LISTED WITH STATES)",
                          "VIRGIN ISLANDS" = "VIRGIN ISLANDS (LISTED WITH STATES)")

# Works on one workbook frame, before the rows with no Location are dropped, because the blank
# Location on the UNITED STATES TOTAL line is what marks the end of the block.
relabel_us_block_territories <- function(df, labels) {

  location <- stringr::str_squish(stringr::str_to_upper(as.character(df$Location)))
  blank <- is.na(location) | location == ""
  started <- cumsum(!blank & location == "ALABAMA") > 0
  ended <- cumsum(started & blank) > 0
  hit <- started & !ended & location %in% names(labels)

  df$Location[hit] <- unname(labels[location[hit]])
  df
}

data.clean.September.2023.Present <- data.clean.September.2023.Present %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.2023.Present) %>%
                      slice(-c(1:5)) %>%
                      relabel_us_block_territories(us.block.territories) %>%
                      filter(!is.na(Location))
  )

# Note that each region has an "afloat" category attached. We'll have to deal with this and treat it as its own country/location.


# Use countrycode package to generate COW country codes for individual countries listed in each list object data frame.

# Generate custom dictionary for countrycode package to match country names that do not have a corresponding Correlates of War country code.
# Pattern is full name first then corresponding number for COW code, separated by equals sign.

# ---------------------------------------------------------------------------
# United States block of a DMDC location sheet
# ---------------------------------------------------------------------------
# The 2008-onward sheets list the states and DC in a block at the top, closed by a "UNITED STATES
# TOTAL" line, with everything else under "OVERSEAS" below it. The US total used to be built by
# keeping every row whose Location usmap::fips() recognises, wherever it sat in the sheet. Two
# OVERSEAS rows pass that test: Puerto Rico, and Georgia the country, which shares its name with the
# state. Both were being added into the United States figure -- Puerto Rico at up to 725 personnel a
# quarter, Georgia at up to 84 -- and Georgia was then counted again under its own code.
#
# The block is found by POSITION, not by its label. The label ("UNITED STATES") sits in the sheet's
# first column, and that column cannot be relied on here: read_xlsx() names it after the sheet's
# title cell, the title was reworded in December 2017 and again in March 2022, and rbindlist(fill = TRUE)
# binds by name. So for every workbook after the first wording the label column lands beyond the
# select(1:24) that follows the bind and arrives here as NA. An earlier version of this function
# filtered on that label and silently dropped every United States row from December 2017 to June
# 2023 (US troops_ad = 0 for 20 quarters). Do not key anything in this script on `Macro Location`.
#
# Rule: start at the ALABAMA row, stop at the first row with no Location (the UNITED STATES TOTAL
# line), and inside that span keep only the fifty states and DC, by name. The span is not just the
# states -- it also holds ARMED FORCES EUROPE / PACIFIC / THE AMERICAS, an unknown-location row
# (UNKNOWN, ZZ-UNKNOWN or UNDEFINED) and, in the 2025 workbooks, GUAM, NORTHERN MARIANA, PUERTO RICO
# and VIRGIN ISLANDS -- so it is 54, 55 or 58 rows long, never 51. Naming the states, rather than
# testing fips(), keeps the result independent of which territories the installed usmap recognises
# and keeps the Puerto Rico row that appears there from 2025 out of the United States figure.
# Checked against all 55 workbooks: exactly 51 rows in every one, no duplicates.
keep_us_block <- function(df) {

  us.state.names <- toupper(c(datasets::state.name, "District of Columbia"))

  out <- df %>%
    tibble::as_tibble() %>%
    dplyr::group_by(source) %>%
    dplyr::mutate(
      location_key = stringr::str_squish(stringr::str_to_upper(as.character(Location))),
      location_missing = is.na(location_key) | location_key == "",
      block_started = cumsum(!location_missing & location_key == "ALABAMA") > 0,
      block_ended = cumsum(block_started & location_missing) > 0
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(block_started, !block_ended, location_key %in% us.state.names) %>%
    dplyr::select(-location_key, -location_missing, -block_started, -block_ended)

  # Every workbook must give exactly the fifty states and DC. Anything else means a sheet layout
  # this rule does not understand, and the United States figure for that quarter is wrong.
  rows.per.source <- table(factor(out$source, levels = unique(df$source)))
  wrong <- rows.per.source[rows.per.source != length(us.state.names)]
  if (length(wrong) > 0) {
    warning("keep_us_block(): expected ", length(us.state.names),
            " state and DC rows per workbook, found ",
            paste0(names(wrong), " = ", as.integer(wrong), collapse = "; "),
            call. = FALSE)
  }

  out
}

# The same block for ONE workbook frame, with the header row above it, for the state-level data.
# The state frames used fixed row ranges -- slice(5:58), slice(8:58), slice(5:62) -- but the block
# is 54, 55 or 58 rows long and starts on row 6 or row 9 depending on the workbook, so a fixed range
# cut the end of the alphabet off: Wyoming was missing from 18 quarters, West Virginia, Wisconsin
# and Wyoming from 9 more, and Washington as well in 6 of those (27 of 55 quarters short of 51).
# Returns the service-label header row (the row above ALABAMA) through the last row before the
# UNITED STATES TOTAL line, so row_to_names(1) downstream works exactly as it did.
slice_us_block <- function(df) {

  location <- stringr::str_squish(stringr::str_to_upper(as.character(df[[2]])))
  first <- match("ALABAMA", location)
  if (is.na(first) || first < 2) {
    stop("slice_us_block(): no ALABAMA row with a header row above it.", call. = FALSE)
  }

  blank <- which(is.na(location) | location == "")
  blank <- blank[blank > first]
  last <- if (length(blank) > 0) blank[1] - 1 else length(location)

  dplyr::slice(df, (first - 1):last)
}

# ---------------------------------------------------------------------------
# gwn -> iso3c gap table
# ---------------------------------------------------------------------------
# countrycode has no gwn -> iso3c entry for the G&W microstates, the territory codes this build adds,
# or several historical states, so without this those rows hold iso3c = NA and no ISO3C filter can
# reach them: 981 rows and 360,304 reported personnel in the country-year frame, concentrated in the
# dependencies that host the largest installations (Greenland/Thule, Bermuda, the Azores/Lajes, Diego
# Garcia). One table, used by both the reports frame and the country-year frame, so the two cannot
# drift apart.
#
# Three conventions, in order of preference:
#
#   1. The unit's own ISO 3166-1 alpha-3, where it has one: GRL, BMU, GIB, VIR, ASM, IOT, ABW, VGB,
#      TCA, ESH, KIR, ATA.
#   2. The retired ISO 3166-3 alpha-3, for a state that has since dissolved. This is the convention
#      already used for DDR and YMD: YUG (Yugoslavia), ANT (Netherlands Antilles), CSK, VDR.
#   3. The parent state's or parent territory's code, for a sub-national unit with no code of its
#      own: PRT (Azores), CHL (Easter Island), MYS (Sarawak), TZA (Zanzibar), CHN (Tibet), GEO
#      (Abkhazia), SHN (Ascension, with St. Helena), MHL (Eniwetok, with the Marshalls), UMI (Wake,
#      Midway and Johnston, which are all US Minor Outlying Islands).
#
# Convention 3 deliberately makes one ISO3C span more than one ccode -- Lajes is in Portugal, so
# host = "PRT" should reach it. Anyone aggregating by iso3c must therefore sum across ccodes, and
# get_troopdata() warns when an ISO3C filter returns a code covering several ccodes.
#
# Deliberately left NA: 1032 British West Indies (a dissolved federation with no ISO code and several
# successor states), 1038 Kashmir (disputed, no code), 1017 Spratly Islands (disputed, no code) and
# 10200, personnel afloat, who are in no country. Keys are character because the lookup is by name.
custom.iso3c <- c(
  # Microstates and historical states the gwn lookup misses
  "6" = "PRI",      # Puerto Rico (custom code)
  "54" = "DMA", "55" = "GRD", "56" = "LCA", "57" = "VCT", "221" = "MCO",
  "223" = "LIE", "232" = "AND", "331" = "SMR", "935" = "VUT", "970" = "KIR",
  "971" = "NRU", "973" = "TUV", "986" = "PLW", "990" = "WSM",
  "397" = "GEO",    # South Ossetia -> Georgia, as 396 Abkhazia already is
  "58" = "ATG", "60" = "KNA", "265" = "DDR", "315" = "CSK", "345" = "YUG",
  "347" = "XKX", "403" = "STP", "591" = "SYC", "678" = "YEM", "680" = "YMD",
  "817" = "VNM", "972" = "TON", "983" = "MHL", "987" = "FSM",
  # Dependencies and territories with an ISO 3166-1 code of their own
  "1001" = "GIB", "1002" = "GRL", "1003" = "VAT", "1004" = "IOT", "1007" = "BMU",
  "1008" = "GUM", "1009" = "HKG", "1011" = "MNP", "1013" = "VIR",
  "1016" = "ANT", "1019" = "ABW", "1030" = "KIR", "1034" = "ESH",
  "1035" = "VGB", "1037" = "TCA", "1041" = "ASM", "10000" = "ATA",
  "1023" = "SJM",   # Svalbard (Svalbard and Jan Mayen)
  "1025" = "CUW", "1026" = "MTQ", "1027" = "SXM",
  # Sub-national units, carrying the code of the state or territory they belong to
  "396" = "GEO",    # Abkhazia -> Georgia
  "511" = "TZA",    # Zanzibar -> Tanzania
  "711" = "CHN",    # Tibet -> China
  "1005" = "SHN",   # St. Helena -> St Helena, Ascension and Tristan da Cunha
  "1012" = "UMI",   # Midway Islands -> US Minor Outlying Islands
  "1014" = "UMI",   # Wake Island -> US Minor Outlying Islands
  "1031" = "CHL",   # Easter Island -> Chile
  "1033" = "MYS",   # Sarawak -> Malaysia
  "1040" = "PRT",   # Azores -> Portugal
  "1042" = "SHN",   # Ascension Island -> St Helena, Ascension and Tristan da Cunha
  "10100" = "UMI",  # Johnston Island -> US Minor Outlying Islands
  "10101" = "MHL",  # Eniwetok -> Marshall Islands
  "1018" = "ARE",   # Trucial States -> United Arab Emirates, the same territory
  "1021" = "GBR",   # Akrotiri -> United Kingdom (a Sovereign Base Area, with no code of its own)
  "1022" = "AUS",   # Coral Sea Islands -> Australia (an external territory, with no code of its own)
  "1024" = "ATF"    # Bassas da India -> French Southern Territories, which administers it
)

# ccode 816 is not in the table because its code depends on the year: the Democratic Republic of
# Vietnam (VDR) while the country was divided, unified Vietnam (VNM) from 1976. Applied separately in
# both frames.
fill_iso3c <- function(iso3c, ccode, year) {
  out <- dplyr::coalesce(iso3c, unname(custom.iso3c[as.character(ccode)]))
  dplyr::case_when(
    ccode == 816 & year <= 1975 ~ "VDR",
    ccode == 816 ~ "VNM",
    TRUE ~ out
  )
}

custom.gwn <- c("Alaska" = 2,
                "ALASKA (Including Aleutians and North Pacific Area)" = 2,
                "Hawaii" = 2,
                "Hawaiian Islands" = 2,
                "Caton Island" = 2,
                "Puerto Rico" = 6,
                "PUERTO RICO" = 6,
                "Costa Rico" = 94,
                "Surinam" = 115,
                "Suriname" = 115,
                "Surinam (Netherlands Guiana)" = 115,
                "Columbia" = 100,
                "Volcano Islands (Iwo Jima)" = 740,
                "Iwo Jima (Volcano Islands)" = 740,
                "Volcano Islands (Including Iwo Jima)" = 740,
                "England (& Wales)" = 200,
                "Scotland" = 200,
                "Canal Zone" = 95,
                "Panama Canal Zone" = 95,
                "Trieste" = 325,
                "Italy/Sardinia" = 325,
                "Italy" = 325,
                "Serbia" = 340,          # G&W: 340 (COW uses 345)
                "SERBIA" = 340,
                "SERBIA (1992 - 2004)" = 340,
                "SERBIA (2006 - 2008)" = 340,
                "Bosnia & Herzegovina" = 346,
                "Bosnia and Herzegovina" = 346,
                "Russia" = 365,
                "Russia (Soviet Union)" = 365,
                "Belarus (Byelorussia)" = 370,
                "Belarus" = 370,
                "Abkhazia" = 396,
                "Burkina Faso (Upper Volta)" = 439,
                "Burkina Faso" = 439,
                "Congo - Brazzaville" = 484,
                "Congo" = 484,
                "Democratic Republic of the Congo" = 490,
                "Congo - Kinshasa" = 490,
                "Jerusalem" = 666,
                "Bahrein Island" = 692,
                "Bahrein" = 692,
                "French Somaliland" = 520,
                "Somali Republic" = 520,
                # Note that this is coded as Eritrea because the actual deployment location appears to be within Eritrean territory. See https://uca.edu/politicalscience/home/research-projects/dadm-project/sub-saharan-africa-region/ethiopia-1942-present/#:~:text=The%20U.S.%20government%20provided%20military,Kagnew%20communications%20station%20in%20Asmara.

                "Ethiopia and Eritrea" = 530,
                "Ethiopia (Inc. Eritrea)" = 530,
                "Ethiopia (Incl Eritrea)" = 530,
                "Zimbabwe (Rhodesia)" = 552,
                "Zimbabwe" = 552,
                "Cameroun" = 471,
                "Tangier" = 600,
                "Iran" = 630,
                "Iran (Persia)" = 630,
                "Bonin Island" = 740,
                "Ryukyus (Okinawa)" = 740,
                "Ryukyu Islands" = 740,
                "Bonin Islands" = 740,
                "Hong Kong" = 710,
                "Hong Kong (& China)" = 710,
                "China (Includes Hong Kong)" = 710,
                "North Korea" = 731,
                "Korea, People's Republic of" = 731,
                "South Korea" = 732,
                "Korea, Republic of" = 732,
                "Myanmar (Burma)" = 775,
                "Myanmar" = 775,
                "Sri Lanka (Ceylon)" = 780,
                "Sri Lanka" = 780,
                "Cambodia (Kampuchea)" = 811,
                "Cambodia" = 811,
                "South Viet-Nam" = 817,
                "Malaya" = 820,
                "Malaya, States of" = 820,
                "States of Malaya" = 820,
                "Fiji" = 950,
                "Fiji and Tonga" = 950,
                "Caroline Islands" = 987,
                "Taiwan" = 713,
                "Formosa (& Pescadores)" = 713,
                "Indo-China" = 817,
                "Gibraltar" = 1001,
                "Gibralter" = 1001,
                "Gilbraltar" = 1001,
                "GIBRALTAR" = 1001,
                "Greenland" = 1002,
                "Greenland*" = 1002,
                "GREENLAND" = 1002,
                "Diego Garcia" = 1004,
                "St. Helena" = 1005,
                "St. Helena (Inc. Ascension)" = 1005,
                "St Helena (Incl. Ascension Is.)" = 1005,
                "St. Helena (Incl. Ascension Is.)" = 1005,
                "St. Helena (Includes Ascension Island)" = 1005,
                "Antigua" = 58,          # G&W microstate: 58 (already correct)
                "Bermuda" = 1007,
                "Mariana Islands (Including Guam)" = 1008,
                "Mariana Islands (Guam)" = 1008,
                "NORTHERN MARIANA ISLANDS" = 1011, # Its own territory, not Guam (1008)
                "Guam" = 1008,
                "GUAM" = 1008,
                "Hong Kong" = 1009,
                "HONG KONG" = 1009,
                "Hong Kong (& China)" = 1009,
                "Hong Kong" = 1009, # Note this conflicts with the entry above. Address this below by making values after 1997 go to China.
                "Mariana Islands" = 1011,
                "Marshall Islands (Kwajelein)" = 983, # G&W Marshall Islands, not the Marianas
                "Northern Mariana Islands" = 1011,
                "Midway Island" = 1012,
                "Midway" = 1012,
                "Midway Islands" = 1012,
                "Virgin Islands" = 1013,
                "U.S. Virgin Islands" = 1013,
                "U. S. Virgin Islands" = 1013,
                "Virgin Islands (U.S.)" = 1013,
                "VIRGIN ISLANDS (U.S.)" = 1013,
                "VIRGIN ISLANDS, U.S." = 1013,
                "Wake Island" = 1014,
                "WAKE ISLAND" = 1014,
                "Scabo Verde" = 1015,
                "Netherlands Antilles" = 1016,
                "NETHERLANDS ANTILLES (1991 - 2010)" = 1016,
                "NETHERLANDS ANTILLES" = 1016,
                "Spraatly Islands" = 1017,
                "Trucial States" = 1018,
                "Aruba" = 1019,
                "Aruba BWI" = 1019,
                "Akrotiri" = 1021,
                "Coral Sea Islands" = 1022,
                "Svalbard" = 1023,
                "Bassas da India" = 1024,
                "Curacao" = 1025,
                "Martinique" = 1026,
                "Sint Maarten" = 1027,
                "Fiji" = 950,            # G&W microstate: 950 (was 1028)
                "Fiji and Tonga" = 950,  # G&W microstate: 950 (was 1028)
                "Aden" = 678,            # G&W code for Republic of Yemen
                "Line Islands" = 1030,
                "Easter Island" = 1031,
                "British West Indies" = 1032,
                "British West Indies Federation" = 1032,
                "British West Indies (Excluding Jamaica & Trinidad)" = 1032,
                "Sarawak" = 1033,
                "Western Sahara" = 1034,
                "British Virgin Islands" = 1035,
                "Leward Islands" = 1035,
                "Leeward Islands" = 1035,
                "Seychelles" = 591,      # G&W microstate: 591 (was 1036)
                "Turks and Caicos Islands" = 1037,
                "Turks Island" = 1037,
                "Kashmir" = 1038,
                "Azores" = 1040,
                "Azore Islands" = 1040,
                "American Samoa" = 1041,
                "AMERICAN SAMOA" = 1041,
                "Samoa (American)" = 1041,
                "Ascension Island" = 1042,
                "Antarctica" = 10000,
                "Project Deep Freeze (Antarctica)" = 10000,
                "Antarctic Region" = 10000,
                "Project Deep Freeze (Antartica)" = 10000,
                "Johnston Island" = 10100,
                "Johnston Atoll" = 10100,
                "Eniwetok (J.T.F. 7)" = 10101)

# The territory rows from the UNITED STATES block, under the labels relabel_us_block_territories()
# gives them. Built from us.block.territories so the two cannot drift apart.
custom.gwn <- c(custom.gwn,
                setNames(c(1008, 1011, 6, 1013),
                         unname(us.block.territories[c("GUAM", "NORTHERN MARIANA",
                                                       "PUERTO RICO", "VIRGIN ISLANDS")])))

# Location names that reached no country code at all, found by comparing every row of every
# report against the reports frame. A row with no code is dropped without a message at the
# filter(ccode != 2) below, so each of these was silently absent from the data.
#
# countrycode's gwn lookup has no entry for Yemen or for the G&W microstates, so the scaffold
# carried those states at zero while their reported personnel were thrown away: Yemen read 0 for
# 1991-2026 against up to 280 reported, the Marshall Islands 0 from 1956 against up to 3,451
# (Kwajalein). "Serbia (includes Kosovo)" matches two countries and so resolved to neither, which
# dropped the Kosovo force of 1999-2007 (6,410 in September 1999). Diego Garcia is reported as
# "BRITISH INDIAN OCEAN TERRITORY" from 2008 and had no rows after 2007.
custom.gwn <- c(custom.gwn,
                # G&W states
                "Yemen" = 678,
                "YEMEN" = 678,
                "Marshall Islands" = 983,
                "MARSHALL ISLANDS" = 983,
                "Federated States of Micronesia" = 987,
                "MICRONESIA, FEDERATED STATES OF" = 987,
                "Caroline Islands (Truk, Palau)" = 987,
                "Palau" = 986,
                "PALAU" = 986,
                "KIRIBATI" = 970,
                "Tonga" = 972,
                "TONGA" = 972,
                "Seychelles Islands" = 591,
                "Seychelles Island" = 591,
                "SEYCHELLES" = 591,
                "SAMOA" = 990,
                "Antigua and Barbuda" = 58,
                "ANTIGUA AND BARBUDA" = 58,
                "Leeward Islands (Antigua)" = 58,
                "Grenada" = 55,
                "DOMINICA" = 54,
                "SAINT KITTS AND NEVIS" = 60,
                "St. Christopher-Nevis-Anguilla" = 60,
                "SAINT LUCIA" = 56,
                "Winward Islands (St. Lucia)" = 56,
                "Nauru" = 971,
                "LIECHTENSTEIN" = 223,
                "Serbia (includes Kosovo)" = 340, # recoded to 345 before 2006 with the other Serbia rows
                # Territories this build already has a code for, under a spelling it did not know
                "BRITISH INDIAN OCEAN TERRITORY" = 1004, # Diego Garcia
                "BERMUDA" = 1007,
                "ARUBA" = 1019,
                "VIRGIN ISLANDS, BRITISH" = 1035,
                "ANTARCTICA" = 10000,
                "Samoan Islands" = 1041,
                # Names the regex lookup sends to the wrong country
                "Netherlands West Indies (Aruba)" = 1019, # was matching the Netherlands
                "Netherlands West Indies" = 1016)         # was matching the Netherlands

# Nine territories that have had a custom code since the first build and had never reached the
# data. Their entries above are in title case ("Akrotiri", "Trucial States", "Spraatly Islands"),
# the 2008-onward workbooks write every name in capitals, and custom_match is exact and case
# sensitive, so none of them ever matched: seven fell through with no code and were dropped, and
# two were given another country's code by the name lookup (BASSAS DA INDIA matched India, TRUCIAL
# STATES matched Oman). The names below are spelled as the workbooks spell them. Each code has an
# entry in custom.iso3c and a region in both frames.
custom.gwn <- c(custom.gwn,
                "SPRATLY ISLANDS" = 1017,
                "TRUCIAL STATES" = 1018,
                "AKROTIRI" = 1021,
                "CORAL SEA ISLANDS" = 1022,
                "SVALBARD" = 1023,
                "BASSAS DA INDIA" = 1024,
                "CURACAO" = 1025,
                "MARTINIQUE" = 1026,
                "SINT MAARTEN" = 1027)

# Spellings of Alaska and Hawaii that had no entry, so those rows carried no code and reached
# neither the United States figure nor any other: Alaska in June 1954 and 1955, Hawaii in
# September 2005. "Malayan Area (Including Singapore)" (September 1957) matches two countries and
# so resolved to neither.
custom.gwn <- c(custom.gwn,
                "ALASKA (& Aleutians)" = 2,
                "Hawaii *" = 2,
                "Malayan Area (Including Singapore)" = 820)

# Rows the name lookup gives a country code although they are not that country. These are
# regional subtotals that match Russia ("soviet union", "ussr"): for 1971-1976 and 1992-2007 the
# figure stored for Russia was the total for the whole region, and Russia's own row was the one
# discarded.
not.a.location <- c("Total - Former Soviet Union",
                    "USSR & East Europe",
                    "USSR and East Europe")

# Custom code for personnel afloat who are not ashore in any country. See the "Personnel afloat"
# section below for what it holds.
afloat.code <- 10200



# Generate country codes for 1950 to 1953
data.clean.1950.1953 <- data.clean.1950.1953 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "gwn",
                                                              custom_match = custom.gwn,
                                                              warn = TRUE),
                             iso3c = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "iso3c",
                                                              warn = TRUE),
                             ccode = case_when(
                               ccode == 816 ~ 817,
                               TRUE ~ ccode
                             )
                      )
  )

# Check for missing country codes
filtered.1950.1053 <- data.clean.1950.1953 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )


# Generate country codes for 1954 to 1956
data.clean.1954.1956 <- data.clean.1954.1956 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "gwn",
                                                              custom_match = custom.gwn,
                                                              warn = TRUE),
                             iso3c = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "iso3c",
                                                              warn = TRUE),
                             ccode = case_when(
                               ccode == 816 ~ 817,
                               TRUE ~ ccode
                             )
                      )
  )

# Check for missing country codes
filtered.1954.1956 <- data.clean.1954.1956 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )


# Generate country codes for 1957 to 1967
data.clean.1957.1967 <- data.clean.1957.1967 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "gwn",
                                                              custom_match = custom.gwn,
                                                              warn = TRUE),
                             iso3c = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "iso3c",
                                                              warn = TRUE),
                             ccode = case_when(
                               ccode == 816 ~ 817,
                               TRUE ~ ccode
                             )
                      )
  )

# Check for missing country codes
filtered.1957.1967 <- data.clean.1957.1967 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )



# Generate country codes for 1968 to 1976
data.clean.1968.1976 <- data.clean.1968.1976 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "gwn",
                                                              custom_match = custom.gwn,
                                                              warn = TRUE),
                             iso3c = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "iso3c",
                                                              warn = TRUE),
                             ccode = case_when(
                               ccode == 816 ~ 817,
                               TRUE ~ ccode
                             )
                      )
  )

# Check for missing country codes
filtered.1968.1976 <- data.clean.1968.1976 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )


# Generate country codes for 1977 to 2010
# Note that these data overlap with newer DMDC reports, so we'll drop 2009 and 2010 from this sequence and use the newer data for those years.
data.clean.1977.2010 <- data.clean.1977.2010 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "gwn",
                                                              custom_match = custom.gwn,
                                                              warn = TRUE),
                             iso3c = countrycode::countrycode(sourcevar = Location,
                                                              origin = "country.name",
                                                              destination = "iso3c",
                                                              warn = TRUE)
                      )
  )

# Check for missing country codes
filtered.1977.2010 <- data.clean.1977.2010 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )

# Remove last two elements from this list as they overlap with the newer data.
# Drop 2008, 2009, and 2010 from this list. 2008 is double counted in another
# chunk of code leading to inflated values.

data.clean.1977.2010 <- data.clean.1977.2010[c(1:29)]

# Generate country codes for 2008 to 2023
data.clean.September.2008.June.2023 <- data.clean.September.2008.June.2023 %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = case_when(
                        row_number() > 53 ~ countrycode::countrycode(sourcevar = Location,
                                                                     origin = "country.name",
                                                                     destination = "gwn",
                                                                     custom_match = custom.gwn,
                                                                     warn = TRUE),
                        TRUE ~ NA),
                        iso3c = case_when(
                          row_number() > 53 ~ countrycode::countrycode(sourcevar = Location,
                                                                       origin = "country.name",
                                                                       destination = "iso3c",
                                                                       warn = TRUE),
                          TRUE ~ NA),
                        fips = case_when(
                          row_number() <=53 ~ usmap::fips(Location),
                          TRUE ~ NA)
                      )
  )

# Check for missing country codes
filtered.September.2008.June.2023 <- data.clean.September.2008.June.2023 %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )

# Generate country codes for September 2023 to December 2023
data.clean.September.2023.Present <- data.clean.September.2023.Present %>%
  furrr::future_map(.f = ~ .x %>%
                      mutate(ccode = case_when(
                        # Rows past the UNITED STATES block, plus the territory rows inside it.
                        row_number() > 54 | Location %in% us.block.territories ~ countrycode::countrycode(sourcevar = Location,
                                                                     origin = "country.name",
                                                                     destination = "gwn",
                                                                     custom_match = custom.gwn,
                                                                     warn = TRUE),
                        TRUE ~ NA),
                        iso3c = case_when(
                          row_number() > 54 ~ countrycode::countrycode(sourcevar = Location,
                                                                       origin = "country.name",
                                                                       destination = "iso3c",
                                                                       warn = TRUE),
                          TRUE ~ NA),
                        fips = case_when(
                          row_number() <=54 ~ usmap::fips(Location),
                          TRUE ~ NA)
                      )
  )

# Check for missing country codes
filtered.September.2023.Present <- data.clean.September.2023.Present %>%
  furrr::future_map(.f = ~ .x %>%
                      filter(is.na(ccode))
  )


# Basic cleaning and organization of 2003 data
data.clean.2003 <- pdftools::pdf_text(datalist.2003.names) %>%
  stringr::str_split(pattern = "\n") %>%
  unlist() %>%
  stringr::str_trim() %>%
  as.data.frame() %>%
  dplyr::slice(548:908) %>%
  tidyr::separate(col = 1,
                  into = c("Location", "troops_ad", "army_ad", "navy_ad", "marine_corps_ad", "air_force_ad"),
                  sep = " {2,}") %>%
  dplyr::filter(Location != "") %>% # Remove empty rows
  dplyr::mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "gwn",
                                                 custom_match = custom.gwn),
                iso3c = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "iso3c",
                                                 warn = TRUE)
  )



# Basic cleaning and organization of 2004 data
data.clean.2004 <- pdftools::pdf_text(datalist.2004.names) %>%
  stringr::str_split(pattern = "\n") %>%
  unlist() %>%
  stringr::str_trim() %>%
  as.data.frame() %>%
  dplyr::slice(555:927) %>%
  tidyr::separate(col = 1,
                  into = c("Location", "troops_ad", "army_ad", "navy_ad", "marine_corps_ad", "air_force_ad"),
                  sep = " {2,}") %>%
  dplyr::filter(Location != "") %>% # Remove empty rows
  dplyr::mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "gwn",
                                                 custom_match = custom.gwn),
                iso3c = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "iso3c",
                                                 warn = TRUE)
  )


# Combine 2003 and 2004 data into a single list object.

data.clean.2003.2004 <- list("September 2003" = data.clean.2003,
                             "September 2004" = data.clean.2004)



#### Consolidate International Frames ####

# Join all of the lists together into a single list object.
# Filter out the unused quarters for each year.
# Summarize values for the United States so they all include the continental US
# and Alaska and Hawaii together.
data.clean.combined.international <- furrr::future_map(.x = list(data.clean.1950.1953,
                                                                 data.clean.1954.1956,
                                                                 data.clean.1957.1967,
                                                                 data.clean.1968.1976,
                                                                 data.clean.1977.2010,
                                                                 data.clean.2003.2004,
                                                                 data.clean.September.2008.June.2023,
                                                                 data.clean.September.2023.Present),
                                                       .f = ~ data.table::rbindlist(.x, fill = TRUE, idcol = "source")) %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) %>%
  dplyr::mutate(ccode = as.numeric(ccode), # Codes are numeric already now that custom.gwn is; kept as a guard.
                ccode = case_when(
    stringr::str_squish(Location) %in% not.a.location ~ NA_real_,
    grepl(".*Ryukyu.*", Location) ~ 740,
    grepl(".*Hong Kong.*", Location, ignore.case = TRUE) ~ 1009,
    grepl(".*Indo-China.*|.*Viet-Nam.*|.*South Vietnam.*", Location, ignore.case = TRUE) ~ 817,
    TRUE ~ ccode
  )) %>% # Assign Ryukyu Islands to Japan. There's an error where it's cutting out second Japan entry for Ryukyu Islands. Seems to be because there's a footnote containing the word 'Japan' and it's dropping the Ryukyu Islands and keeping that. Also assign Hong Kong its own country code because countrycode is lumping it in with China. Also make sure Indo-China is recoded as Vietnam for 817 south vietnam code.
  # The 2003 and 2004 reports are read from PDFs as text, thousands separators included, and
  # as.numeric("74,796") is NA. Every location with a thousand or more personnel in those two
  # reports therefore lost its row at the filter on troops_ad further down -- Germany, Japan, South
  # Korea, the United Kingdom, Italy, Guam and Puerto Rico among them -- and the country-year frame
  # fell back to the Kane row for that year, which has the same total but no service branches.
  # Strip the separators before converting.
  dplyr::mutate(troops_ad = as.numeric(stringr::str_replace_all(troops_ad, ",", ""))) %>% # Make sure combined and data.gaps formats match.
  #bind_rows(data.gaps) %>%
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, tidyselect::everything()) %>%
  dplyr::arrange(ccode, year, month, quarter) %>%
  dplyr::filter(case_when(
    year <= 1956 ~ month == "June",
    year >= 1957 & year <= 1976 ~ month == "September",
    year >= 1977 & year <= 2012 ~ month == "September",
    TRUE ~ TRUE
  )) %>%
  dplyr::filter(ccode != 2) %>% # Remove US and total US values separately
  dplyr::mutate(across(`Total`:`Space Force Active Duty`,
                       ~ str_replace_all(., pattern = ",", replacement = ""))) %>% # Remove commas from numbers
  dplyr::mutate(across(quarter:`Space Force Active Duty`, ~ case_when(
    . == "N/A" ~ NA,
    TRUE ~ as.numeric(.)  # Convert all values to numeric
  )
  ),
  `Navy Other` = abs(`Navy Other`)) %>%
  # The Army reported nothing for December 2022, March 2023 and June 2023 while it moved to a new
  # personnel system. Those three workbooks show N/A for the Army columns and for every total,
  # and real figures for the Navy, Marine Corps, Air Force and Coast Guard. A row from one of them
  # has no troops_ad, so it is flagged here and let through the filter on troops_ad below; the
  # country-year frame then interpolates the Army columns only and rebuilds the totals.
  dplyr::mutate(army_not_reported =
                  ((year == 2022 & quarter == 4) | (year == 2023 & quarter %in% c(1, 2))) &
                  is.na(`Army Active Duty`) &
                  !(is.na(`Navy Active Duty`) & is.na(`Marine Corps Active Duty`) &
                      is.na(`Air Force Active Duty`) & is.na(`Coast Guard Active Duty`))) %>%
  rowwise() %>%
  # Personnel ashore, for every report that separates ashore from afloat (1950 to 1976).
  #
  # Those reports attribute Navy and Marine Corps personnel afloat to a location in different
  # ways: to the country of the nearest port, inside the row total (1954 to 1958) or in
  # parentheses beside it (1953 and 1959 to 1967), and to selected rows only from 1968. Counting
  # them put a fleet at sea in whichever country it was nearest on the day of the count --
  # Greece read 15,066 for September 1960 against 1,976 ashore, Brazil 12,716 for June 1953
  # against 269. The reports from 1977 to 2007 list personnel afloat in rows of their own and
  # show countries ashore only. So troops_ad, navy_ad and marine_corps_ad are the ashore figures
  # throughout:
  #
  #   1950, 1954-1956, 1968-1976   the report's ashore column
  #   1953, 1957-1967              shore activities plus mobile units temporarily based ashore,
  #                                which those reports print as a separate Navy column
  #
  # In 1954 to 1956 the temporarily shore-based units are inside a single "Afloat & Mobile"
  # column and cannot be separated from it, so they are not counted for those three years.
  #
  # What a report puts afloat at a location is kept beside those, in navy_afloat,
  # marine_corps_afloat and troops_afloat (added after this block), so get_troopdata() can leave
  # it out, add it in or show it separately. Everything afloat is also carried once, worldwide,
  # under afloat.code (see "Personnel afloat").
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),
    year %in% c(1953, 1957:1967) & (!is.na(`Total`) | !is.na(`Total Ashore`)) ~
      sum(`Total Ashore`, `Navy Temporary Ashore`, na.rm = TRUE),
    year <= 1976 & (!is.na(`Total`) | !is.na(`Total Ashore`)) ~ sum(`Total Ashore`, na.rm = TRUE),
    !is.na(`Total`) ~ as.numeric(`Total`),
    #!is.na(troops) ~ as.numeric(troops),
    TRUE ~ as.numeric(`Total Active Duty`)
  ),
  army_ad = case_when(
    !is.na(army_ad) ~ army_ad,
    !is.na(`Army Total`) & is.na(army_ad) ~ as.numeric(`Army Total`),
    army_not_reported ~ NA_real_, # not reported is not zero
    TRUE ~ sum(`Army Active Duty`,
               na.rm = TRUE)),
  navy_ad = case_when(
    !is.na(navy_ad) ~ navy_ad,
    # Ashore, as for troops_ad. `Navy Afloat`, `Navy Other` and, for 1968 to 1976, the afloat part
    # of `Navy Total` are not in a location's figure.
    year <= 1976 ~ sum(`Navy Ashore`, `Navy Temporary Ashore`, na.rm = TRUE),
    !is.na(`Navy Total`) ~ as.numeric(`Navy Total`),
    # `Navy Active Duty` is the 2008-onward column. It was once missing from this branch, so
    # navy_ad came out as 0 for every country outside the United States in every report from
    # September 2008 on: 5,305 country-quarters, Japan and Bahrain included.
    TRUE ~ sum(`Navy Active Duty`, na.rm = TRUE)),
  air_force_ad = case_when(
    !is.na(air_force_ad) ~ air_force_ad,
    !is.na(`Air Force Total`) & is.na(air_force_ad) ~ as.numeric(`Air Force Total`),
    TRUE ~ sum(`Air Force Active Duty`,
               na.rm = TRUE)),
  marine_corps_ad = case_when(
    !is.na(marine_corps_ad) ~ marine_corps_ad,
    year <= 1976 ~ sum(`Marine Corps Ashore`, na.rm = TRUE), # ashore, as above
    !is.na(`Marine Corps Total`) ~ as.numeric(`Marine Corps Total`),
    TRUE ~ sum(`Marine Corps Active Duty`, na.rm = TRUE)),
  coast_guard_ad = sum(`Coast Guard Active Duty`,
                       na.rm = TRUE),
  space_force_ad = sum(`Space Force Active Duty`,
                       na.rm = TRUE)
  ) %>%
  dplyr::mutate(countryname = countrycode::countrycode(ccode, "gwn", "country.name"),
                countryname = case_when(
                  is.na(countryname) ~ Location,
                  TRUE ~ countryname
                ),
                countryname = str_to_title(countryname),
                countryname = case_when(
                  grepl(".*Antar.*", countryname) ~ "Antarctica",
                  TRUE ~ countryname
                )
  ) %>%
  dplyr::arrange(ccode, countryname, year, month, quarter) %>%
  dplyr::select(ccode, countryname, year, month, quarter, tidyselect::everything()) %>%
  # One row per reported location per period. This used to group by (ccode, countryname) and keep
  # the largest row, and countryname is derived from the code, so wherever a report lists two
  # places under one country code only the bigger one survived. The reports list Japan and the
  # Ryukyu Islands separately through 1973, both coded 740: every year kept one and discarded the
  # other, so Japan's September figure was roughly half the true one for 1957-1973 (41,948 for
  # 1968, where the report shows 41,121 + 41,948 = 83,069) and the reports frame never held both
  # rows. The same rule dropped Trieste, Scotland, Jerusalem, the Volcano and Bonin Islands, the
  # Mediterranean half of France in 1955-56 and the Republic of Panama beside the Canal Zone: 174
  # rows in all. Grouping by Location keeps every distinct place and still removes a location the
  # report repeats (ZIMBABWE is listed twice in September 2013 and was being counted twice).
  #
  # A row with no troops_ad is dropped here, which is what removes footnotes and headings that
  # happen to match a country name. The exception is a row from one of the three quarters with no
  # Army figure: its total is N/A in the workbook, and it is kept with troops_ad left missing.
  group_by(ccode, Location, year, month, quarter) %>%
  dplyr::filter(troops_ad == max(troops_ad, na.rm = TRUE) | (is.na(troops_ad) & army_not_reported)) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::select(-army_not_reported) %>%
  # Personnel afloat that the report attributes to this location. These are kept out of
  # troops_ad, navy_ad and marine_corps_ad, which stay ashore figures.
  #
  #   1953, 1959-1967   the figure in parentheses under Navy "Other" and Marine Corps "Afloat &
  #                     Mobile": personnel afloat, "distributed by country of nearest port". It
  #                     is read as a negative number, hence abs().
  #   1957, 1958        the same two columns, printed without parentheses.
  #   1954-1956         the single Navy "Afloat & Mobile" column, which also holds the mobile
  #                     units temporarily based ashore, and the Marine Corps one.
  #   1968-1976         the Afloat columns. Most of these reports give afloat figures for regions
  #                     only; 1974 and 1975 give them for countries.
  #   1950              nothing for the Navy outside the United States; one Marine Corps figure.
  #
  # From 1953 to 1976 a location with no figure is zero: the report lists personnel afloat by
  # location and has none there. In 1950, and from 1977 on, a location with no figure is
  # missing: the reports give personnel afloat by region (1977 to 2007) or count a crew at its
  # home port, inside the country's own figure (2008 on).
  dplyr::mutate(
    navy_afloat = dplyr::case_when(
      year %in% c(1953, 1957:1967) ~ abs(as.numeric(`Navy Other`)),
      year %in% c(1954:1956, 1968:1976) ~ as.numeric(`Navy Afloat`),
      TRUE ~ NA_real_),
    marine_corps_afloat = dplyr::case_when(
      year <= 1976 ~ abs(as.numeric(`Marine Corps Afloat`)),
      TRUE ~ NA_real_),
    dplyr::across(c(navy_afloat, marine_corps_afloat),
                  ~ dplyr::if_else(year %in% 1953:1976, dplyr::coalesce(.x, 0), .x)),
    troops_afloat = dplyr::if_else(is.na(navy_afloat) & is.na(marine_corps_afloat),
                                   NA_real_,
                                   dplyr::coalesce(navy_afloat, 0) + dplyr::coalesce(marine_corps_afloat, 0)),
    # One total for a location in 1950 that has a figure for one service only.
    dplyr::across(c(navy_afloat, marine_corps_afloat),
                  ~ dplyr::if_else(!is.na(troops_afloat), dplyr::coalesce(.x, 0), .x))) %>%
  dplyr::group_by(ccode, countryname, year, month, quarter)



#### Personnel afloat ####

# Navy and Marine Corps personnel afloat, worldwide, as one figure per report under afloat.code
# (10200). No country, state or territory in this build includes personnel afloat in troops_ad
# before 2008, so this row is where they are: the fleet in home waters as well as the fleets
# abroad.
#
# The row holds everyone afloat, including the personnel a report attributes to a location, who
# are also in that location's navy_afloat and marine_corps_afloat. get_troopdata() takes them
# back out of this row when it adds them to the locations or shows them separately
# (afloat = "include" or "separate"), so nobody is counted twice.
#
# It is the report's own worldwide afloat figure, not a sum built up from rows:
#
#   1950                   "Afloat & Mobile" on the WORLDWIDE line. The 1950 report does not
#                          distribute it by location at all.
#   1953, 1957-1967        "Afloat & Mobile" on the WORLDWIDE line, less the mobile units
#                          temporarily based ashore, which are counted in the locations.
#   1954-1956              "Afloat & Mobile" on the WORLDWIDE line. These three reports do not
#                          separate the temporarily shore-based units, so they are in here.
#   1968-1976              the Afloat column of the TOTAL PERSONNEL line.
#   1977-2002, 2005-2007   the Afloat line printed under "Total - Worldwide".
#   2003, 2004             the same line, entered by hand below: the PDF tables are read by line
#                          number and the slice stops before it. The 2004 line prints 135,536,
#                          which is the Navy alone; the report's own afloat lines for the United
#                          States (115,494, of them 164 Marine Corps) and for foreign countries
#                          (20,206) add to 135,700, and that is the figure used.
#
# There is nothing after 2007. From September 2008 the DMDC counts a ship's crew at its home
# port, inside the state or country figure, and prints no afloat line.
afloat_numeric <- function(x) {
  suppressWarnings(as.numeric(stringr::str_replace_all(as.character(x), ",", "")))
}

data.afloat.1950.1976 <- c(data.clean.1950.1953,
                           data.clean.1954.1956,
                           data.clean.1957.1967,
                           data.clean.1968.1976) %>%
  purrr::map(.f = ~ .x %>%
               dplyr::filter(stringr::str_squish(as.character(Location)) %in%
                               c("WORLDWIDE", "TOTAL PERSONNEL")) %>%
               dplyr::mutate(dplyr::across(-Location, afloat_numeric))) %>%
  dplyr::bind_rows(.id = "source") %>%
  dplyr::mutate(year = as.numeric(stringr::str_extract(source, "[0-9]{4}")),
                navy_ad = dplyr::case_when(
                  year == 1950 ~ `Navy Temporary Ashore`, # one afloat-and-mobile figure, printed in this column
                  year %in% c(1953, 1957:1967) ~ abs(`Navy Other`),
                  TRUE ~ `Navy Afloat`),
                marine_corps_ad = `Marine Corps Afloat`,
                troops_ad = dplyr::case_when(
                  year %in% c(1953, 1957:1967) ~ `Total Afloat` - dplyr::coalesce(`Navy Temporary Ashore`, 0),
                  TRUE ~ `Total Afloat`)) %>%
  dplyr::select(source, troops_ad, navy_ad, marine_corps_ad,
                `Total Afloat`, `Navy Temporary Ashore`, `Navy Other`, `Navy Afloat`, `Marine Corps Afloat`)

data.afloat.1977.2007 <- data.clean.1977.2010 %>%
  purrr::map(.f = function(df) {
    location <- stringr::str_squish(as.character(df$Location))
    worldwide <- which(grepl("^Total - Worldwide", location))
    hit <- integer(0)
    if (length(worldwide) == 1) {
      position <- seq_along(location)
      hit <- which(location == "Afloat" & position > worldwide & position <= worldwide + 2)
    }
    df[hit, ] %>%
      dplyr::mutate(dplyr::across(-Location, afloat_numeric))
  }) %>%
  dplyr::bind_rows(.id = "source") %>%
  dplyr::transmute(source,
                   troops_ad = `Total`,
                   navy_ad = `Navy Total`,
                   marine_corps_ad = `Marine Corps Total`)

# "Total - Worldwide ... Afloat" in the active duty table of m05sep03.pdf and m05sep04.pdf.
data.afloat.2003.2004 <- tibble::tribble(
  ~source,          ~troops_ad, ~navy_ad, ~marine_corps_ad,
  "September 2003",     147734,   140912,             6822,
  "September 2004",     135700,   135536,              164
)

data.afloat.global <- dplyr::bind_rows(data.afloat.1950.1976,
                                       data.afloat.1977.2007,
                                       data.afloat.2003.2004) %>%
  dplyr::mutate(year = as.numeric(stringr::str_extract(source, "[0-9]{4}")),
                month = stringr::str_extract(source, "[A-Za-z]+"),
                quarter = dplyr::case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                ),
                ccode = afloat.code,
                countryname = "Afloat",
                Location = "Afloat",
                iso3c = NA_character_,
                dplyr::across(c(troops_ad, navy_ad, marine_corps_ad), ~ dplyr::coalesce(.x, 0)),
                army_ad = 0,
                air_force_ad = 0,
                coast_guard_ad = 0,
                space_force_ad = 0) %>%
  dplyr::arrange(year) %>%
  dplyr::select(ccode, countryname, year, month, quarter, source, Location, iso3c,
                troops_ad, army_ad, navy_ad, marine_corps_ad, air_force_ad, coast_guard_ad,
                space_force_ad, tidyselect::everything())

# One row for every report from 1950 to 2007, and nothing else. Fewer means a report whose
# worldwide line was not found, and its personnel afloat would be missing from the data.
local({
  expected <- length(data.clean.1950.1953) + length(data.clean.1954.1956) +
    length(data.clean.1957.1967) + length(data.clean.1968.1976) +
    length(data.clean.1977.2010) + nrow(data.afloat.2003.2004)
  if (nrow(data.afloat.global) != expected || any(duplicated(data.afloat.global$source)) ||
      any(data.afloat.global$troops_ad <= 0)) {
    warning("Personnel afloat: expected one positive worldwide figure for each of ", expected,
            " reports, found ", nrow(data.afloat.global), " row(s), ",
            sum(data.afloat.global$troops_ad <= 0), " of them not positive.", call. = FALSE)
  }
})


# Personnel afloat that the reports attribute to the United States, one row per report from 1950
# to 2007. The United States frame below is built through a chain that keeps one row per report
# and cannot carry these columns, so they are worked out here and joined on by report.
#
#   1950              "Afloat & Mobile" on the "Other 48 States & D.C." line, the only place the
#                     1950 report puts any of the Navy's afloat and mobile personnel.
#   1953, 1959-1967   Navy "Other" and Marine Corps "Afloat & Mobile" on the UNITED STATES line.
#                     The figures in parentheses on the Alaska, Hawaii and 48-states lines below
#                     it distribute the same personnel and are not added again.
#   1954-1958         the same columns (one Navy "Afloat & Mobile" column in 1954 to 1956) on the
#                     continental United States, Alaska and Hawaii lines, added together.
#   1968-1976         the Afloat columns of the "United States, U.S. Territories & Special
#                     Locations" line, less what the report places at a territory with a country
#                     code of its own (Guam, Puerto Rico, Guantanamo, the Canal Zone and Midway in
#                     1974 and 1975), which is in that territory's figure.
#   1977-2007         the Afloat line inside the "United States and Territories" block.
#   2003, 2004        the same line, entered by hand for the reason given above.
#
# From 1968 the reports give this figure for the United States and its territories together and
# do not divide it further. It is the fleet in home waters, and it is assigned to the United
# States: from September 2008 the DMDC counts the same crews in their home-port state.
us_afloat_rows <- function(df) {
  location <- stringr::str_squish(as.character(df$Location))
  total.given <- grepl("^UNITED STATES$", location)
  parts <- grepl("^continental united states|^alaska|^hawaii", location, ignore.case = TRUE)
  df[if (any(total.given)) total.given else parts, ]
}

data.afloat.us.1950 <- data.clean.1950.1953["June 1950"] %>%
  purrr::map(.f = ~ .x %>%
               dplyr::filter(grepl("^Other 48 States", stringr::str_squish(as.character(Location)))) %>%
               dplyr::mutate(dplyr::across(-Location, afloat_numeric))) %>%
  dplyr::bind_rows(.id = "source") %>%
  dplyr::group_by(source) %>%
  dplyr::summarise(navy_afloat = sum(`Navy Temporary Ashore`, na.rm = TRUE),
                   marine_corps_afloat = sum(abs(`Marine Corps Afloat`), na.rm = TRUE),
                   .groups = "drop")

data.afloat.us.1953.1967 <- c(data.clean.1950.1953["June 1953"],
                              data.clean.1954.1956,
                              data.clean.1957.1967) %>%
  purrr::map(.f = ~ us_afloat_rows(.x) %>%
               dplyr::mutate(dplyr::across(-Location, afloat_numeric))) %>%
  dplyr::bind_rows(.id = "source") %>%
  dplyr::mutate(year = as.numeric(stringr::str_extract(source, "[0-9]{4}")),
                navy_afloat = dplyr::if_else(year %in% 1954:1956, `Navy Afloat`, abs(`Navy Other`))) %>%
  dplyr::group_by(source) %>%
  dplyr::summarise(navy_afloat = sum(navy_afloat, na.rm = TRUE),
                   marine_corps_afloat = sum(abs(`Marine Corps Afloat`), na.rm = TRUE),
                   .groups = "drop")

data.afloat.us.1968.1976 <- data.clean.1968.1976 %>%
  purrr::map(.f = function(df) {
    location <- stringr::str_squish(as.character(df$Location))
    code <- suppressWarnings(as.numeric(df$ccode))
    position <- seq_along(location)
    block <- which(grepl("TERRITORIES", location) & grepl("SPECIAL LOCATIONS", location))
    foreign <- which(grepl("^Total Foreign", location))
    if (length(block) != 1 || length(foreign) != 1 || foreign < block) {
      return(tibble::tibble(navy_afloat = NA_real_, marine_corps_afloat = NA_real_))
    }
    elsewhere <- position > block & position < foreign & !is.na(code) & code != 2
    net <- function(column) {
      value <- afloat_numeric(df[[column]])
      dplyr::coalesce(value[block], 0) - sum(value[elsewhere], na.rm = TRUE)
    }
    tibble::tibble(navy_afloat = net("Navy Afloat"),
                   marine_corps_afloat = net("Marine Corps Afloat"))
  }) %>%
  dplyr::bind_rows(.id = "source")

data.afloat.us.1977.2007 <- data.clean.1977.2010 %>%
  purrr::map(.f = function(df) {
    location <- stringr::str_squish(as.character(df$Location))
    block.total <- which(grepl("^Total - U", location))[1]   # "... U. S. Territories" / "... United States"
    hit <- which(location == "Afloat" & seq_along(location) < block.total)
    if (is.na(block.total) || length(hit) != 1) {
      return(tibble::tibble(navy_afloat = NA_real_, marine_corps_afloat = NA_real_))
    }
    tibble::tibble(navy_afloat = afloat_numeric(df[["Navy Total"]][hit]),
                   marine_corps_afloat = afloat_numeric(df[["Marine Corps Total"]][hit]))
  }) %>%
  dplyr::bind_rows(.id = "source")

# "United States and Territories ... Afloat" in the active duty table of the two PDFs.
data.afloat.us.2003.2004 <- tibble::tribble(
  ~source,          ~navy_afloat, ~marine_corps_afloat,
  "September 2003",       121274,                  266,
  "September 2004",       115330,                  164
)

data.afloat.us <- dplyr::bind_rows(data.afloat.us.1950,
                                   data.afloat.us.1953.1967,
                                   data.afloat.us.1968.1976,
                                   data.afloat.us.1977.2007,
                                   data.afloat.us.2003.2004) %>%
  dplyr::mutate(dplyr::across(c(navy_afloat, marine_corps_afloat), as.numeric),
                troops_afloat = navy_afloat + marine_corps_afloat) %>%
  dplyr::select(source, troops_afloat, navy_afloat, marine_corps_afloat)

# One row for every report that has a worldwide afloat figure, each with a figure of its own.
local({
  missing <- setdiff(data.afloat.global$source, data.afloat.us$source[!is.na(data.afloat.us$troops_afloat)])
  if (length(missing) > 0 || any(duplicated(data.afloat.us$source)) ||
      any(data.afloat.us$troops_afloat < 0, na.rm = TRUE)) {
    warning("Personnel afloat, United States: no usable figure for ",
            paste(missing, collapse = ", "), "; ",
            sum(duplicated(data.afloat.us$source)), " duplicated report(s), ",
            sum(data.afloat.us$troops_afloat < 0, na.rm = TRUE), " negative.", call. = FALSE)
  }
})



#### Consolidate US Frames ####

# Adds up one column over the rows that make up the United States in a report. All missing stays
# missing rather than becoming zero, so a column a report does not have is not turned into a value.
us_block_sum <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
}


# Repeat the basic procedure from the previous code chunk but extract the US
# data and clean those. These are more complicated because of the different ways that states
# are parsed out at different times.
# This first batch can only cover up until 2007. After that DOD reports start breaking out state-specific values and
# include them along with deployments to individual countries.
data.clean.combined.us.1953.2007 <- furrr::future_map(.x = list(data.clean.1950.1953,
                                                                data.clean.1954.1956,
                                                                data.clean.1957.1967,
                                                                data.clean.1968.1976,
                                                                data.clean.2003.2004,
                                                                data.clean.1977.2010),
                                                      .f = ~ data.table::rbindlist(.x,
                                                                                   fill = TRUE,
                                                                                   idcol = "source")) %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) %>%
  #bind_rows(data.gaps) %>%
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, tidyselect::everything()) %>%
  dplyr::arrange(ccode, year, month, quarter) %>%
  dplyr::filter(case_when( # Filter out the quarters that are not used in the data
    year <= 1956 ~ month == "June",
    year >= 1957 & year <= 1976 ~ month == "September",
    year >= 1977 & year <= 2012 ~ month == "September",
    TRUE ~ TRUE
  )) %>%
  dplyr::filter(ccode == 2) %>% # Only keep US data
  #dplyr::filter(!is.na(`Total`)) %>% # Remove rows with no data for the Total column
  dplyr::filter(year < 2008) %>% # Remove 2008 since that will be aggregated separately.
  dplyr::group_by(year, month, quarter) %>% # Group by year, month, and quarter
  # The patterns are anchored at the start of the name. Unanchored, "ontinental" also matched
  # "OUTSIDE CONTINENTAL UNITED STATES" and several footnotes that mention the continental total.
  dplyr::mutate(grouping = case_when( # Create grouping variable to identify reports where total is given vs broken out by continental US, Alaska, and Hawaii
    grepl("^UNITED STATES$", Location) ~ "Total Given",
    #!is.na(statenme) ~ "Total Given",
    grepl("^continental united states", stringr::str_squish(Location), ignore.case = TRUE) ~ "Disaggregated",
    grepl("^alaska", stringr::str_squish(Location), ignore.case = TRUE) ~ "Disaggregated",
    grepl("^hawaii", stringr::str_squish(Location), ignore.case = TRUE) ~ "Disaggregated",
  )) %>%
  dplyr::filter(!grepl(".*territor.*", Location, ignore.case = TRUE)) %>%
  dplyr::mutate(grouping_num = factor(grouping,
                                      levels = c("Disaggregated", "Total Given"))) %>% # Create a factor for ordering
  dplyr::mutate(across(`Total`:`air_force_ad`,
                       ~ str_replace_all(., ",", ""))) %>%
  # One row per report: the UNITED STATES line where the report prints one (1950, 1953, 1959 to
  # 1967), otherwise the continental United States, Alaska and Hawaii added together.
  #
  # This step used to be slice(which.max(grouping_num)), which keeps a single row. In a report
  # with no UNITED STATES line that row was the continental United States alone, so Alaska and
  # Hawaii were left out of the United States figure for 1954 to 1958 and 1968 to 2007 -- between
  # 48,000 and 87,000 personnel a year -- and, being coded 2, were dropped from the country data
  # too. The summarise() below already says "Disaggregated ~ sum"; it only ever saw one row.
  dplyr::filter(!is.na(grouping_num)) %>%
  dplyr::filter(as.integer(grouping_num) == max(as.integer(grouping_num))) %>%
  dplyr::group_by(source, year, month, quarter, grouping, grouping_num) %>%
  dplyr::summarise(dplyr::across(`Total`:`air_force_ad`, us_block_sum),
                   Location = dplyr::first(Location),
                   ccode = dplyr::first(ccode),
                   iso3c = dplyr::first(iso3c),
                   .groups = "drop") %>%
  dplyr::group_by(year, month, quarter) %>%
  select(source, Location, grouping, grouping_num, tidyselect::everything()) %>%
  dplyr::group_by(source, year, month, quarter) %>%
  dplyr::summarise(across(tidyselect::everything(), ~ case_when(
    grouping == "Total Given" ~ max(as.numeric(.), na.rm = TRUE),
    grouping == "Disaggregated" ~ sum(as.numeric(.), na.rm = TRUE)))) %>%
  dplyr::summarize(across(tidyselect::everything(), ~ max(., na.rm = TRUE))) %>%
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) %>%
  dplyr::mutate(across(tidyselect::everything(), ~ case_when(
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>%
  dplyr::mutate(across(`Total`: `air_force_ad`, ~ case_when(
    . == 0 ~ NA,
    TRUE ~ .
  ))) %>%
  rowwise() %>%
  # Personnel ashore, on the same rule as every other location (see the international block):
  # troops_ad, navy_ad and marine_corps_ad for the United States before 2008 hold nobody afloat.
  # The reports put the fleet in home waters inside the United States total in some years (1953
  # to 1967, 1974 and 1975), outside it in others (1977 to 2007), and on the line for the United
  # States and its territories together in the rest. It is in navy_afloat, marine_corps_afloat
  # and troops_afloat for every report (data.afloat.us, joined on below). From 2008 the DMDC
  # counts a crew in its home-port state, so the ashore series steps up by roughly the home
  # fleet: 936,447 for September 2007, 1,055,155 for September 2008, and 1,029,037 for
  # September 2007 with the 92,590 afloat added.
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),       # 2003 and 2004, read from the PDFs
    year %in% c(1953, 1957:1967) ~ sum(`Total Ashore`, `Navy Temporary Ashore`, na.rm = TRUE),
    year <= 1976 ~ `Total Ashore`,
    TRUE ~ `Total`                                   # 1977 to 2007: these rows are ashore
  ),
  army_ad = case_when(
    !is.na(army_ad) ~ army_ad,
    TRUE ~ `Army Total`
  ),
  navy_ad = case_when(
    !is.na(navy_ad) ~ navy_ad,
    year <= 1976 ~ sum(`Navy Ashore`, `Navy Temporary Ashore`, na.rm = TRUE),
    TRUE ~ `Navy Total`
  ),
  air_force_ad = case_when(
    !is.na(air_force_ad) ~ air_force_ad,
    TRUE ~ `Air Force Total`
  ),
  marine_corps_ad = case_when(
    !is.na(marine_corps_ad) ~ marine_corps_ad,
    year <= 1976 ~ `Marine Corps Ashore`,
    TRUE ~ `Marine Corps Total`)
  )



# Repeat the basic procedure from the previous code chunk but extract the US states
# and generate aggregate US totals using these data.
# This first pass covers the pre-Space Force deployment figures.
# Keep this suffix as 2023 and NOT present because the Space Force data is not included in this pass.
data.clean.combined.us.2008.2023 <- data.table::rbindlist(data.clean.2008.Present[c(1:45)],
                                                          idcol = "source",
                                                          fill = TRUE) %>%
  dplyr::select(1:24) %>% # Only keep the columns that are relevant to the US data
  setNames(c("source", names.2008.2023)) %>%
  keep_us_block() %>% # Fifty states and DC only, located by position in the sheet; see keep_us_block()
  dplyr::mutate(fips = usmap::fips(Location)) %>% # Generate FIPS codes for US states
  dplyr::filter(!is.na(fips)) %>%
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) %>%
  dplyr::mutate(across(tidyselect::everything(), ~ str_replace(., ",", ""))) %>% # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) %>% # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) %>% # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) %>%
  rowwise() %>%
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) %>%
  group_by(year, month, quarter, source) %>%
  dplyr::select(-c(`Location`, `Macro Location`, fips)) %>%
  dplyr::summarise(across(tidyselect::everything(), ~ sum(., na.rm = TRUE))) %>%
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) %>%
  # This line is intended to fill in missing values for the army because they didn't report numbers while transitioning to a new personnel system. Instead we'll use the most recent available values from September 2022.
  dplyr::mutate(`Army Active Duty` = case_when(
    `Army Active Duty` == 0 & year == 2022 & month == "December" ~ 404114,
    `Army Active Duty` == 0 & year == 2023 & month == "March" ~ 404114,
    `Army Active Duty` == 0 & year == 2023 & month == "June" ~ 404114,
    TRUE ~ `Army Active Duty`
  )) %>%
  # Now we need to update total active duty numbers to reflect the new values for the Army.
  dplyr::mutate(`Total Active Duty` = case_when(
    year == 2022 & month == "December" ~ sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE),
    year == 2023 & month == "March" ~ sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE),
    year == 2023 & month == "June" ~ sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE),
    TRUE ~ `Total Active Duty`
  )) %>%
  rowwise() %>%
  dplyr::mutate(troops_ad = case_when(
    !is.na(`Total Active Duty`) ~ as.numeric(`Total Active Duty`),
    TRUE ~ sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)
  ),
  army_ad = `Army Active Duty`,
  navy_ad = `Navy Active Duty`,
  air_force_ad = `Air Force Active Duty`,
  marine_corps_ad = `Marine Corps Active Duty`,
  coast_guard_ad = `Coast Guard Active Duty`)





# This second pass covers newer reports from 2023 through 2024 and includes Space Force
# deployment numbers
data.clean.combined.us.2023.Present <- data.table::rbindlist(data.clean.2008.Present[c(46:length(data.clean.2008.Present))], # Select only recent data frames with space force
                                                             idcol = "source",
                                                             fill = TRUE) %>%
  dplyr::select(1:25) %>% # Only keep the columns that are relevant to the US data
  setNames(c("source", names.2023.Present)) %>%
  keep_us_block() %>% # Fifty states and DC only, located by position in the sheet; see keep_us_block()
  dplyr::mutate(fips = usmap::fips(Location)) %>% # Generate FIPS codes for US states
  dplyr::filter(!is.na(fips)) %>%
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) %>%
  dplyr::mutate(across(tidyselect::everything(), ~ str_replace(., ",", ""))) %>% # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) %>% # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) %>% # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) %>%
  rowwise() %>%
  # Space Force is a separate column from September 2023 and has to be in the total: this line was
  # copied from the pre-Space Force pass above without it, so the US troops_ad in the reports frame
  # ran about 8,500-9,600 below the workbook's own total in every quarter from September 2023.
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Space Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) %>%
  group_by(year, month, quarter, source) %>%
  dplyr::select(-c(`Location`, `Macro Location`, fips)) %>%
  dplyr::summarise(across(tidyselect::everything(), ~ sum(., na.rm = TRUE))) %>%
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) %>%
  rowwise() %>%
  dplyr::mutate(troops_ad = case_when(
    !is.na(`Total Active Duty`) ~ as.numeric(`Total Active Duty`),
    TRUE ~ `Army Active Duty` + `Navy Active Duty` + `Marine Corps Active Duty` + `Air Force Active Duty` + `Coast Guard Active Duty`
  ),
  army_ad = `Army Active Duty`,
  navy_ad = `Navy Active Duty`,
  air_force_ad = `Air Force Active Duty`,
  marine_corps_ad = `Marine Corps Active Duty`,
  coast_guard_ad = `Coast Guard Active Duty`,
  space_force_ad = `Space Force Active Duty`)


data.us.combined.all <- bind_rows(data.clean.combined.us.1953.2007,
                                  data.clean.combined.us.2008.2023,
                                  data.clean.combined.us.2023.Present) %>%
  dplyr::mutate(countryname = "United States",
                ccode = 2,
                iso3c = "USA",
                Location = "United States") %>%
  # Personnel afloat attributed to the United States, 1950 to 2007. No figure from 2008.
  dplyr::ungroup() %>%
  dplyr::left_join(data.afloat.us, by = "source") %>%
  dplyr::select(ccode, countryname, year, month, quarter, tidyselect::everything())





#### US States Data ####

# Do first batch.
# Space force screws up later observations from September 2021 forward
data.us.states.2008.September.2021 <- purrr::map(
  .x = data.clean.2008.Present[1:38],
  .f = ~ .x %>%
    slice_us_block() %>% # header row + the whole US block, wherever it sits; see slice_us_block()
    janitor::row_to_names(1) %>%
    janitor::clean_names() %>%
    dplyr::rename("state" = "na_2",
                  "army_ad" = "army",
                  "navy_ad" = "navy",
                  "air_force_ad" = "air_force",
                  "marine_corps_ad" = "marine_corps",
                  "coast_guard_ad" = "coast_guard",
                  "troops_ad" = "total",
                  "army_civilian" = "army_2",
                  "navy_civilian" = "navy_2",
                  "marine_corps_civilian" = "marine_corps_2",
                  "air_force_civilian" = "air_force_2",
                  "dod_civilian" = "x4th_estate_dod",
                  "total_selected_reserve" = "total_2",
                  "total_civilian" = "total_3")
) %>%
  dplyr::bind_rows(.id = "year") %>%
  dplyr::mutate(state = stringr::str_to_lower(state)) %>%
  dplyr::mutate(fipscode = usmap::fips(state = state)) %>%
  dplyr::filter(!is.na(fipscode)) %>%
  dplyr::select(-c("na", "na_3"))


# Do second batch from December 2021 Forward

data.us.states.December.2021.March.2022 <- purrr::map(
  .x = data.clean.2008.Present[39:40],
  .f = ~ .x %>%
    slice_us_block() %>% # header row + the whole US block, wherever it sits; see slice_us_block()
    janitor::row_to_names(1) %>%
    janitor::clean_names() %>%
    dplyr::rename("state" = "na_2",
                  "army_ad" = "army",
                  "navy_ad" = "navy",
                  "air_force_ad" = "air_force_space_force",
                  "marine_corps_ad" = "marine_corps",
                  "coast_guard_ad" = "coast_guard",
                  "troops_ad" = "total",
                  "army_civilian" = "army_2",
                  "navy_civilian" = "navy_2",
                  "marine_corps_civilian" = "marine_corps_2",
                  "air_force_civilian" = "air_force",
                  "dod_civilian" = "x4th_estate_dod",
                  "total_selected_reserve" = "total_2",
                  "total_civilian" = "total_3")
) %>%
  dplyr::bind_rows(.id = "year") %>%
  dplyr::mutate(state = stringr::str_to_lower(state)) %>%
  dplyr::mutate(fipscode = usmap::fips(state = state)) %>%
  dplyr::filter(!is.na(fipscode)) %>%
  dplyr::select(-c("na", "na_3"))


# Do batch 3 from June 2022 to June 2023
data.us.states.June.2022.June.2023 <- purrr::map(
  .x = data.clean.2008.Present[41:45],
  .f = ~ .x %>%
    slice_us_block() %>% # header row + the whole US block, wherever it sits; see slice_us_block()
    janitor::row_to_names(1) %>%
    janitor::clean_names() %>%
    dplyr::rename("state" = "na_2",
                  "army_ad" = "army",
                  "navy_ad" = "navy",
                  "air_force_ad" = "air_force_space_force",
                  "marine_corps_ad" = "marine_corps",
                  "coast_guard_ad" = "coast_guard",
                  "troops_ad" = "total",
                  "army_civilian" = "army_2",
                  "navy_civilian" = "navy_2",
                  "marine_corps_civilian" = "marine_corps_2",
                  "air_force_civilian" = "air_force",
                  "dod_civilian" = "x4th_estate_dod",
                  "total_selected_reserve" = "total_2",
                  "total_civilian" = "total_3")
) %>%
  dplyr::bind_rows(.id = "year") %>%
  dplyr::mutate(state = stringr::str_to_lower(state)) %>%
  dplyr::mutate(fipscode = usmap::fips(state = state)) %>%
  dplyr::filter(!is.na(fipscode)) %>%
  dplyr::select(-c("na", "na_3"))


# Do batch 3 from September 2023 June 2024
data.us.states.September.2023.June.2024 <- purrr::map(
  .x = data.clean.2008.Present[46:49],
  .f = ~ .x %>%
    slice_us_block() %>% # header row + the whole US block, wherever it sits; see slice_us_block()
    janitor::row_to_names(1) %>%
    janitor::clean_names() %>%
    dplyr::rename("state" = "na_2",
                  "army_ad" = "army",
                  "navy_ad" = "navy",
                  "air_force_ad" = "air_force",
                  "space_force_ad" = "space_force",
                  "marine_corps_ad" = "marine_corps",
                  "coast_guard_ad" = "coast_guard",
                  "troops_ad" = "total",
                  "army_civilian" = "army_2",
                  "navy_civilian" = "navy_2",
                  "air_force_civilian" = "air_force_2",
                  "marine_corps_civilian" = "marine_corps_2",
                  "dod_civilian" = "x4th_estate_dod",
                  "total_selected_reserve" = "total_2",
                  "total_civilian" = "total_3")
) %>%
  dplyr::bind_rows(.id = "year") %>%
  dplyr::mutate(state = stringr::str_to_lower(state)) %>%
  dplyr::mutate(fipscode = usmap::fips(state = state)) %>%
  dplyr::filter(!is.na(fipscode)) %>%
  dplyr::select(-c("na", "na_3"))


# Do batch 4 From September 2024 to ...
data.us.states.Setember.2024.Present <- purrr::map(
  .x = data.clean.2008.Present[50:length(data.clean.2008.Present)],
  .f = ~ .x %>%
    slice_us_block() %>% # header row + the whole US block, wherever it sits; see slice_us_block()
    janitor::row_to_names(1) %>%
    janitor::clean_names() %>%
    dplyr::rename("state" = "na_2",
                  "army_ad" = "army",
                  "navy_ad" = "navy",
                  "air_force_ad" = "air_force",
                  "space_force_ad" = "space_force",
                  "marine_corps_ad" = "marine_corps",
                  "coast_guard_ad" = "coast_guard",
                  "troops_ad" = "total",
                  "army_civilian" = "army_2",
                  "navy_civilian" = "navy_2",
                  "marine_corps_civilian" = "marine_corps_2",
                  "air_force_civilian" = "air_force_2",
                  "dod_civilian" = "x4th_estate_dod",
                  "total_selected_reserve" = "total_2",
                  "total_civilian" = "total_3")
) %>%
  dplyr::bind_rows(.id = "year") %>%
  dplyr::mutate(state = stringr::str_to_lower(state)) %>%
  dplyr::mutate(fipscode = usmap::fips(state = state)) %>%
  dplyr::filter(!is.na(fipscode)) %>%
  dplyr::select(-c("na", "na_3"))


# Combine data for US States
troopdata_rebuild_us_states <- dplyr::bind_rows(data.us.states.2008.September.2021,
                                                data.us.states.December.2021.March.2022,
                                                data.us.states.June.2022.June.2023,
                                                data.us.states.September.2023.June.2024,
                                                data.us.states.Setember.2024.Present) %>%
  # Fifty states and DC only. usmap::fips() also recognises Puerto Rico, which DMDC lists inside the
  # UNITED STATES block from March 2025. It is an overseas location and is carried in the country
  # data under its own code, not here.
  dplyr::filter(state %in% stringr::str_to_lower(c(datasets::state.name, "District of Columbia"))) %>%
  dplyr::mutate(month = stringr::str_extract(year,
                                             "[a-zA-Z]*"),
                year = stringr::str_extract(year,
                                            "\\d.*"),
                quarter = dplyr::case_when(
                  month == "September" ~ 3,
                  month == "December" ~ 4,
                  month == "March" ~ 1,
                  month == "June" ~ 2
                ),
                state = stringr::str_to_title(state),
                across(!state & !month,
                         ~ as.numeric(.x))) %>%
  dplyr::select(year, month, quarter, state, fipscode, tidyselect::everything()) %>%
  # Active duty plus the guard and reserve components, the same definition as troops_all in the
  # country data. get_troopdata(state_data = TRUE, guard_reserve = TRUE) selects this column, and
  # failed for as long as the state data did not carry it. It is NA in the three quarters where
  # the Army did not report (December 2022 to June 2023), as troops_ad is here.
  dplyr::mutate(troops_all = troops_ad + army_national_guard + air_national_guard + army_reserve +
                  navy_reserve + marine_corps_reserve + air_force_reserve + coast_guard_reserve) %>%
  dplyr::relocate(troops_all, .after = total_selected_reserve)

# Every reporting period must carry all fifty states and DC, and nothing else. A short period
# means the block was cut somewhere, which is how Wyoming went missing without anything failing.
local({
  expected.states <- stringr::str_to_title(c(datasets::state.name, "District of Columbia"))
  short <- troopdata_rebuild_us_states %>%
    dplyr::group_by(year, quarter) %>%
    dplyr::summarise(n_missing = sum(!expected.states %in% state) + sum(!state %in% expected.states),
                     .groups = "drop") %>%
    dplyr::filter(n_missing > 0)
  if (nrow(short) > 0) {
    warning("troopdata_rebuild_us_states does not hold exactly the 51 states in ", nrow(short), " period(s): ",
            paste0(short$year, " Q", short$quarter, " (", short$n_missing, ")", collapse = ", "),
            call. = FALSE)
  }
})









#### Country Name Standardization ####

# Single source of truth for country names. Applied to BOTH the reports frame and the long frame
# so that a given ccode carries the same countryname in every object the package ships. Without
# this the two frames disagree (e.g. 572 appeared as "Eswatini" in the reports and "Swaziland" in
# the long data), and host = "<name>" in get_troopdata() then matches in one and not the other.
standardize_countryname <- function(.data) {
  .data %>%
    dplyr::mutate(countryname = dplyr::case_when(
    countryname == "United States of America" ~ "United States",
    # Custom code 6. countrycode cannot name it and it is not a G&W state, so without this branch
    # every Puerto Rico row was dropped at the no-countryname filter: 107 report rows, 1950-2025.
    ccode == 6 ~ "Puerto Rico",
    ccode == 52 ~ "Trinidad and Tobago",
    ccode == 58 ~ "Antigua",
    ccode == 60 ~ "St. Kitts and Nevis",
    # G&W 260 is the German Federal Republic. The name applies to the whole series: it is West
    # Germany while the country was divided and, after 1990, the same state having absorbed the GDR,
    # so one name covers both periods without the year split North/South Vietnam needs. 265 remains
    # the German Democratic Republic, bounded at 1990.
    ccode == 260 ~ "Federal Republic of Germany",
    ccode == 316 ~ "Czech Republic",
    ccode == 343 ~ "Macedonia",
    ccode == 345 & year <= 2006 ~ "Yugoslavia",
    ccode == 345 & year > 2006 ~ "Serbia",
    ccode == 346 ~ "Bosnia and Herzegovina",
    ccode == 396 ~ "Abkhazia",
    ccode == 402 ~ "Cabo Verde",              # G&W 402 = Cape Verde (was custom 1015 "Scabo Verde")
    ccode == 403 ~ "Sao Tome and Principe",
    ccode == 437 ~ "Ivory Coast",
    ccode == 484 ~ "Congo",
    ccode == 490 ~ "Democratic Republic of the Congo",
    ccode == 571 ~ "Botswana",
    ccode == 572 ~ "Eswatini",               # G&W 572 = Swaziland (was 571, which is Botswana)
    ccode == 591 ~ "Seychelles",              # G&W microstate 591 = Seychelles (was custom 1036)
    ccode == 678 ~ "Yemen",                    # G&W code for Republic of Yemen
    ccode == 680 ~ "Yemen People's Republic",
    ccode == 775 ~ "Myanmar",
    ccode == 731 ~ "North Korea",
    ccode == 732 ~ "South Korea",
    ccode == 1003 ~ "Vatican City",           # custom code; G&W 327 is the Papal States (-1870)
    ccode == 816 & year <= 1975 ~ "North Vietnam",  # G&W 816 = Democratic Republic of Vietnam
    ccode == 816 ~ "Vietnam",                 # and unified Vietnam from 1976
    ccode == 817 ~ "South Vietnam",           # G&W 817 = Republic of Vietnam (South Vietnam)
    ccode == 860 ~ "East Timor",
    ccode == 950 ~ "Fiji",                    # G&W microstate 950 = Fiji (split from custom 1028)
    ccode == 972 ~ "Tonga",                   # G&W microstate 972 = Tonga (split from custom 1028)
    ccode == 987 ~ "Micronesia",
    grepl(".*Hong Kong.*", countryname, ignore.case = TRUE) & year < 1997 ~ "Hong Kong",
    grepl(".*Hong Kong.*", countryname, ignore.case = TRUE) & year >= 1997 ~ "China",
    ccode == 1009 ~ "Hong Kong",
    ccode == 1001 ~ "Gibraltar",
    ccode == 1002 ~ "Greenland",
    ccode == 1004 ~ "Diego Garcia",
    ccode == 1005 ~ "St. Helena",
    ccode == 1007 ~ "Bermuda",
    ccode == 1008 ~ "Guam",
    ccode == 1011 ~ "Northern Mariana Islands",
    ccode == 983 ~ "Marshall Islands",
    ccode == 1012 ~ "Midway Islands",
    ccode == 1013 ~ "US Virgin Islands",
    ccode == 1014 ~ "Wake Island",
    ccode == 1015 ~ "Scabo Verde",            # Retain custom code for non-G&W cases
    ccode == 1016 ~ "Netherlands Antilles",
    ccode == 1017 ~ "Spratly Islands",
    ccode == 1018 ~ "Trucial States",
    ccode == 1019 ~ "Aruba",
    ccode == 1021 ~ "Akrotiri",
    ccode == 1022 ~ "Coral Sea Islands",
    ccode == 1023 ~ "Svalbard",
    ccode == 1024 ~ "Bassas Da India",
    ccode == 1025 ~ "Curacao",
    ccode == 1026 ~ "Martinique",
    ccode == 1027 ~ "Sint Maarten",
    ccode == 1028 ~ "Fiji and Tonga",         # Retain custom code if still needed
    ccode == 1030 ~ "Line Islands",
    ccode == 1031 ~ "Easter Island",
    ccode == 1032 ~ "British West Indies",
    ccode == 1033 ~ "Sarawak",
    ccode == 1034 ~ "Western Sahara",
    ccode == 1035 ~ "British Virgin Islands",
    ccode == 1037 ~ "Turks and Caicos Islands",
    ccode == 1038 ~ "Kashmir",
    ccode == 1040 ~ "Azores",
    ccode == 1041 ~ "American Samoa",
    ccode == 1042 ~ "Ascension Island",
    ccode == 10000 ~ "Antarctica",
    ccode == 10200 ~ "Afloat",                # personnel afloat, worldwide; not a place
    ccode == 10100 ~ "Johnston Island",
    ccode == 10101 ~ "Eniwetok (J.T.F. 7)",
    TRUE ~ countryname
    ))
}


#### Build Reports Frame ####

# Combine the US and international data into a single data frame
troopdata_rebuild_reports <- bind_rows(data.clean.combined.international,
                                       data.afloat.global,
                                       data.us.combined.all) %>%
  dplyr::arrange(ccode, countryname, year, month, quarter) %>%
  dplyr::select(ccode, countryname, year, month, quarter, tidyselect::everything(), -c(grouping, grouping_num)) %>%
  dplyr::mutate(across(tidyselect::everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>%
  dplyr::mutate(source = case_when(
    is.na(source) & ccode == 2 ~ "Not Reported", # Fill in missing source values for unreported US data.
    TRUE ~ source
  )) %>%
  # Vietnam arrives under three different codes: custom.gwn sends "South Viet-Nam" and
  # "Indo-China" to 817, while countrycode's gwn lookup sends plain "Viet Nam" / "VIETNAM" to 815.
  # G&W 815 is a nineteenth century polity (Annam/Cochin China) and should hold no post-1950
  # deployments at all; 817 is the Republic of Vietnam, which ends in 1975; 816 is unified Vietnam
  # from 1976. Recode on year, because the location string cannot tell 1963 "Viet Nam" (RVN) from
  # 2018 "VIETNAM" (unified).
  dplyr::mutate(ccode = dplyr::case_when(
    ccode == 815 & year <= 1975 ~ 817,
    ccode %in% c(815, 817) & year > 1975 ~ 816,
    ccode == 340 & year < 2006 ~ 345,   # Serbia is not a state 1915-2006; those rows are Yugoslavia
    ccode == 327 ~ 1003,                # G&W 327 is the Papal States; the Holy See gets a custom code
    TRUE ~ ccode
  ),
  # "Indo-China" fuzzy-matches China in the country.name -> iso3c lookup.
  iso3c = dplyr::case_when(
    ccode == 817 ~ "VNM",
    grepl("Indo-China", Location, ignore.case = TRUE) ~ "VNM",
    # "TRUCIAL STATES" matches Oman and "BASSAS DA INDIA" matches India in the name lookup.
    ccode %in% c(1018, 1024) ~ unname(custom.iso3c[as.character(ccode)]),
    TRUE ~ iso3c
  )) %>%
  # The reports frame derives iso3c from the raw Location string, which leaves 634 rows across 38
  # codes unresolved -- footnote suffixes and old names ("Yemen Arab Republic", "Netherlands Antilles
  # (1991 - 2010)", "Johnston Atoll") defeat the name lookup even for ordinary sovereign states.
  # Fill those from the ccode, which is already resolved, using the same table the country-year frame
  # uses. Coalesce rather than overwrite, so a value the Location lookup got right is never replaced.
  dplyr::mutate(iso3c = dplyr::coalesce(
    iso3c,
    fill_iso3c(countrycode(ccode, "gwn", "iso3c"), ccode, year)
  )) %>%
  # NOTE: standardize_countryname() is deliberately NOT applied here. The reports frame keeps the
  # names the reports themselves use, so a country code can carry several location names within it
  # (Japan and the Ryukyu Islands under 740, Guam and the Northern Marianas under 1008). Those are
  # aggregated to the country level by get_troopdata(), not flattened in the stored reports.
  dplyr::mutate(region = countrycode(ccode, "gwn", "region"),
                source = case_when(
                  year %in% c(1951:1952) ~ "Stepwise Interpolation",
                  TRUE ~ source
                )) %>%
  # The gwn -> region lookup returns nothing for the custom codes, so label the Pacific territories
  # with the same region the country-year data gives them.
  dplyr::mutate(region = dplyr::case_when(
    ccode == afloat.code ~ "Afloat",                            # personnel afloat are in no region
    is.na(region) & ccode %in% c(983, 1008, 1011) ~ "East Asia & Pacific",
    is.na(region) & ccode == 6 ~ "Latin America & Caribbean",   # Puerto Rico
    # The nine territories brought in with custom.gwn; the same regions as the country-year frame.
    is.na(region) & ccode %in% c(1017, 1022) ~ "East Asia & Pacific",
    is.na(region) & ccode == 1018 ~ "Middle East & North Africa",
    is.na(region) & ccode %in% c(1021, 1023) ~ "Europe & Central Asia",
    is.na(region) & ccode == 1024 ~ "Sub-Saharan Africa",
    is.na(region) & ccode %in% c(1025, 1026, 1027) ~ "Latin America & Caribbean",
    # Same single-vocabulary rule as the long frame: whichever MENA spelling the installed
    # countrycode version returns, the column ends up on the house label. get_troopdata() matches a
    # region `host` against this column when reports = TRUE, so both frames must agree.
    grepl("Middle East", region) ~ "Middle East & North Africa",
    TRUE ~ region
  )) %>%
  dplyr::select(ccode, countryname, region, year, month, quarter, tidyselect::everything(), -fips) %>%
  ungroup() # Remove grouping

# Guard: in every report, the personnel afloat attributed to locations must fit inside the
# worldwide afloat figure, service by service, and the worldwide figure must be the sum of its two
# services. get_troopdata(afloat = "include") moves the attributed personnel out of the worldwide
# row and into the locations; if they did not fit, the same people would be counted twice or the
# worldwide row would go negative.
local({
  check <- troopdata_rebuild_reports %>%
    dplyr::group_by(source) %>%
    dplyr::summarise(
      worldwide = sum(troops_ad[ccode == afloat.code], na.rm = TRUE),
      worldwide_navy = sum(navy_ad[ccode == afloat.code], na.rm = TRUE),
      worldwide_marine_corps = sum(marine_corps_ad[ccode == afloat.code], na.rm = TRUE),
      placed_navy = sum(navy_afloat[ccode != afloat.code], na.rm = TRUE),
      placed_marine_corps = sum(marine_corps_afloat[ccode != afloat.code], na.rm = TRUE),
      .groups = "drop") %>%
    dplyr::filter(worldwide > 0 | placed_navy > 0 | placed_marine_corps > 0)

  over <- check %>%
    dplyr::filter(placed_navy > worldwide_navy | placed_marine_corps > worldwide_marine_corps)
  unbalanced <- check %>%
    dplyr::filter(worldwide != worldwide_navy + worldwide_marine_corps)

  if (nrow(over) > 0) {
    warning("Personnel afloat: attributed to locations exceeds the worldwide figure in ",
            paste(over$source, collapse = ", "), call. = FALSE)
  }
  if (nrow(unbalanced) > 0) {
    warning("Personnel afloat: the worldwide figure is not the sum of Navy and Marine Corps in ",
            paste(unbalanced$source, collapse = ", "), call. = FALSE)
  }
  message("Personnel afloat: ", nrow(check), " reports; ",
          format(sum(check$placed_navy + check$placed_marine_corps), big.mark = ","),
          " of ", format(sum(check$worldwide), big.mark = ","),
          " personnel afloat attributed to a location.")
})








#### Build Long Form Frame ####
####

# Country-years for which a DMDC report gives a figure. A Kane row is used only where this has
# nothing: Kane is a fallback for what the reports do not cover, not a second observation of what
# they do.
#
# A figure counts when the report prints one, zero included. The exception is the rows the
# reports print as zero in place of a number -- "Iraq (See OIF Table)", "Afghanistan (not
# available)", "Kuwait (See Deployment Section)" and their unannotated equivalents in the same
# years. Those are the deployments the Kane rows and the estimates further down exist to fill, so
# they are treated as not reported.
#
# Hong Kong is folded into China from 1997 further down, after the Kane rows are bound in, so
# the same recode is applied here: "China (Includes Hong Kong)" is the China row of the 2000-2007
# reports, and without this the Kane row for China stayed beside it.
#
# The other exception is Iraq and Syria from 2018. From the December 2017 report the DMDC leaves
# out personnel deployed to Iraq, Syria and Afghanistan, and what it prints for those countries is
# the handful assigned there permanently: 158 for Iraq and 1 for Syria in December 2021, against
# deployments of about 2,500 and 900. The figures in the gap file for those years come from
# public reporting (see the 0.1.4 notes in NEWS.md for the two 2021 sources), and they are kept
# beside the report rows; the annual figure is the larger of the two.
dmdc.reported <- troopdata_rebuild_reports %>%
  dplyr::ungroup() %>%
  dplyr::filter(!is.na(troops_ad)) %>%
  dplyr::filter(!(troops_ad == 0 & ccode %in% c(645, 690, 700) & year %in% 2002:2007)) %>%
  dplyr::filter(!(ccode %in% c(645, 652) & year >= 2018)) %>%
  dplyr::mutate(ccode = dplyr::if_else(ccode == 1009 & year >= 1997, 710, ccode)) %>%
  dplyr::distinct(ccode, year)

troopdata_rebuild_long <- country.year.list %>%
  full_join(troopdata_rebuild_reports, by = c("ccode", "year", "month", "quarter")) %>%
  dplyr::filter(month == "June" & year %in% c(1950:1956) | # All reports are from June between 1950 and 1956
                  month == "September" & year >= 1957 | # All reports are from September between 1957 and 2012
                  month == "December" & year >= 2013 |
                  month == "June" & year >= 2014 |
                  month == "March" & year >= 2014) %>%
  ungroup() %>%
  # The report headers "Navy Afloat" and "Marine Corps Afloat" would be cleaned to navy_afloat and
  # marine_corps_afloat, the names of the two built columns, and clean_names() would then number
  # one of each pair. The built columns are the ones wanted here, so the headers go first.
  dplyr::select(-dplyr::any_of(c("Navy Afloat", "Marine Corps Afloat"))) %>%
  # clean_names() turns the report headers into the names used from here on ("Army National Guard"
  # -> army_national_guard, "DOD Civilian" -> dod_civilian). The components are then selected by
  # name rather than with contains(), so a missing column is an error here and the column order
  # downstream is fixed rather than incidental.
  janitor::clean_names() %>%
  dplyr::select(ccode, countryname, year, month, quarter, source, location, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad,
                troops_afloat, navy_afloat, marine_corps_afloat,
                army_national_guard, air_national_guard, army_reserve, navy_reserve,
                marine_corps_reserve, air_force_reserve, coast_guard_reserve,
                total_selected_reserve, army_civilian, navy_civilian, marine_corps_civilian,
                air_force_civilian, dod_civilian, total_civilian) %>%  # select only variables to be exported to package
  #dplyr::select(-statenme) %>% Not needed with G&W update
  # Kane rows are all stamped month = "June" / quarter = 2. They used to be dropped only where a
  # DMDC report existed for that same month, so for 1957 to 2013, when the reports are dated
  # September, every Kane row stayed beside the report for the same year. The annual figure is the
  # larger of the quarters, and wherever Kane's figure was the higher one that was the Kane row:
  # Germany read 85,419 for 2006, the report's 64,319 plus 21,100 deployed to Iraq, who are
  # counted in Iraq as well.
  #
  # A Kane row is now brought in only for a country-year the reports do not cover (dmdc.reported
  # above). What is left is small: the 1951 and 1952 rows, the Iraq, Kuwait, Afghanistan and Syria
  # rows for the years the reports leave those countries out, and about a dozen country-years
  # where a report has no row for the country.
  dplyr::bind_rows(
    data.gaps %>%
      dplyr::anti_join(dmdc.reported, by = c("ccode", "year"))
  ) %>%
  # Every code correction happens FIRST, before iso3c and countryname are derived from the code.
  # Deriving them first and recoding afterwards leaves a row labelled by the code it used to carry:
  # that is how ccode 817 ended up holding both "South Vietnam" and "Vietnam".
  # G&W 816 is the Democratic Republic of Vietnam (North Vietnam) while Vietnam was divided, and
  # unified Vietnam from 1976. It must NOT be folded into 817: the scaffold is built from the G&W
  # system list, so it supplies North Vietnam country-years for the divided period exactly as it
  # supplies East Germany, South Yemen and North Korea, none of which host US troops either. Only
  # 815 needs recoding -- countrycode's gwn lookup sends plain "Viet Nam" / "VIETNAM" there, and
  # G&W 815 is a nineteenth century polity (Annam/Cochin China) that must hold no post-1950 rows.
  dplyr::mutate(ccode = dplyr::case_when(
    ccode == 815 & year <= 1975 ~ 817,  # a bare "Viet Nam" report before the fall is the RVN
    ccode %in% c(815, 817) & year > 1975 ~ 816,  # 817 cannot outlive 1975; 815 never applies
    ccode == 1009 & year >= 1997 ~ 710,  # Hong Kong ceded to China in 1997
    # Serbia did not exist as a state between 1915 and 2006 in the G&W list, but the reports carry a
    # literal "Serbia" location for 1995-1998 (13, 8, 13 and 37 personnel). Those were landing on 340
    # alongside Yugoslavia's own 345 rows for the same years, so the panel held two country-years for
    # one territory. Send them to 345, which is the state that existed.
    ccode == 340 & year < 2006 ~ 345,
    # G&W 327 is the Papal States, 1816-1870. The reports' "Vatican City" rows (1985-2020) are the
    # modern Holy See, which is not a G&W state at all, so reusing 327 for them contradicts the system
    # list the scaffold is built from -- the same kind of collision as 571 Botswana carrying Swaziland.
    # 1003 is the next free number in this build's custom territory block (1001-1042).
    ccode == 327 ~ 1003,
    TRUE ~ ccode
  )) %>%
  # Bind every state to the end of its own existence, using the G&W system list as the authority.
  # Applied AFTER the recodes above so the bound is matched against the code a row finally carries.
  # Only the upper bound is applied: country.year.list.supplement deliberately adds years BEFORE a
  # state's independence so Kane's 1950s deployments to places like Algeria are not lost, and
  # bounding the start would delete them. Codes absent from the lookup -- states still in existence,
  # and the custom territory codes the G&W list does not carry -- are left alone.
  dplyr::left_join(gw.state.endyear, by = "ccode") %>%
  dplyr::filter(is.na(gw_endyear) | year <= gw_endyear) %>%
  dplyr::select(-gw_endyear) %>%
  # countrycode has no gwn -> iso3c entry for the G&W microstates, the territory codes, or several
  # historical states, which left those rows with iso3c = NA and made host = "ATG" (etc.) return
  # nothing. custom.iso3c is the single table for both frames; see its definition for the conventions.
  dplyr::mutate(iso3c = fill_iso3c(countrycode(ccode, "gwn", "iso3c"), ccode, year)) %>%
  dplyr::mutate(countryname = countrycode(ccode, "gwn", "country.name", custom_match = custom.gwn))  %>%
  standardize_countryname() %>%
  # Fall back to the G&W list's own name for any state countrycode could not name, so that every
  # state in the system list reaches the panel even when no US personnel were ever reported there --
  # the same treatment North Korea, South Yemen and East Germany already get. Coalesce, so a name
  # assigned above is never overwritten.
  dplyr::left_join(gw.state.names, by = c("ccode" = "statenumber")) %>%
  dplyr::mutate(countryname = dplyr::coalesce(countryname, gw_name)) %>%
  dplyr::select(-gw_name) %>%
  # Guard: 817 is the Republic of Vietnam and cannot outlive it. The recode above should leave
  # nothing for this to remove.
  dplyr::filter(!(ccode == 817 & year > 1975)) %>%
  # Anything still unnamed here is dropped, which is how the microstates disappeared. Say so.
  {
    unnamed <- dplyr::distinct(dplyr::filter(., is.na(countryname)), ccode)
    if (nrow(unnamed) > 0) {
      warning("Dropping rows with no countryname for ccode(s): ",
              paste(sort(unnamed$ccode), collapse = ", "), call. = FALSE)
    }
    .
  } %>%
  dplyr::filter(!is.na(countryname)) %>%
  dplyr::mutate(across(tidyselect::everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>% # Replace infinite values with NA
  dplyr::mutate(across(tidyselect::everything(), ~ case_when( # 0 values in US with NA
    ccode == 2 & . == 0 ~ NA,
    TRUE ~ .
  ))) %>% # Replace infinite values with NA
  dplyr::group_by(ccode, year, month, quarter) %>%
  dplyr::summarise(across(matches("_ad|_afloat|civilian|guard|reserve"), ~ sum(., na.rm = TRUE)),
                   countryname = first(countryname),
                   iso3c = first(iso3c),
                   source = first(source)) %>%
  # Add Kane's data here to fill in gaps in coverage. Should come after all DMDC reports are cleaned and consolidated.
  #plyr::rbind.fill(data.gaps) %>%
  rowwise() %>%
  # Recalculate troops_ad to make sure Kane values are overwritten by higher branch totals in some cases.
  dplyr::mutate(troops_ad_kane_check = army_ad + navy_ad + air_force_ad + marine_corps_ad + coast_guard_ad + space_force_ad) %>%
  rowwise() %>%
  dplyr::mutate(troops_ad = max(troops_ad, troops_ad_kane_check)) %>%
  dplyr::mutate(troops_ad = case_when( # Add values from reports to fill in missing data for Iraq and Afghanistan and other estimated values for US and other cases as needed.
    # These are external estimates for periods the reports do not cover. Where the report does carry
    # branch-level figures, troops_ad is already their sum (see the max() above) and that reported
    # sum is kept in preference to the estimate. The estimates below apply only where there are no
    # branch values to add up.
    !is.na(troops_ad_kane_check) & troops_ad_kane_check > 0 ~ troops_ad,
    ccode == 200 & year == 2014 ~ 8495,
    ccode == 700 & year == 2020 ~ 8600, # Afghanistan update from just security
    ccode == 700 & year == 2019 ~ 13000, # Afghanistan update
    ccode == 700 & year == 2018 ~ 14000, # Afghanistan update
    ccode == 652 & year == 2018 ~ 1700, # Syria update from just security
    ccode == 652 & year == 2019 ~ 1000,
    ccode == 652 & year == 2020 ~ 900,
    ccode == 645 & year == 2006 & !is.na(troops_ad) ~ 141100, # FAS update for Iraq
    ccode == 645 & year == 2007 & !is.na(troops_ad) ~ 170000, # Reuters update for Iraq
    ccode == 690 & year == 2003 ~ 47000, # Kuwait values from Kane's original data
    ccode == 690 & year == 2004 ~ 36647, # Kuwait values from Kane's original data
    ccode == 690 & year == 2005 ~ 42600, # Kuwait values from Kane's original data
    ccode == 690 & year == 2006 ~ 44400, # Reverse engineered from OIF totals
    ccode == 690 & year == 2007 ~ 48500, # Reverse engineered from OIF totals
    TRUE ~ troops_ad)
  ) %>%
  # Record where each manually coded figure came from. These are the largest values in the series
  # that do not come from a DMDC report -- Afghanistan 2018-2020 alone is 142,400 troop-years -- and
  # they were carrying source = NA, so the `source` column attributed them to nothing. The condition
  # list mirrors the overrides above, including the branch-sum precedence rule, so a row only gets an
  # estimate label where the estimate was actually applied.
  dplyr::mutate(source = dplyr::case_when(
    !is.na(troops_ad_kane_check) & troops_ad_kane_check > 0 ~ source,
    ccode == 200 & year == 2014 ~ "Estimate, external source",
    ccode == 700 & year %in% c(2018, 2019, 2020) ~ "Estimate, Just Security",
    ccode == 652 & year %in% c(2018, 2019, 2020) ~ "Estimate, Just Security",
    ccode == 645 & year == 2006 & !is.na(troops_ad) ~ "Estimate, Federation of American Scientists",
    ccode == 645 & year == 2007 & !is.na(troops_ad) ~ "Estimate, Reuters",
    # The two 2021 figures kept from the gap file (see dmdc.reported). The sources are the ones
    # given in NEWS.md under version 0.1.4. Only the June row is the estimate; the September and
    # December rows are the DMDC reports and keep their own source.
    ccode == 645 & year == 2021 & month == "June" & troops_ad == 2500 ~ "Estimate, New York Times",
    ccode == 652 & year == 2021 & month == "June" & troops_ad == 900 ~ "Estimate, Politico",
    ccode == 690 & year %in% c(2003, 2004, 2005) ~ "Kane 2006",
    ccode == 690 & year %in% c(2006, 2007) ~ "Estimate, reverse engineered from OIF totals",
    TRUE ~ source)
  ) %>%
  dplyr::select(ccode, iso3c, countryname, year, month, quarter, source, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad, troops_afloat, navy_afloat, marine_corps_afloat, contains("national_guard"), contains("reserve"), contains("civilian")) %>%  # select only variables to be exported to package
  arrange(ccode, iso3c, year, month, quarter) %>%
  dplyr::group_by(ccode) %>%
  # The Army reported nothing for December 2022, March 2023 and June 2023 while it converted to
  # IPPS-A. The workbooks for those quarters show N/A in the three Army columns that depend on it
  # (active duty, National Guard, Reserve) and in every total, and real figures everywhere else.
  # So only the three Army columns are filled, by stepping linearly between the two reported
  # quarters that bracket the gap, September 2022 and September 2023, both left exactly as
  # reported; troops_ad and total_selected_reserve are then rebuilt from their components.
  #
  # An earlier version dropped these rows altogether, because their total was N/A, and
  # interpolated every column, so figures the Navy, Marine Corps, Air Force and Coast Guard had
  # reported were replaced with estimates: the Marine Corps in Japan read about 18,160 for December
  # 2022 against 21,132 reported, and in Norway 24 for March 2023 against 683.
  #
  # A location with no row on one side of the gap is taken as zero on that side, the same as any
  # other period in which a report does not list it.
  #
  # The previous version wrote `year_quarter %in% c(2022.3:2023.3)`. R's colon operator steps by 1,
  # so that vector is just c(2022.3, 2023.3): the three quarters in between were never filled, and
  # September 2023 -- an anchor, and a real reported figure -- was overwritten with an interpolated
  # value that differed from the published report for 99 of 168 countries.
  dplyr::mutate(year_quarter = as.numeric(glue::glue("{year}.{quarter}"))) %>%
  dplyr::mutate(dplyr::across(
    tidyselect::all_of(c("army_ad", "army_national_guard", "army_reserve")),
    ~ {
      gap.start <- .x[year == 2022 & quarter == 3]
      gap.end <- .x[year == 2023 & quarter == 3]
      gap.start <- if (length(gap.start) == 1 && !is.na(gap.start)) as.numeric(gap.start) else 0
      gap.end <- if (length(gap.end) == 1 && !is.na(gap.end)) as.numeric(gap.end) else 0
      gap.step <- (gap.end - gap.start) / 4

      dplyr::case_when(
        year == 2022 & quarter == 4 ~ round(gap.start + gap.step),
        year == 2023 & quarter == 1 ~ round(gap.start + (2 * gap.step)),
        year == 2023 & quarter == 2 ~ round(gap.start + (3 * gap.step)),
        TRUE ~ as.numeric(.x)
      )
    }
  )) %>%
  # The totals for those three quarters are N/A in the workbooks, so they are the sum of their
  # components: the interpolated Army figure plus what the other services reported.
  dplyr::ungroup() %>%
  dplyr::mutate(
    army_gap = (year == 2022 & quarter == 4) | (year == 2023 & quarter %in% c(1, 2)),
    troops_ad = dplyr::if_else(
      army_gap,
      rowSums(dplyr::across(c(army_ad, navy_ad, air_force_ad,
                              marine_corps_ad, coast_guard_ad, space_force_ad)),
              na.rm = TRUE),
      as.numeric(troops_ad)),
    total_selected_reserve = dplyr::if_else(
      army_gap,
      rowSums(dplyr::across(c(army_national_guard, air_national_guard, army_reserve,
                              navy_reserve, marine_corps_reserve, air_force_reserve,
                              coast_guard_reserve)),
              na.rm = TRUE),
      as.numeric(total_selected_reserve))) %>%
  dplyr::select(-army_gap) %>%
  dplyr::group_by(ccode) %>% # Start to fill in 1951 and 1952 estimates using stepwise increases.
  dplyr::mutate(troops_ad_1950 = ifelse(year %in% c(1950:1953), troops_ad[year==1950], NA),
                troops_ad_1953 = ifelse(year %in% c(1950:1953), troops_ad[year==1953], NA),
                troops_ad_incremental_difference = round((troops_ad_1953 - troops_ad_1950) / 3, 0) ) %>%
  dplyr::mutate(troops_ad = case_when(
    year == 1951 ~ troops_ad_1950 + troops_ad_incremental_difference,
    year == 1952 ~ troops_ad_1950 + (2 * troops_ad_incremental_difference),
    TRUE ~ troops_ad
  )) %>%
  dplyr::select(-c(troops_ad_1950, troops_ad_1953, troops_ad_incremental_difference)) %>%
  dplyr::mutate(troops_all = troops_ad + army_national_guard + air_national_guard + army_reserve + navy_reserve + marine_corps_reserve + air_force_reserve + coast_guard_reserve) %>% # This adds active duty with reserves separately.
  ungroup() %>%
  dplyr::mutate(region = countrycode::countrycode(ccode,
                                                  origin = "gwn",
                                                  destination = "region"),
                # Need to make another pass over the regions because the data.gaps filler creates some missing observations.
                region = case_when(
                  ccode == afloat.code ~ "Afloat", # personnel afloat are in no region
                  # The nine territories brought in with custom.gwn.
                  ccode %in% c(1017, 1022) ~ "East Asia & Pacific",         # Spratly Islands, Coral Sea Islands
                  ccode == 1018 ~ "Middle East & North Africa",             # Trucial States
                  ccode %in% c(1021, 1023) ~ "Europe & Central Asia",       # Akrotiri, Svalbard
                  ccode == 1024 ~ "Sub-Saharan Africa",                     # Bassas da India
                  ccode %in% c(1025, 1026, 1027) ~ "Latin America & Caribbean", # Curacao, Martinique, Sint Maarten
                  grepl(".*Ryukyu.*|.*Indo-China.*|.*Hong Kong.*|.*Wake.*|.*Virgin.*|.*Samoa.*|.*Midway.*|.*Marshall.*|.*Mariana.*|.*Johnston.*|.*Guam.*|.*Sarawak.*|.*Line Islands.*|.*Atoll.*|.*Palau.*|.*Tuvalu.*|.*Vanuatu.*|.*Tonga.*|.*Vietnam.*|.*Nauru.*|.*Fiji.*|.*Micronesia.*|.*Eniwetok.*|.*Kiribati.*|.*Leward.*", countryname) ~ "East Asia & Pacific",
                  grepl(".*Antar.*", countryname) ~ "Antarctica",
                  # St. Helena is a South Atlantic territory, not MENA, and Ascension -- the same
                  # British overseas territory -- is already mapped to Sub-Saharan Africa below.
                  grepl(".*Helena.*", countryname) ~ "Sub-Saharan Africa",
                  grepl(".*Sahara.*|.*Aden.*", countryname) ~ "Middle East & North Africa",
                  grepl(".*Caicos.*|.*Turks Island.*|.*Puerto Rico.*|.*Kitts.*|.*Antilles.*|.*Dominica.*|.*Leeward.*|.*Grenada.*|.*Easter.*|.*Bermuda.*|.*British West.*|.*British Virgin.*|.*Aruba.*|.*Lucia.*|.*Vincent.*|.*Antigua.*", countryname) ~ "Latin America & Caribbean",
                  grepl(".*Kashmir.*|.*Diego.*|.*Seychelles.*", countryname) ~ "South Asia",
                  ccode == 1004 ~ "South Asia",
                  grepl(".*Gibraltar.*|.*Azore.*|.*Monaco.*|.*Gilbral.*|.*Andorra.*|.*Liechtenstein.*|.*Ossetia.*|.*Marino.*|.*Abkhazia.*", countryname) ~ "Europe & Central Asia",
                  ccode == 1001 ~ "Europe & Central Asia", # Gibraltar missing country name
                  grepl(".*Ascension.*|.*Principe.*", countryname) ~ "Sub-Saharan Africa",
                  grepl(".*Greenland.*", countryname) ~ "North America",
                  ccode == 1002 ~ "Europe & Central Asia", # Greenland missing country name
                  ccode == 711 ~ "East Asia & Pacific",    # Tibet; same region as China (710)
                  ccode == 1003 ~ "Europe & Central Asia", # Vatican City / Holy See
                  TRUE ~ region
                ),
                # countrycode renamed its World Bank MENA label to "Middle East, North Africa,
                # Afghanistan & Pakistan", and both spellings were reaching this column, so
                # get_troopdata(host = "Middle East & North Africa") -- which matches host against
                # this column -- returned 4 countries and silently missed Iraq, Saudi Arabia, Egypt
                # and the rest. One label, and it is the shorter one: Afghanistan (700) and Pakistan
                # (770) are classified in South Asia in this data, so a MENA label that names them
                # describes a grouping the column does not actually use. Matching on "Middle East"
                # rather than the exact old string means a further rename upstream also lands here.
                region = dplyr::case_when(
                  grepl("Middle East", region) ~ "Middle East & North Africa",
                  TRUE ~ region
                ),
                source = case_when(
                  year %in% c(1951, 1952) ~ "Stepwise Imputation",
                  TRUE ~ source
                )
                # A row with no region is invisible to a region `host` filter, so surface the gap
                # rather than shipping NA. Tibet (711) was the one that slipped through: countrycode
                # has no gwn -> region entry for it and no name rule above matched.
  ) %>%
  dplyr::mutate(across(c(army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad),
                       ~ case_when(
                         year %in% c(1951:1952) ~ NA,
                         TRUE ~ .x
                       )
  )
  ) %>%
  # This next mutate chunk addresses true NA from false NA values and
  # should preserve observations for country years that aren't showing up in the
  # final data frame because they get dropped.
  # The second rule here used to read
  #
  #   across(coast_guard_ad:coast_guard_reserve,
  #          ~ case_when(is.na(.x) & year >= 2008 ~ 0,
  #                      is.na(.x) & year < 2008 ~ NA))
  #
  # with no `TRUE ~ .x`. case_when() returns NA for a row that matches no condition, and both
  # conditions require is.na(.x), so every value that was NOT missing fell through and was replaced
  # with NA. The summarise() above has already turned missing into 0, so nothing was missing and the
  # whole range was wiped: nine columns, on every row. That is why the seven guard and reserve
  # components shipped empty, and Coast Guard and Space Force active duty with them (2.2 million and
  # 95,000 troop-years in the reports), while total_selected_reserve and the civilian columns
  # survived -- they simply sit to the right of coast_guard_reserve, outside the range. troops_all
  # stayed correct because it is computed further up, before the wipe.
  #
  # The columns are also named outright now. `a:b` selects by position, so which columns a rule
  # touches depended on the order an earlier select() happened to leave them in.
  # A category the DMDC did not report at all in a period is NA there, not 0. A 0 says the report
  # was checked and nobody was present; these categories were not in the report format. The guard
  # and reserve components, their total, the civilian columns and Coast Guard active duty all first
  # appear in the September 2008 report. Space Force first has a column of its own in September 2023
  # -- from December 2021 to June 2023 the sheets carry it inside a combined "AIR FORCE/SPACE FORCE"
  # column, so it is already counted in air_force_ad for those quarters -- which also means the
  # IPPS-A interpolation above must not leave a Space Force ramp behind in December 2022 to June
  # 2023: one end of that ramp is "not reported", not zero.
  #
  # From the first reported period on, a missing cell is a true zero, because the country was in the
  # report and the cell was blank. Every case_when() here ends in a fallback, so a reported value
  # can only pass through. troops_all is computed above, before any of this, so it stays equal to
  # troops_ad in the years with no guard or reserve reporting.
  dplyr::mutate(across(tidyselect::all_of(c("coast_guard_ad",
                                            "army_national_guard", "air_national_guard",
                                            "army_reserve", "navy_reserve",
                                            "marine_corps_reserve", "air_force_reserve",
                                            "coast_guard_reserve", "total_selected_reserve",
                                            "army_civilian", "navy_civilian",
                                            "marine_corps_civilian", "air_force_civilian",
                                            "dod_civilian", "total_civilian")),
                       ~ case_when(
                         year < 2008 ~ NA_real_,
                         is.na(.x) ~ 0,
                         TRUE ~ as.numeric(.x)
                       )),
                space_force_ad = case_when(
                  year < 2023 | (year == 2023 & quarter < 3) ~ NA_real_,
                  is.na(space_force_ad) ~ 0,
                  TRUE ~ as.numeric(space_force_ad)
                )
                ) %>%
  # Personnel afloat attributed to a location, on the same footing: a zero means a report that
  # lists personnel afloat by location has none for this one, and that is the reports of 1953 to
  # 1976. In 1950, and from 1977 to 2007, the reports give a figure for the United States and
  # (in 1950) one other location, and nothing for anywhere else, so only a figure that was
  # printed is kept and the rest is missing rather than zero. There is nothing for 1951 and 1952,
  # which have no report, or from 2008, when a crew is counted at its home port. The summarise()
  # above has turned every missing value into zero, so this is what tells them apart again. The
  # worldwide row (afloat.code) is not a location and has no attributed figure of its own.
  dplyr::mutate(
    afloat_listed = ccode != afloat.code &
      (year %in% 1953:1976 |
         (year %in% c(1950, 1977:2007) & dplyr::coalesce(troops_afloat, 0) > 0)),
    dplyr::across(c(troops_afloat, navy_afloat, marine_corps_afloat),
                  ~ dplyr::if_else(afloat_listed, dplyr::coalesce(as.numeric(.x), 0), NA_real_))) %>%
  dplyr::select(-afloat_listed) %>%
  dplyr::relocate(troops_afloat, navy_afloat, marine_corps_afloat, .after = space_force_ad)






# Export reports to csv
readr::write_csv(troopdata_rebuild_reports,
                 here::here("data-raw/troopdata-rebuild-reports.csv"))


# Export full country year quarter list data

# Guard: every branch and component column the reports populate must carry values in the finished
# frame. A case_when() with no fallback once replaced nine of them with NA on every row, which left
# get_troopdata(guard_reserve = TRUE) returning seven empty columns and branch = TRUE returning no
# Coast Guard or Space Force, while the totals looked fine. A warning here is cheaper than shipping it.
component.cols <- c("coast_guard_ad", "space_force_ad",
                    "army_national_guard", "air_national_guard", "army_reserve", "navy_reserve",
                    "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve",
                    "total_selected_reserve", "army_civilian", "navy_civilian",
                    "marine_corps_civilian", "air_force_civilian", "dod_civilian",
                    "total_civilian")

missing.cols <- setdiff(component.cols, names(troopdata_rebuild_long))
if (length(missing.cols) > 0) {
  warning("Component columns absent from troopdata_rebuild_long: ",
          paste(missing.cols, collapse = ", "), call. = FALSE)
}

empty.cols <- vapply(intersect(component.cols, names(troopdata_rebuild_long)), function(cl) {
  x <- troopdata_rebuild_long[[cl]][troopdata_rebuild_long$year >= 2023]
  all(is.na(x) | x == 0)
}, logical(1))

if (any(empty.cols)) {
  warning("Branch/component columns with no values at all in 2023 or later: ",
          paste(names(empty.cols)[empty.cols], collapse = ", "), call. = FALSE)
} else {
  message("Branch and component columns populated: ",
          length(component.cols), " of ", length(component.cols), " carry reported values.")
}

readr::write_csv(troopdata_rebuild_long,
                 here::here("data-raw/troopdata-rebuild-country-year-quarter-format.csv"))

readr::write_csv(troopdata_rebuild_us_states,
                 here::here("data-raw/troopdata-rebuild-us-state-data.csv"))

usethis::use_data(troopdata_rebuild_long,
                  troopdata_rebuild_reports,
                  troopdata_rebuild_us_states,
                  overwrite = TRUE,
                  internal = FALSE)

