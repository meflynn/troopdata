## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(data.table)
library(haven)
library(here)
library(readxl)
library(furrr)
library(furrr)
library(stringr)
library(countrycode)
library(usmap)

#### Load data and generate names for individual list objects ####
#
# Using the tidyverse package and the read_xlsx function, write a code chunk to load every .xls file in the /Users/michaelflynn/Library/CloudStorage/Dropbox/Projects/Troop Data/Data Files/M05 Military Only folder.
# Load each individual xls file into a list that contains all of the xls files in this folder.
# The list object chould be named "datalist".
#
#

# Load data files from 1950 to 1976
datalist.1950.1977 <- list.files(here("../../Projects/Troop Data/Data Files/M05 Military Only"), pattern = "xls", full.names = TRUE) |>
  furrr::future_map(.f = readxl::read_xls)

# Read file names into list for 1977 to 2010.
# Use this list to extract dates and names later on.
datalist.1977.2010.names <- list.files(here("../../Projects/Troop Data/Data Files/309A_Reports_1977-2011"), pattern = "\\.xls$", full.names = TRUE)

# Read in actual files from the list
datalist.1977.2010 <- datalist.1977.2010.names |>
  furrr::future_map(.f = readxl::read_xls)


# Read in file names for 2011 to 2023
datalist.2008.2023.names <- list.files(here("../../Projects/Troop Data/Data Files/2008-Present"), pattern = "\\.xlsx$", full.names = TRUE)

# Read in data files for 2011 to 2023 from the list of file names.
datalist.2008.2023 <- datalist.2008.2023.names |>
  furrr::future_map(.f = readxl::read_xlsx)


# Add previously cleaned data for 1951, 1952, 2003, and 2004.
data.gaps <- read_csv(here("../../Projects/Troop Data/Data Files/troop_data_1950_2016.csv")) |>
  janitor::clean_names() |>
  janitor::remove_empty("rows") |>
  janitor::remove_empty("cols")


# Pull names from the data frames and use them to generate names for each data frame in the list.
names.1950.1977 <- future_map(.x = seq_along(datalist.1950.1977),
             .f = ~ str_extract(datalist.1950.1977[[.x]][[1]],
                                pattern = "September\\s{1}([0-9]{4})|June\\s{1}([0-9]{4})") |>
               as.data.frame()
             ) |>
  bind_rows() |>
  drop_na()

listnames.1950.1977 <- as.vector(names.1950.1977[[1]])

# Basic data cleaning for 1950 to 1977
data.clean.1950.1977 <- datalist.1950.1977 |>
  furrr::future_map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Assign names to the data frames
names(data.clean.1950.1977) <- listnames.1950.1977



# Basic data cleaning for 1977 to 2011
data.clean.1977.2010 <- datalist.1977.2010 |>
  furrr::future_map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Pull years from file list for the 1976 to 2011 data.
listnames.1977.2010 <- future_map(.x = seq_along(datalist.1977.2010.names),
             .f = ~ str_extract(datalist.1977.2010.names[[.x]],
                                pattern = "September_([0-9]{4})|June_([0-9]{4})") |>
               as.data.frame()
             ) |>
  bind_rows() |>
  drop_na()

# Create an actual list of the months and years for naming list
listnames.1977.2010 <- as.vector(listnames.1977.2010[[1]]) |>
  str_replace_all(pattern = "_", replacement = " ")

names(data.clean.1977.2010) <- listnames.1977.2010



# Basic data cleaning for 2008 to 2023

data.clean.2008.2023 <- datalist.2008.2023 |>
  furrr::future_map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Pull years and months from the file list for the 2008 to Present Data
listnames.2008.2023 <- future_map(.x = seq_along(datalist.2008.2023.names),
             .f = ~ str_extract(datalist.2008.2023.names[[.x]],
                                pattern = "_([0-9]{4})") |>
               as.data.frame()
             ) |>
  bind_rows() |>
  drop_na() |>
  dplyr::rename("Date" = 1) |>
  dplyr::mutate(Date = str_replace_all(Date, pattern = "_", replacement = "20"),
                Year = str_extract(Date, pattern = "^[0-9]{4}"),
                Month = str_extract(Date, pattern = "[0-9]{2}$"),
                Month = month.name[as.numeric(Month)],
                Date = glue::glue("{Month} {Year}"))

listnames.2008.2023 <- as.vector(listnames.2008.2023[[1]])

names(data.clean.2008.2023) <- listnames.2008.2023


#### Name Columns ####

# Create separate list objects containing the data frames for time periods that have the same spreadsheet formatting.
# Each list object should only contain data frames with the same formatting and number of columns.

# Subset data for 1950 to 1953, 1954 to 1956, 1957 to 1967, and 1968 to 1976.
data.clean.1950.1953 <- data.clean.1950.1977[c(1:2)]

data.clean.1954.1956 <- data.clean.1950.1977[c(3:5)]

data.clean.1957.1967 <- data.clean.1950.1977[c(6:16)]

data.clean.1968.1976 <- data.clean.1950.1977[c(17:25)]

# Subset the data for 2008 to 2023 to only include data from September 2008 to June 2023. This is all of the pre-Space Force data.
data.clean.September.2008.June.2023 <- data.clean.2008.2023[c(1:45)]

# This is where space force comes into the data
data.clean.September.2023.December.2023 <- data.clean.2008.2023[c(46:47)]


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

names.2023.2024 <- c("Macro Location", "Location", "Army Active Duty", "Navy Active Duty", "Marine Corps Active Duty", "Air Force Active Duty", "Space Force Active Duty", "Coast Guard Active Duty", "Total Active Duty", "Army National Guard", "Army Reserve", "Navy Reserve", "Marine Corps Reserve", "Air National Guard", "Air Force Reserve", "Coast Guard Reserve", "Total Selected Reserve", "Army Civilian", "Navy Civilian", "Marine Corps Civilian", "Air Force Civilian", "DOD Civilian", "Total Civilian", "Grand Total")



# Apply names and remove uninformative or rows
data.clean.1950.1953 <- data.clean.1950.1953 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.1950.1953) |>
               slice(-c(1:2)) |>
               filter(!is.na(Location))
             )

data.clean.1954.1956 <- data.clean.1954.1956 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.1954.1956) |>
               slice(-c(1:2)) |>
               filter(!is.na(Location))
             )

data.clean.1957.1967 <- data.clean.1957.1967 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.1957.1967) |>
               slice(-c(1:2)) |>
               filter(!is.na(Location))

             )

data.clean.1968.1976 <- data.clean.1968.1976 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.1968.1976) |>
               slice(-c(1:2)) |>
               filter(!is.na(Location))
             )

data.clean.1977.2010 <- data.clean.1977.2010 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.1977.2010) |>
               slice(-c(1:3)) |>
               filter(!is.na(Location))

             )

data.clean.September.2008.June.2023 <- data.clean.September.2008.June.2023 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.2008.2023) |>
               slice(-c(1:5)) |>
               filter(!is.na(Location))
             )


data.clean.September.2023.December.2023 <- data.clean.September.2023.December.2023 |>
  furrr::future_map(.f = ~ .x |>
               setNames(names.2023.2024) |>
               slice(-c(1:5)) |>
               filter(!is.na(Location))
             )

# Note that each region has an "afloat" category attached. We'll have to deal with this and treat it as its own country/location.


# Use countrycode package to generate COW country codes for individual countries listed in each list object data frame.

# Generate custom dictionary for countrycode package to match country names that do not have a corresponding Correlates of War country code.
# Pattern is full name first then corresponding number for COW code, separated by equals sign.

custom.cown <- c("Alaska" = 2,
                 "ALASKA (Including Aleutians and North Pacific Area)" = 2,
                 "Hawaii" = 2,
                 "Hawaiian Islands" = 2,
                 "Caton Island" = 2, # Alaskan Island
                 "Puerto Rico" = 6,
                 "PUERTO RICO" = 6,
                 "Costa Rico" = 94,
                 "Surinam" = 115,
                 "Suriname" = 115,
                 "Surinam (Netherlands Guiana)" = 115,
                 "Columbia" = 100,
                 "Indo-China (Vietnam, Laos, Cambodia)" = 816,
                 "Vietnam" = 816,
                 "Volcano Islands (Iwo Jima)" = 740,
                 "Iwo Jima (Volcano Islands)" = 740,
                 "Volcano Islands (Including Iwo Jima)" = 740,
                 "England (& Wales)" = 200,
                 "Scotland" = 200,
                 "Canal Zone" = 95,
                 "Panama Canal Zone" = 95,
                 "Trieste" = 325,
                 "Serbia" = 345,
                 "SERBIA" = 345,
                 "SERBIA (1992 - 2004)" = 345,
                 "SERBIA (2006 - 2008)" = 345,
                 "Jerusalem" = 666,
                 "Bahrein Island" = 692,
                 "Bahrein" = 692,
                 "French Somaliland" = 520,
                 "Somali Republic" = 520,
                 # Note that this is coded as Eritrea because the actual deployment location appears to be within Eritrean territory. See https://uca.edu/politicalscience/home/research-projects/dadm-project/sub-saharan-africa-region/ethiopia-1942-present/#:~:text=The%20U.S.%20government%20provided%20military,Kagnew%20communications%20station%20in%20Asmara.
                 "Ethiopia and Eritrea" = 531,
                 "Ethiopia (Inc. Eritrea)" = 531,
                 "Ethiopia (Incl Eritrea)" = 531,
                 "Cameroun" = 471,
                 "Tangier" = 600,
                 "Bonin Island" = 740,
                 "Ryukyus (Okinawa)" = 740,
                 "Ryukyu Islands" = 740,
                 "Bonin Islands" = 740,
                 "Hong Kong" = 710,
                 "Hong Kong (& China)" = 710,
                 "China (Includes Hong Kong)" = 710,
                 "Malaya" = 820,
                 "Malaya, States of" = 820,
                 "States of Malaya" = 820,
                 "Caroline Islands" = 987,
                 "Taiwan" = 713,
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
                 "Antigua" = 1006,
                 "Bermuda" = 1007,
                 "Mariana Islands (Including Guam)" = 1008,
                 "Mariana Islands (Guam)" = 1008,
                 "NORTHERN MARIANA ISLANDS" = 1008,
                 "Guam" = 1008,
                 "GUAM" = 1008,
                 "Hong Kong" = 1009,
                 "HONG KONG" = 1009,
                 "Mariana Islands" = 1011,
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
                 "Fiji" = 1028,
                 "Fiji and Tonga" = 1028,
                 "Aden" = 1029,
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
                 "Seychelles" = 1036,
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



# Generate country codes for 1950 to 1953
data.clean.1950.1953 <- data.clean.1950.1953 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
                                                     warn = TRUE),
                      iso3c = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "iso3c",
                                                     warn = TRUE)
                      )
             )

# Check for missing country codes
filtered.1950.1053 <- data.clean.1950.1953 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )


# Generate country codes for 1954 to 1956
data.clean.1954.1956 <- data.clean.1954.1956 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
                                                     warn = TRUE),
                      iso3c = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "iso3c",
                                                     warn = TRUE)
                      )
             )

# Check for missing country codes
filtered.1954.1956 <- data.clean.1954.1956 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )


# Generate country codes for 1957 to 1967
data.clean.1957.1967 <- data.clean.1957.1967 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
                                                     warn = TRUE),
                      iso3c = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "iso3c",
                                                     warn = TRUE)
                      )
             )

# Check for missing country codes
filtered.1957.1967 <- data.clean.1957.1967 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )



# Generate country codes for 1968 to 1976
data.clean.1968.1976 <- data.clean.1968.1976 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
                                                     warn = TRUE),
                      iso3c = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "iso3c",
                                                     warn = TRUE)
                      )
             )

# Check for missing country codes
filtered.1968.1976 <- data.clean.1968.1976 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )


# Generate country codes for 1977 to 2010
# Note that these data overlap with newer DMDC reports, so we'll drop 2009 and 2010 from this sequence and use the newer data for those years.
data.clean.1977.2010 <- data.clean.1977.2010 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
                                                     warn = TRUE),
                      iso3c = countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "iso3c",
                                                     warn = TRUE)
                      )
             )

# Check for missing country codes
filtered.1977.2010 <- data.clean.1977.2010 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )


# Generate country codes for 2008 to 2023
data.clean.September.2008.June.2023 <- data.clean.September.2008.June.2023 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = case_when(
                row_number() > 53 ~ countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
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
filtered.September.2008.June.2023 <- data.clean.September.2008.June.2023 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )

# Generate country codes for September 2023 to December 2023
data.clean.September.2023.December.2023 <- data.clean.September.2023.December.2023 |>
  furrr::future_map(.f = ~ .x |>
               mutate(ccode = case_when(
                row_number() > 54 ~ countrycode::countrycode(sourcevar = Location,
                                                     origin = "country.name",
                                                     destination = "cown",
                                                     custom_match = custom.cown,
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
filtered.September.2023.December.2023 <- data.clean.September.2023.December.2023 |>
  furrr::future_map(.f = ~ .x |>
               filter(is.na(ccode))
             )


