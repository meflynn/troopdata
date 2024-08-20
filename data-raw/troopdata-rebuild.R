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


# Read in PDF file path for 2003 data and extract relevant information.
datalist.2003.names <- here::here("../../Projects/Troop Data/Data Files/M05 Military Only/m05sep03.pdf")

# Read in PDF file path for 2004 data and extract relevant information.
datalist.2004.names <- here::here("../../Projects/Troop Data/Data Files/M05 Military Only/m05sep04.pdf")




# Add previously cleaned data for 1951, 1952, 2003, and 2004.
# # Also use back values for Iraq and Afghanistan to fill in missing time periods not reported in DoD reports.
# Filter only relevant years
data.gaps <- read_csv(here("../../Projects/Troop Data/Data Files/troopdata_1950_2021.csv")) |>
  janitor::clean_names() |>
  janitor::remove_empty("rows") |>
  janitor::remove_empty("cols") |>
  dplyr::filter(year %in% c(1951, 1952) |
                  ccode %in% c(645, 700)) |>
  dplyr::mutate(ccode = ifelse(ccode == 260, 255, ccode),
                statenme = countrycode::countrycode(sourcevar = ccode,
                                                   origin = "cown",
                                                   destination = "country.name",
                                                   warn = TRUE),
                iso3c = countrycode::countrycode(sourcevar = ccode,
                                                   origin = "cown",
                                                   destination = "iso3c",
                                                   warn = TRUE),
                quarter = 2,
                month =  "June",
                source = "Kane 2006"
                ) |>
  dplyr::rename(troops_ad = troops) |>
  dplyr::filter(ccode != 2) |>
  dplyr::select(statenme, ccode, iso3c, year, month, quarter, source, troops_ad)


#### Base Dataframe ####
# Add base country-year data frame using COW country codes for 1950 through the present.
year.position <- as.numeric(length(datalist.2008.2023.names))
current.end.year <- str_extract(datalist.2008.2023.names[[year.position]], pattern = "[0-9]{4}.xlsx")
current.end.year <- 2000 + as.numeric(str_extract(current.end.year, pattern = "^[0-9]{2}"))


country.year.list <- read_csv(here("../../Data Files/COW Data/System/states2016.csv")) |>
  rowwise() |> # Rowwise operation to create a list of years for each country.
  dplyr::mutate(endyear = case_when(
    endyear == 2016 ~ current.end.year,
    TRUE ~ endyear
  ),
  ccode = case_when(
    ccode == 260 ~ 255,
    TRUE ~ ccode
  ),
  year = list(seq(styear, endyear))
  ) |>
  unnest(year) |> # Expand to full country-year data frame
  dplyr::filter(year >= 1950) |># Only keep values from 1950 forward
  dplyr::select(ccode, statenme, year) |>
  dplyr::group_by(ccode, statenme, year) |>
  tidyr::expand(month = c("March", "June", "September", "December")) |>
  dplyr::mutate(quarter = case_when(
    month == "March" ~ 1,
    month == "June" ~ 2,
    month == "September" ~ 3,
    month == "December" ~ 4
    )
    ) |>
  dplyr::filter(!(statenme == "German Federal Republic" & year == 1990)) # Remove duplicate Germany observation for 1990


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
data.clean.September.2023.December.2023 <- data.clean.2008.2023[c(46:48)]


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
               slice(-c(1:2)) |>
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
                 "Antigua" = 1006,
                 "Bermuda" = 1007,
                 "Mariana Islands (Including Guam)" = 1008,
                 "Mariana Islands (Guam)" = 1008,
                 "NORTHERN MARIANA ISLANDS" = 1008,
                 "Guam" = 1008,
                 "GUAM" = 1008,
                 "Mariana Islands (Guam)" = 1008,
                 "Hong Kong" = 1009,
                 "HONG KONG" = 1009,
                 "Hong Kong (& China)" = 1009,
                 "Mariana Islands" = 1011,
                 "Marshall Islands (Kwajelein)" = 1011,
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
                                                     warn = TRUE),
                      ccode = case_when(
                        ccode == 816 ~ 817,
                        TRUE ~ ccode
                      )
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
                                                     warn = TRUE),
                      ccode = case_when(
                        ccode == 816 ~ 817,
                        TRUE ~ ccode
                      )
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
                                                     warn = TRUE),
                      ccode = case_when(
                        ccode == 816 ~ 817,
                        TRUE ~ ccode
                      )
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
                                                     warn = TRUE),
                      ccode = case_when(
                        ccode == 816 ~ 817,
                        TRUE ~ ccode
                      )
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

# Remove last two elements from this list as they overlap with the newer data.
# Drop 2009 and 2010 from this list.

data.clean.1977.2010 <- data.clean.1977.2010[c(1:30)]

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


# Basic cleaning and organization of 2003 data
data.clean.2003 <- pdftools::pdf_text(datalist.2003.names) |>
  stringr::str_split(pattern = "\n") |>
  unlist() |>
  stringr::str_trim() |>
  as.data.frame() |>
  dplyr::slice(548:908) |>
  tidyr::separate(col = 1,
                  into = c("Location", "troops_ad", "army_ad", "navy_ad", "marine_corps_ad", "air_force_ad"),
                  sep = " {2,}") |>
  dplyr::filter(Location != "") |> # Remove empty rows
  dplyr::mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "cown",
                                                 custom_match = custom.cown),
                iso3c = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "iso3c",
                                                 warn = TRUE)
                )



# Basic cleaning and organization of 2004 data
data.clean.2004 <- pdftools::pdf_text(datalist.2004.names) |>
  stringr::str_split(pattern = "\n") |>
  unlist() |>
  stringr::str_trim() |>
  as.data.frame() |>
  dplyr::slice(555:927) |>
  tidyr::separate(col = 1,
                  into = c("Location", "troops_ad", "army_ad", "navy_ad", "marine_corps_ad", "air_force_ad"),
                  sep = " {2,}") |>
  dplyr::filter(Location != "") |> # Remove empty rows
  dplyr::mutate(ccode = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "cown",
                                                 custom_match = custom.cown),
                iso3c = countrycode::countrycode(sourcevar = Location,
                                                 origin = "country.name",
                                                 destination = "iso3c",
                                                 warn = TRUE)
                )


# Combine 2003 and 2004 data into a single list object.

data.clean.2003.2004 <- list("September 2003" = data.clean.2003,
                             "September 2004" = data.clean.2004)



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
                                                   data.clean.September.2023.December.2023),
                                         .f = ~ data.table::rbindlist(.x, fill = TRUE, idcol = "source")) |>
  dplyr::bind_rows() |>
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
                ) |>
  dplyr::mutate(ccode = case_when(
    grepl(".*Ryukyu.*", Location) ~ 740,
    grepl(".*Hong Kong.*", Location, ignore.case = TRUE) ~ 1009,
    grepl(".*Indo-China.*", Location, ignore.case = TRUE) ~ 817,
    TRUE ~ ccode
  )) |> # Assign Ryukyu Islands to Japan. There's an error where it's cutting out second Japan entry for Ryukyu Islands. Seems to be because there's a footnote containing the word 'Japan' and it's dropping the Ryukyu Islands and keeping that. Also asign Hong Kong its own country code because countrycode is lumping it in with China. Also make sure Indo-China is recoded as Vietnam.
  #bind_rows(data.gaps) |>
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, everything()) |>
  dplyr::arrange(ccode, year, month, quarter) |>
  dplyr::filter(case_when(
    year <= 1956 ~ month == "June",
    year >= 1957 & year <= 1976 ~ month == "September",
    year >= 1977 & year <= 2013 ~ month == "September",
    TRUE ~ TRUE
  )) |>
  dplyr::filter(ccode != 2) |> # Remove US and total US values separately
  dplyr::mutate(across(`Total`:`Space Force Active Duty`,
                       ~ str_replace_all(., pattern = ",", replacement = ""))) |> # Remove commas from numbers
  dplyr::mutate(across(quarter:`Space Force Active Duty`, ~ case_when(
    . == "N/A" ~ NA,
    TRUE ~ as.numeric(.)  # Convert all values to numeric
    )
    ),
    `Navy Other` = abs(`Navy Other`)) |>
  rowwise() |>
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),
    !is.na(`Total`) ~ as.numeric(`Total`),
    !is.na(`Total Ashore`) ~ as.numeric(`Total Ashore`),
    #!is.na(troops) ~ as.numeric(troops),
    TRUE ~ as.numeric(`Total Active Duty`) + as.numeric(`Total Selected Reserve`)
  ),
  army_ad = case_when(
    !is.na(`Army Total`) & is.na(army_ad) ~ as.numeric(`Army Total`),
    TRUE ~ sum(`Army Active Duty`, `Army National Guard`, `Army Reserve`,
               na.rm = TRUE)),
  navy_ad = case_when(
    !is.na(`Navy Total`) & is.na(navy_ad) ~ as.numeric(`Navy Total`),
    TRUE ~ sum(`Navy Ashore`, `Navy Afloat`, `Navy Temporary Ashore`, `Navy Other`, `Navy Reserve`,
               na.rm = TRUE)),
  air_force_ad = case_when(
    !is.na(`Air Force Total`) & is.na(air_force_ad) ~ as.numeric(`Air Force Total`),
    TRUE ~ sum(`Air Force Active Duty`, `Air National Guard`, `Air Force Reserve`,
               na.rm = TRUE)),
  marine_corps_ad = case_when(
    !is.na(`Marine Corps Total`) & is.na(marine_corps_ad) ~ as.numeric(`Marine Corps Total`),
    TRUE ~ sum(`Marine Corps Active Duty`, `Marine Corps Reserve`, `Marine Corps Afloat`, `Marine Corps Ashore`,
               na.rm = TRUE)),
  coast_guard_ad = sum(`Coast Guard Active Duty`, `Coast Guard Reserve`,
               na.rm = TRUE),
  space_force_ad = sum(`Space Force Active Duty`,
               na.rm = TRUE)
  ) |>
  mutate(countryname = countrycode::countrycode(ccode, "cown", "country.name"),
         countryname = case_when(
           is.na(countryname) ~ Location,
           TRUE ~ countryname
         ),
         countryname = str_to_title(countryname),
         countryname = case_when(
           grepl(".*Antar.*", countryname) ~ "Antarctica",
           TRUE ~ countryname
         ),
         source = case_when(
           year %in% c(1951, 1952, 2003, 2004) ~ "Kane 2006",
           TRUE ~ source
         )) |>
  dplyr::arrange(ccode, countryname, year, month, quarter) |>
  dplyr::select(ccode, countryname, year, month, quarter, everything())


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
                                                                                    idcol = "source")) |>
  dplyr::bind_rows() |>
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) |>
  #bind_rows(data.gaps) |>
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, everything()) |>
  dplyr::arrange(ccode, year, month, quarter) |>
  dplyr::filter(case_when( # Filter out the quarters that are not used in the data
    year <= 1956 ~ month == "June",
    year >= 1957 & year <= 1976 ~ month == "September",
    year >= 1977 & year <= 2013 ~ month == "September",
    TRUE ~ TRUE
  )) |>
  dplyr::filter(ccode == 2) |> # Only keep US data
  #dplyr::filter(!is.na(`Total`)) |> # Remove rows with no data for the Total column
  dplyr::filter(year < 2008) |> # Remove 2008 since that will be aggregated separately.
  dplyr::group_by(year, month, quarter) |> # Group by year, month, and quarter
  dplyr::mutate(grouping = case_when( # Create grouping variable to identify reports where total is given vs broken out by continental US, Alaska, and Hawaii
    grepl("^UNITED STATES$", Location) ~ "Total Given",
    #!is.na(statenme) ~ "Total Given",
    grepl(".*ontinental.*", Location, ignore.case = TRUE) ~ "Disaggregated",
    grepl(".*laska.*", Location, ignore.case = TRUE) ~ "Disaggregated",
    grepl(".*awaii.*", Location, ignore.case = TRUE) ~ "Disaggregated",
  )) |>
  dplyr::filter(!grepl(".*territor.*", Location, ignore.case = TRUE)) |>
  dplyr::mutate(grouping_num = factor(grouping,
                                      levels = c("Disaggregated", "Total Given"))) |> # Create a factor for ordering
  dplyr::mutate(across(`Total`:`air_force_ad`,
                       ~ str_replace(., ",", ""))) |>
  dplyr::slice(which.max(grouping_num)) |>
  select(source, Location, grouping, grouping_num, everything()) |>
  dplyr::group_by(source, year, month, quarter) |>
  dplyr::summarise(across(everything(), ~ case_when(
    grouping == "Total Given" ~ max(as.numeric(.), na.rm = TRUE),
    grouping == "Disaggregated" ~ sum(as.numeric(.), na.rm = TRUE)))) |>
  dplyr::summarize(across(everything(), ~ max(., na.rm = TRUE))) |>
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) |>
  dplyr::mutate(across(everything(), ~ case_when(
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) |>
  dplyr::mutate(across(`Total`: `air_force_ad`, ~ case_when(
    . == 0 ~ NA,
    TRUE ~ .
  ))) |>
  rowwise() |>
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),
    is.infinite(`Total`) ~ `Total Ashore`,
    TRUE ~ `Total`
  ),
  army_ad = case_when(
    !is.na(army_ad) ~ army_ad,
    TRUE ~ `Army Total`
    ),
  navy_ad = case_when(
    !is.na(navy_ad) ~ navy_ad,
    !is.na(`Navy Total`) ~ `Navy Total`,
    TRUE ~ sum(`Navy Ashore`, `Navy Temporary Ashore`, `Navy Other`, na.rm = TRUE)
    ),
  air_force_ad = case_when(
    !is.na(air_force_ad) ~ air_force_ad,
    TRUE ~ `Air Force Total`
    ),
  marine_corps_ad = case_when(
    !is.na(marine_corps_ad) ~ marine_corps_ad,
    `Marine Corps Ashore` > 0 ~ `Marine Corps Ashore`,
    TRUE ~ `Marine Corps Total`)
  )


# Repeat the basic procedure from the previous code chunk but extract the US states
# and generate aggregate US totals using these data.
# This first pass covers the pre-Space Force deployment figures.
data.clean.combined.us.2008.2023 <- data.table::rbindlist(data.clean.2008.2023[c(1:45)],
                                                          idcol = "source",
                                                          fill = TRUE) |>
  dplyr::select(1:24) |> # Only keep the columns that are relevant to the US data
  setNames(c("source", names.2008.2023)) |>
  dplyr::mutate(fips = usmap::fips(Location)) |> # Generate FIPS codes for US states
  dplyr::filter(!is.na(fips)) |>
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) |>
  dplyr::mutate(across(everything(), ~ str_replace(., ",", ""))) |> # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) |> # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) |> # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) |>
  rowwise() |>
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) |>
  group_by(year, month, quarter, source) |>
  dplyr::select(-c(`Location`, `Macro Location`, fips)) |>
  dplyr::summarise(across(everything(), ~ sum(., na.rm = TRUE))) |>
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) |>
  rowwise() |>
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
data.clean.combined.us.2023.2024 <- data.table::rbindlist(data.clean.2008.2023[c(46:48)], # Select only recent data frames with space force
                                                          idcol = "source",
                                                          fill = TRUE) |>
  dplyr::select(1:25) |> # Only keep the columns that are relevant to the US data
  setNames(c("source", names.2023.2024)) |>
  dplyr::mutate(fips = usmap::fips(Location)) |> # Generate FIPS codes for US states
  dplyr::filter(!is.na(fips)) |>
  dplyr::mutate(year = as.numeric(str_extract(source, pattern = "[0-9]{4}")),
                month = str_extract(source, pattern = "[A-Za-z]+"),
                quarter = case_when(
                  month == "March" ~ 1,
                  month == "June" ~ 2,
                  month == "September" ~ 3,
                  month == "December" ~ 4
                )
  ) |>
  dplyr::mutate(across(everything(), ~ str_replace(., ",", ""))) |> # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) |> # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) |> # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) |>
  rowwise() |>
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) |>
  group_by(year, month, quarter, source) |>
  dplyr::select(-c(`Location`, `Macro Location`, fips)) |>
  dplyr::summarise(across(everything(), ~ sum(., na.rm = TRUE))) |>
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) |>
  rowwise() |>
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
                                  data.clean.combined.us.2023.2024) |>
  dplyr::mutate(countryname = "United States",
                ccode = 2,
                iso3c = "USA",
                Location = "United States",
                troops_ad = case_when(
                  year %in% c(1951, 1952) ~ NA,
                  TRUE ~ troops_ad
                )) |>
  dplyr::select(ccode, countryname, year, month, quarter, everything())


# Combine the US and international data into a single data frame
troopdata_rebuild_reports <- bind_rows(data.clean.combined.international,
                                     data.us.combined.all) |>
  dplyr::arrange(ccode, countryname, year, month, quarter) |>
  dplyr::select(ccode, countryname, year, month, quarter, everything(), -c(grouping, grouping_num)) |>
  dplyr::mutate(across(everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) |>
  dplyr::mutate(source = case_when(
    is.na(source) & ccode == 2 ~ "Not Reported", # Fill in missing source values for unreported US data.
    TRUE ~ source
  )) |>
  dplyr::mutate(region = countrycode(ccode, "cown", "region")) |>
  dplyr::select(ccode, countryname, region, year, month, quarter, everything(), -fips) |>
  ungroup() # Remove grouping




troopdata_rebuild_long <- country.year.list |>
  full_join(troopdata_rebuild_reports, by = c("ccode", "year", "month", "quarter")) |>
  dplyr::filter(month == "June" & year %in% c(1950:1956) | # All reports are from June between 1950 and 1956
                  month == "September" & year >= 1957 | # All reports are from September between 1957 and 2012
                  month == "December" & year >= 2013 |
                  month == "June" & year >= 2014 |
                  month == "March" & year >= 2014) |>
  dplyr::mutate(countryname = case_when(
    is.na(countryname) ~ statenme,
    TRUE ~ countryname
  )) |>
  ungroup() |>
  janitor::clean_names() |>
  dplyr::select(ccode, countryname, year, month, quarter, source, location, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad, contains("national_guard"), contains("reserve"), contains("civilian")) |>  # select only variables to be exported to package
  dplyr::mutate(troops_ad = case_when( # Add values from reports to fill in missing data for Iraq and Afghanistan
      ccode == 200 & year == 2014 ~ 8495,
      ccode == 700 & year == 2020 ~ 8600, # Afghanistan update from just security
      ccode == 700 & year == 2019 ~ 13000, # Afghanistan update
      ccode == 652 & year == 2018 ~ 1700, # Syria update from just security
      ccode == 652 & year == 2019 ~ 1000,
      ccode == 652 & year == 2020 ~ 900,
      ccode == 645 & year == 2006 & !is.na(troops_ad) ~ 141100, # FAS update for Iraq
      ccode == 645 & year == 2007 & !is.na(troops_ad) ~ 170000, # Reuters update for Iraq
      ccode == 690 & year == 2006 ~ 44400, # Reverse engineered from OIF totals
      ccode == 690 & year == 2007 ~ 48500, # Reverse engineered from OIF totals
      TRUE ~ troops_ad)
  ) |>
  plyr::rbind.fill(data.gaps) |>
  dplyr::select(-statenme) |>
  dplyr::mutate(iso3c = countrycode(ccode, "cown", "iso3c")) |>
  dplyr::mutate(countryname = case_when(
    is.na(countryname) ~ countrycode(ccode, "cown", "country.name"),
    TRUE ~ countryname),
    countryname = case_when(
      countryname == "United States of America" ~ "United States", # Help standardize country names.
      grepl(".*Hong Kong.*", countryname, ignore.case = TRUE) ~ "Hong Kong",
      ccode == 1001 ~ "Gibraltar",
      ccode == 1002 ~ "Greenland",
      ccode == 1004 ~ "Diego Garcia",
      ccode == 1009 ~ "Hong Kong",
      ccode == 817 ~ "Vietnam",
      ccode == 1005 ~ "St. Helena",
      ccode == 1006 ~ "Antigua",
      ccode == 1007 ~ "Bermuda",
      ccode == 1008 ~ "Guam",
      ccode == 1011 ~ "Mariana Islands",
      ccode == 1012 ~ "Midway Islands",
      ccode == 1013 ~ "US Virgin Islands",
      ccode == 1014 ~ "Wake Island",
      ccode == 1015 ~ "Scabo Verde",
      ccode == 1016 ~ "Netherlands Antilles",
      ccode == 1017 ~ "Spraatly Islands",
      ccode == 1018 ~ "Trucial States",
      ccode == 1019 ~ "Aruba",
      ccode == 1021 ~ "Akrotiri",
      ccode == 1022 ~ "Coral Sea Islands",
      ccode == 1023 ~ "Svalbard",
      ccode == 1024 ~ "Bassas Da India",
      ccode == 1025 ~ "Curacao",
      ccode == 1026 ~ "Martinique",
      ccode == 1027 ~ "Sint Maarten",
      ccode == 1028 ~ "Fiji and Tonga",
      ccode == 1029 ~ "Aden",
      ccode == 1030 ~ "Line Islands",
      ccode == 1031 ~ "Easter Island",
      ccode == 1032 ~ "British West Indies",
      ccode == 1033 ~ "Sarawak",
      ccode == 1034 ~ "Western Sahara",
      ccode == 1035 ~ "British Virgin Islands",
      ccode == 1036 ~ "Seychelles",
      ccode == 1037 ~ "Turks and Caicos Islands",
      ccode == 1038 ~ "Kashmir",
      ccode == 1040 ~ "Azores",
      ccode == 1041 ~ "American Samoa",
      ccode == 1042 ~ "Ascension Island",
      ccode == 10000 ~ "Antarctica",
      ccode == 10100 ~ "Johnston Island",
      ccode == 10101 ~ "Eniwetok (J.T.F. 7",
      TRUE ~ countryname
    ),
    region = countrycode(ccode, "cown", "region"),
    region = case_when(
      grepl(".*Ryukyu.*|.*Indo-China.*|.*Hong Kong.*|.*Wake.*|.*Virgin.*|.*Samoa.*|.*Midway.*|.*Marshall.*|.*Mariana.*|.*Johnston.*|.*Guam.*|.*Sarawak.*|.*Line Islands.*|.*Atoll.*|.*Fiji.*|.*Eniwetok.*|.*Leward.*", countryname) ~ "East Asia & Pacific",
      grepl(".*Antar.*", countryname) ~ "Antarctica",
      grepl(".*Sahara.*|.*Helena.*|.*Aden.*", countryname) ~ "Middle East & North Africa",
      grepl(".*Caicos.*|.*Turks Island.*|.*Puerto Rico.*|.*Antilles.*|.*Leeward.*|.*Easter.*|.*Bermuda.*|.*British West.*|.*British Virgin.*|.*Aruba.*|.*Antigua.*", countryname) ~ "Latin America & Caribbean",
      grepl(".*Kashmir.*|.*Diego.*|.*Seychelles.*", countryname) ~ "South Asia",
      ccode == 1004 ~ "South Asia",
      grepl(".*Gibraltar.*|.*Azore.*|.*Gilbral.*", countryname) ~ "Europe & Central Asia",
      ccode == 1001 ~ "Europe & Central Asia", # Gibraltar missing country name
      grepl(".*Ascension.*", countryname) ~ "Sub-Saharan Africa",
      grepl(".*Greenland.*", countryname) ~ "North America",
      ccode == 1002 ~ "Europe & Central Asia", # Greenland missing country name
      TRUE ~ region
    )
  ) |> # Fill in missing country names
  dplyr::filter(!(ccode == 817 & year > 1975)) |>
  dplyr::filter(!is.na(countryname)) |>
  dplyr::mutate(across(everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) |> # Replace infinite values with NA
  dplyr::mutate(across(everything(), ~ case_when( # 0 values in US with NA
    ccode == 2 & . == 0 ~ NA,
    TRUE ~ .
  ))) |> # Replace infinite values with NA
  dplyr::group_by(ccode, year, month, quarter) |>
  dplyr::summarise(across(matches("_ad|civilian|guard|reserve"), ~ sum(., na.rm = TRUE)),
                   countryname = first(countryname),
                   iso3c = first(iso3c),
                   region = first(region),
                   source = first(source)) |>
  dplyr::select(ccode, iso3c, countryname, region, year, month, quarter, source, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad, contains("national_guard"), contains("reserve"), contains("civilian")) |>  # select only variables to be exported to package
  arrange(ccode, iso3c, year, month, quarter) |>
  ungroup()




# Export reports to csv
readr::write_csv(troopdata_rebuild_reports,
                 here::here("data-raw/troopdata-rebuild-reports.csv"))


# Export full country year quarter list data
readr::write_csv(troopdata_rebuild_long,
                 here::here("data-raw/troopdata-rebuild-country-year-quarter-format.csv"))

usethis::use_data(troopdata_rebuild_long,
                  troopdata_rebuild_reports,
                  overwrite = TRUE,
                  internal = FALSE)

