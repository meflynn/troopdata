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
  dplyr::rename(troops_ad = troops) %>%
  dplyr::filter(ccode != 2) %>%
  dplyr::select(countryname, ccode, iso3c, year, month, quarter, source, troops_ad)




#### Base Dataframe ####
# Add base country-year data frame using COW country codes for 1950 through the present.
year.position <- as.numeric(length(datalist.2008.Present.names))
current.end.year <- str_extract(datalist.2008.Present.names[[year.position]], pattern = "[0-9]{4}.xlsx")
current.end.year <- 2000 + as.numeric(str_extract(current.end.year, pattern = "^[0-9]{2}"))


# Use Gleditsch and Ward system data
country.year.list <- read_delim(here("../../Data Files/Gleditsch System List/ksgmdw.txt"), delim = "\t") %>%
  dplyr::bind_rows(
    read_delim(here("../../Data Files/Gleditsch System List/microstates.txt"), delim = "\t")
  ) %>%
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

# Now we joint the two data frames and filter out the distinct country year quarter observations
country.year.list <- country.year.list %>%
  bind_rows(country.year.list.supplement) %>%
  distinct(ccode, year, quarter, month) %>%
  arrange(ccode, year, quarter)


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


data.clean.September.2023.Present <- data.clean.September.2023.Present %>%
  furrr::future_map(.f = ~ .x %>%
                      setNames(names.2023.Present) %>%
                      slice(-c(1:5)) %>%
                      filter(!is.na(Location))
  )

# Note that each region has an "afloat" category attached. We'll have to deal with this and treat it as its own country/location.


# Use countrycode package to generate COW country codes for individual countries listed in each list object data frame.

# Generate custom dictionary for countrycode package to match country names that do not have a corresponding Correlates of War country code.
# Pattern is full name first then corresponding number for COW code, separated by equals sign.

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
                "Korea, Republic of", 732,
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
                "NORTHERN MARIANA ISLANDS" = 1008,
                "Guam" = 1008,
                "GUAM" = 1008,
                "Hong Kong" = 1009,
                "HONG KONG" = 1009,
                "Hong Kong (& China)" = 1009,
                "Hong Kong" = 1009, # Note this conflicts with the entry above. Address this below by making values after 1997 go to China.
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
                               ccode == "816" ~ "817",
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
                               ccode == "816" ~ "817",
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
                               ccode == "816" ~ "817",
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
                               ccode == "816" ~ "817",
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
                        row_number() > 54 ~ countrycode::countrycode(sourcevar = Location,
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
  dplyr::mutate(ccode = as.numeric(ccode), # Convert ccode to numeric. It is previously stored as a character vector.
                ccode = case_when(
    grepl(".*Ryukyu.*", Location) ~ 740,
    grepl(".*Hong Kong.*", Location, ignore.case = TRUE) ~ 1009,
    grepl(".*Indo-China.*|.*Viet-Nam.*|.*South Vietnam.*", Location, ignore.case = TRUE) ~ 817,
    TRUE ~ ccode
  )) %>% # Assign Ryukyu Islands to Japan. There's an error where it's cutting out second Japan entry for Ryukyu Islands. Seems to be because there's a footnote containing the word 'Japan' and it's dropping the Ryukyu Islands and keeping that. Also assign Hong Kong its own country code because countrycode is lumping it in with China. Also make sure Indo-China is recoded as Vietnam for 817 south vietnam code.
  dplyr::mutate(troops_ad = as.numeric(troops_ad)) %>% # Make sure combined and data.gaps formats match.
  #bind_rows(data.gaps) %>%
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, everything()) %>%
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
  rowwise() %>%
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),
    !is.na(`Total`) ~ as.numeric(`Total`),
    !is.na(`Total Ashore`) ~ as.numeric(`Total Ashore`),
    #!is.na(troops) ~ as.numeric(troops),
    TRUE ~ as.numeric(`Total Active Duty`)
  ),
  army_ad = case_when(
    !is.na(army_ad) ~ army_ad,
    !is.na(`Army Total`) & is.na(army_ad) ~ as.numeric(`Army Total`),
    TRUE ~ sum(`Army Active Duty`,
               na.rm = TRUE)),
  navy_ad = case_when(
    !is.na(navy_ad) ~ navy_ad,
    !is.na(`Navy Total`) & is.na(navy_ad) ~ as.numeric(`Navy Total`),
    TRUE ~ sum(`Navy Ashore`, `Navy Afloat`, `Navy Temporary Ashore`, `Navy Other`,
               na.rm = TRUE)),
  air_force_ad = case_when(
    !is.na(air_force_ad) ~ air_force_ad,
    !is.na(`Air Force Total`) & is.na(air_force_ad) ~ as.numeric(`Air Force Total`),
    TRUE ~ sum(`Air Force Active Duty`,
               na.rm = TRUE)),
  marine_corps_ad = case_when(
    !is.na(marine_corps_ad) ~ marine_corps_ad,
    !is.na(`Marine Corps Total`) & is.na(marine_corps_ad) ~ as.numeric(`Marine Corps Total`),
    TRUE ~ sum(`Marine Corps Active Duty`, `Marine Corps Ashore`,
               na.rm = TRUE)),
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
  dplyr::select(ccode, countryname, year, month, quarter, everything()) %>%
  group_by(ccode, countryname, year, month, quarter) %>%
  dplyr::filter(troops_ad == max(troops_ad, na.rm = TRUE))



#### Consolidate US Frames ####


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
  dplyr::select(source, Location, ccode, iso3c, year, month, quarter, everything()) %>%
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
  dplyr::mutate(grouping = case_when( # Create grouping variable to identify reports where total is given vs broken out by continental US, Alaska, and Hawaii
    grepl("^UNITED STATES$", Location) ~ "Total Given",
    #!is.na(statenme) ~ "Total Given",
    grepl(".*ontinental.*", Location, ignore.case = TRUE) ~ "Disaggregated",
    grepl(".*laska.*", Location, ignore.case = TRUE) ~ "Disaggregated",
    grepl(".*awaii.*", Location, ignore.case = TRUE) ~ "Disaggregated",
  )) %>%
  dplyr::filter(!grepl(".*territor.*", Location, ignore.case = TRUE)) %>%
  dplyr::mutate(grouping_num = factor(grouping,
                                      levels = c("Disaggregated", "Total Given"))) %>% # Create a factor for ordering
  dplyr::mutate(across(`Total`:`air_force_ad`,
                       ~ str_replace(., ",", ""))) %>%
  dplyr::slice(which.max(grouping_num)) %>%
  select(source, Location, grouping, grouping_num, everything()) %>%
  dplyr::group_by(source, year, month, quarter) %>%
  dplyr::summarise(across(everything(), ~ case_when(
    grouping == "Total Given" ~ max(as.numeric(.), na.rm = TRUE),
    grouping == "Disaggregated" ~ sum(as.numeric(.), na.rm = TRUE)))) %>%
  dplyr::summarize(across(everything(), ~ max(., na.rm = TRUE))) %>%
  dplyr::mutate(source = as.character(source),
                month = as.character(month)) %>%
  dplyr::mutate(across(everything(), ~ case_when(
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>%
  dplyr::mutate(across(`Total`: `air_force_ad`, ~ case_when(
    . == 0 ~ NA,
    TRUE ~ .
  ))) %>%
  rowwise() %>%
  dplyr::mutate(troops_ad = case_when(
    !is.na(troops_ad) ~ as.numeric(troops_ad),
    is.infinite(`Total`) ~ `Total Ashore`,
    year == 1950 ~ `Total Ashore`,
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
# Keep this suffix as 2023 and NOT present because the Space Force data is not included in this pass.
data.clean.combined.us.2008.2023 <- data.table::rbindlist(data.clean.2008.Present[c(1:45)],
                                                          idcol = "source",
                                                          fill = TRUE) %>%
  dplyr::select(1:24) %>% # Only keep the columns that are relevant to the US data
  setNames(c("source", names.2008.2023)) %>%
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
  dplyr::mutate(across(everything(), ~ str_replace(., ",", ""))) %>% # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) %>% # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) %>% # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) %>%
  rowwise() %>%
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) %>%
  group_by(year, month, quarter, source) %>%
  dplyr::select(-c(`Location`, `Macro Location`, fips)) %>%
  dplyr::summarise(across(everything(), ~ sum(., na.rm = TRUE))) %>%
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
  dplyr::mutate(across(everything(), ~ str_replace(., ",", ""))) %>% # Remove commas from numbers
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ str_replace(., "N/A", ""))) %>% # Replace N/A with no value
  dplyr::mutate(across(`Army Active Duty`:`Grand Total`, ~ as.numeric(.))) %>% # Convert all values to numeric
  dplyr::mutate(year = as.numeric(year),
                quarter = as.numeric(quarter)) %>%
  rowwise() %>%
  dplyr::mutate(`Total Active Duty` = sum(`Army Active Duty`, `Navy Active Duty`, `Marine Corps Active Duty`, `Air Force Active Duty`, `Coast Guard Active Duty`, na.rm = TRUE)) %>%
  group_by(year, month, quarter, source) %>%
  dplyr::select(-c(`Location`, `Macro Location`, fips)) %>%
  dplyr::summarise(across(everything(), ~ sum(., na.rm = TRUE))) %>%
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
  dplyr::select(ccode, countryname, year, month, quarter, everything())









#### Build Reports Frame ####

# Combine the US and international data into a single data frame
troopdata_rebuild_reports <- bind_rows(data.clean.combined.international,
                                       data.us.combined.all) %>%
  dplyr::arrange(ccode, countryname, year, month, quarter) %>%
  dplyr::select(ccode, countryname, year, month, quarter, everything(), -c(grouping, grouping_num)) %>%
  dplyr::mutate(across(everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>%
  dplyr::mutate(source = case_when(
    is.na(source) & ccode == 2 ~ "Not Reported", # Fill in missing source values for unreported US data.
    TRUE ~ source
  )) %>%
  dplyr::mutate(region = countrycode(ccode, "gwn", "region"),
                source = case_when(
                  year %in% c(1951:1952) ~ "Stepwise Interpolation",
                  TRUE ~ source
                )) %>%
  dplyr::select(ccode, countryname, region, year, month, quarter, everything(), -fips) %>%
  ungroup() # Remove grouping








#### Build Long Form Frame ####
####
troopdata_rebuild_long <- country.year.list %>%
  full_join(troopdata_rebuild_reports, by = c("ccode", "year", "month", "quarter")) %>%
  dplyr::filter(month == "June" & year %in% c(1950:1956) | # All reports are from June between 1950 and 1956
                  month == "September" & year >= 1957 | # All reports are from September between 1957 and 2012
                  month == "December" & year >= 2013 |
                  month == "June" & year >= 2014 |
                  month == "March" & year >= 2014) %>%
  ungroup() %>%
  janitor::clean_names() %>%
  dplyr::select(ccode, countryname_x, year, month, quarter, source, location, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad, contains("national_guard"), contains("reserve"), contains("civilian")) %>%  # select only variables to be exported to package
  dplyr::rename("countryname" = "countryname_x") %>%
  #dplyr::select(-statenme) %>% Not needed with G&W update
  dplyr::bind_rows(data.gaps) %>%
  dplyr::mutate(iso3c = countrycode(ccode, "gwn", "iso3c")) %>%
  dplyr::mutate(countryname = countrycode(ccode, "gwn", "country.name", custom_match = custom.gwn))  %>%
  dplyr::mutate(countryname = case_when(
    countryname == "United States of America" ~ "United States",
    ccode == 52 ~ "Trinidad and Tobago",
    ccode == 58 ~ "Antigua",
    ccode == 60 ~ "St. Kitts and Nevis",
    ccode == 260 ~ "Germany",
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
    ccode == 572 ~ "Swaziland",               # G&W 572 = Swaziland (was 571, which is Botswana)
    ccode == 591 ~ "Seychelles",              # G&W microstate 591 = Seychelles (was custom 1036)
    ccode == 678 ~ "Yemen",                    # G&W code for Republic of Yemen
    ccode == 680 ~ "Yemen People's Republic",
    ccode == 775 ~ "Myanmar",
    ccode == 731 ~ "North Korea",
    ccode == 732 ~ "South Korea",
    ccode == 775 ~ "Myanmar",
    ccode == 816 ~ "Vietnam",                 # G&W 816 = unified Vietnam (817 = South Vietnam only)
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
    ccode == 1011 ~ "Mariana Islands",
    ccode == 1012 ~ "Midway Islands",
    ccode == 1013 ~ "US Virgin Islands",
    ccode == 1014 ~ "Wake Island",
    ccode == 1015 ~ "Scabo Verde",            # Retain custom code for non-G&W cases
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
    ccode == 10100 ~ "Johnston Island",
    ccode == 10101 ~ "Eniwetok (J.T.F. 7)",
    TRUE ~ countryname
  ),
  ccode = case_when(
    ccode == 1009 & year < 1997 ~ 1009, # Hong Kong before 1997
    ccode == 1009 & year >= 1997 ~ 710, # Hong Kong ceded to China in 1997
    TRUE ~ ccode
  ),
  iso3c = case_when(
    ccode == 1009 & year < 1997 ~ "HKG", # Hong Kong before 1997
    ccode == 1009 & year >= 1997 ~ "CHN", # Hong Kong ceded to China in 1997
    TRUE ~ iso3c
  )
  ) %>% # Fill in missing country names
  dplyr::filter(!(ccode == 817 & year > 1975)) %>%
  dplyr::filter(!is.na(countryname)) %>%
  dplyr::mutate(across(everything(), ~ case_when( # Replace infinite values with NA
    is.infinite(.) ~ NA,
    TRUE ~ .
  ))) %>% # Replace infinite values with NA
  dplyr::mutate(across(everything(), ~ case_when( # 0 values in US with NA
    ccode == 2 & . == 0 ~ NA,
    TRUE ~ .
  ))) %>% # Replace infinite values with NA
  dplyr::group_by(ccode, year, month, quarter) %>%
  dplyr::summarise(across(matches("_ad|civilian|guard|reserve"), ~ sum(., na.rm = TRUE)),
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
  dplyr::select(ccode, iso3c, countryname, year, month, quarter, source, troops_ad, army_ad, navy_ad, air_force_ad, marine_corps_ad, coast_guard_ad, space_force_ad, contains("national_guard"), contains("reserve"), contains("civilian")) %>%  # select only variables to be exported to package
  arrange(ccode, iso3c, year, month, quarter) %>%
  dplyr::group_by(ccode) %>% # Impute missing army values for December 2022 through September 2023
  dplyr::mutate(year_quarter = as.numeric(glue::glue("{year}.{quarter}"))) %>%
  dplyr::mutate(army_ad_sept_2022 = ifelse(year_quarter %in% c(2022.3:2023.3), army_ad[year_quarter==2022.3], NA),
                army_ad_sept_2023 = ifelse(year_quarter %in% c(2022.3:2023.3), army_ad[year_quarter==2023.3], NA),
                army_ad_incremental_difference = round((army_ad_sept_2023 - army_ad_sept_2022) / 5, 0) ) %>%
  dplyr::mutate(army_ad = case_when(
    year_quarter == 2022.4 ~ army_ad_sept_2022 + army_ad_incremental_difference,
    year_quarter == 2023.1 ~ army_ad_sept_2022 + (2 * army_ad_incremental_difference),
    year_quarter == 2023.2 ~ army_ad_sept_2022 + (3 * army_ad_incremental_difference),
    year_quarter == 2023.3 ~ army_ad_sept_2022 + (4 * army_ad_incremental_difference),
    TRUE ~ army_ad
  )) %>%
  dplyr::mutate(army_reserve_sept_2022 = ifelse(year_quarter %in% c(2022.3:2023.3), army_reserve[year_quarter==2022.3], NA),
                army_reserve_sept_2023 = ifelse(year_quarter %in% c(2022.3:2023.3), army_reserve[year_quarter==2023.3], NA),
                army_reserve_incremental_difference = round((army_reserve_sept_2023 - army_reserve_sept_2022) / 5, 0) ) %>%
  dplyr::mutate(army_reserve = case_when(
    year_quarter == 2022.4 ~ army_reserve_sept_2022 + army_reserve_incremental_difference,
    year_quarter == 2023.1 ~ army_reserve_sept_2022 + (2 * army_reserve_incremental_difference),
    year_quarter == 2023.2 ~ army_reserve_sept_2022 + (3 * army_reserve_incremental_difference),
    year_quarter == 2023.3 ~ army_reserve_sept_2022 + (4 * army_reserve_incremental_difference),
    TRUE ~ army_reserve
  )) %>%
  dplyr::mutate(army_national_guard_sept_2022 = ifelse(year_quarter %in% c(2022.3:2023.3), army_national_guard[year_quarter==2022.3], NA),
                army_national_guard_sept_2023 = ifelse(year_quarter %in% c(2022.3:2023.3), army_national_guard[year_quarter==2023.3], NA),
                army_national_guard_incremental_difference = round((army_national_guard_sept_2023 - army_national_guard_sept_2022) / 5, 0) ) %>%
  dplyr::mutate(army_national_guard = case_when(
    year_quarter == 2022.4 ~ army_national_guard_sept_2022 + army_national_guard_incremental_difference,
    year_quarter == 2023.1 ~ army_national_guard_sept_2022 + (2 * army_national_guard_incremental_difference),
    year_quarter == 2023.2 ~ army_national_guard_sept_2022 + (3 * army_national_guard_incremental_difference),
    year_quarter == 2023.3 ~ army_national_guard_sept_2022 + (4 * army_national_guard_incremental_difference),
    TRUE ~ army_national_guard
  )) %>%
  dplyr::select(-c(army_ad_sept_2022, army_ad_sept_2023, army_ad_incremental_difference,
                   army_reserve_sept_2022, army_reserve_sept_2023, army_reserve_incremental_difference,
                   army_national_guard_sept_2022, army_national_guard_sept_2023, army_national_guard_incremental_difference)) %>%
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
                  grepl(".*Ryukyu.*|.*Indo-China.*|.*Hong Kong.*|.*Wake.*|.*Virgin.*|.*Samoa.*|.*Midway.*|.*Marshall.*|.*Mariana.*|.*Johnston.*|.*Guam.*|.*Sarawak.*|.*Line Islands.*|.*Atoll.*|.*Palau.*|.*Tuvalu.*|.*Vanuatu.*|.*Tonga.*|.*Vietnam.*|.*Nauru.*|.*Fiji.*|.*Micronesia.*|.*Eniwetok.*|.*Kiribati.*|.*Leward.*", countryname) ~ "East Asia & Pacific",
                  grepl(".*Antar.*", countryname) ~ "Antarctica",
                  grepl(".*Sahara.*|.*Helena.*|.*Aden.*", countryname) ~ "Middle East & North Africa",
                  grepl(".*Caicos.*|.*Turks Island.*|.*Puerto Rico.*|.*Kitts.*|.*Antilles.*|.*Dominica.*|.*Leeward.*|.*Grenada.*|.*Easter.*|.*Bermuda.*|.*British West.*|.*British Virgin.*|.*Aruba.*|.*Lucia.*|.*Vincent.*|.*Antigua.*", countryname) ~ "Latin America & Caribbean",
                  grepl(".*Kashmir.*|.*Diego.*|.*Seychelles.*", countryname) ~ "South Asia",
                  ccode == 1004 ~ "South Asia",
                  grepl(".*Gibraltar.*|.*Azore.*|.*Monaco.*|.*Gilbral.*|.*Andorra.*|.*Liechtenstein.*|.*Ossetia.*|.*Marino.*|.*Abkhazia.*", countryname) ~ "Europe & Central Asia",
                  ccode == 1001 ~ "Europe & Central Asia", # Gibraltar missing country name
                  grepl(".*Ascension.*|.*Principe.*", countryname) ~ "Sub-Saharan Africa",
                  grepl(".*Greenland.*", countryname) ~ "North America",
                  ccode == 1002 ~ "Europe & Central Asia", # Greenland missing country name
                  TRUE ~ region
                ),
                source = case_when(
                  year %in% c(1951, 1952) ~ "Stepwise Imputation",
                  TRUE ~ source
                )
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
  dplyr::mutate(across(army_national_guard:total_civilian,
                       ~ case_when(
                         is.na(.x) & year >= 2015 ~ 0,
                         TRUE ~ .x
                       )),
                across(coast_guard_ad:coast_guard_reserve,
                       ~ case_when(
                         is.na(.x) & year >= 2008 ~ 0,
                         is.na(.x) & year < 2008 ~ NA
                       )),
                space_force_ad = case_when(
                  is.na(space_force_ad) & year >= 2023 ~ 0,
                  TRUE ~ space_force_ad
                )
                )






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

