## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(data.table)
library(haven)
library(here)

temp <- setDT(readxl::read_xls(here("../../Projects/Troop Data/Data Files/M05 Military Only/hst0650.xls")))

names(temp) <- c("countryname", "dod_total", "dod_shore", "dod_afloat", "army_ashore", "army_shore", "navy_shore", "navy_shore", "marines_shore", "marines_afloat", "airforce_shore")

temp <- temp[
  !is.na(countryname)
]



troopdata.2021 <- fread(here::here("../../Projects/Troops/data/", "troops-1950-2021.txt"), fill = TRUE) |>
  dplyr::filter(year == 2021)

troopdata.2022.2023 <- fread(here::here("../../Projects/Troop Data/Data Files/troops_2022_2023.csv")) |>
  dplyr::rename("troops" = "total") |>
  dplyr::rename("countryname" = "country")


troopdata <- haven::read_dta(here::here("../../Projects/Troops/data/", "troops 1950-2020.dta")) |>
  dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps) |>
  dplyr::filter(year >= 1950) |>
  mutate(countryname = countrycode::countrycode(ccode, "cown", "country.name"),
         countryname = case_when(
           ccode == 260 ~ "West Germany",
           ccode == 6 ~ "Puerto Rico",
           ccode == 713 ~ "Taiwan",
           ccode == 315 ~ "Czechoslovakia",
           ccode == 816 ~ "Vietnam",
           ccode == 1001 ~ "Gibraltar",
           ccode == 1002 ~ "Greenland",
           ccode == 1003 ~ "Afloat",
           ccode == 1004 ~ "Diego Garcia",
           ccode == 1005 ~ "St. Helena",
           ccode == 1006 ~ "Antigua",
           ccode == 1007 ~ "Bermuda",
           ccode == 1007 ~ "American Samoa",
           ccode == 1008 ~ "Guam",
           ccode == 1009 ~ "Hong Kong",
           ccode == 1010 ~ "Montenegro",
           ccode == 1011 ~ "Northern Mariana Islands",
           ccode == 1012 ~ "Taiwan",
           ccode == 1013 ~ "U.S. Virgin Islands",
           ccode == 1014 ~ "Wake Island",
           ccode == 1015 ~ "Scabo Verde",
           ccode == 1016 ~ "Netherlands Antilles",
           ccode == 1017 ~ "Spratly Islands",
           ccode == 1018 ~ "Trucial States",
           ccode == 1019 ~ "Aruba",
           ccode == 1020 ~ "South Sudan",
           ccode == 1021 ~ "Akrotiri",
           ccode == 1022 ~ "Coral Sea Islands",
           ccode == 1023 ~ "Svalbard",
           ccode == 1024 ~ "Bassas da India",
           ccode == 1025 ~ "Curacao",
           ccode == 1026 ~ "Martinique",
           ccode == 1027 ~ "Sint Maarten",
           ccode == 1028 ~ "Fiji and Tonga",
           ccode == 1029 ~ "Aden",
           ccode == 1030 ~ "Line Islands",
           ccode == 1031 ~ "Easter Island",
           ccode == 1032 ~ "British West Indies Federation",
           ccode == 1033 ~ "Sarawak",
           ccode == 1034 ~ "Western Sahara",
           ccode == 1035 ~ "British Virgin Islands",
           ccode == 1036 ~ "Easter Island",
           ccode == 1037 ~ "Seychelles Island",
           ccode == 1038 ~ "Turks Island",
           ccode == 1039 ~ "Kashmir",
           ccode == 1099 ~ "UNKNOWN",
           TRUE ~ countryname),
         troops = case_when(
           ccode == 200 & year == 2014 ~ 8495,
           ccode == 700 & year == 2020 ~ 8600, # Afghanistan update from just security
           ccode == 700 & year == 2019 ~ 13000, # Afghanistan update
           ccode == 652 & year == 2018 ~ 1700, # Syria update from just security
           ccode == 652 & year == 2019 ~ 1000,
           ccode == 652 & year == 2020 ~ 900,
           ccode == 645 & year == 2006 ~ 141100, # FAS update for Iraq
           ccode == 645 & year == 2007 ~ 170000, # Reuters update for Iraq
           ccode == 690 & year == 2006 ~ 44400, # Reverse engineered from OIF totals
           ccode == 690 & year == 2007 ~ 48500, # Reverse engineered from OIF totals
           TRUE ~ troops),
         army = case_when(ccode == 200 & year == 2014 ~ 216,
                          TRUE ~ army),
         navy = case_when(ccode == 200 & year == 2014 ~ 300,
                          TRUE ~ navy),
         air_force = case_when(ccode == 200 & year == 2014 ~ 7938,
                               TRUE ~ air_force),
         marine_corps = case_when(ccode == 200 & year == 2014 ~ 40,
                                  TRUE ~ marine_corps),
         iso3c = countrycode::countrycode(countryname, "country.name", "iso3c")) |>
  dplyr::select(countryname, ccode, iso3c, year, troops, army, navy, air_force, marine_corps)


south.vietnam <- troopdata |>
  filter(ccode == 816 & year %in% c(1954:1975)) |>
  mutate(ccode = 817,
         countryname = "Republic of Vietnam",
         iso3c = NA)

troopdata <- troopdata |>
  mutate(troops = case_when(
    ccode == 816 & year %in% c(1954:1975) ~ 0,
    TRUE ~ troops
  )) |>
  filter(!(ccode == 817 & year <= 1975)) |>
  bind_rows(south.vietnam) |>
  arrange(ccode, year) |>
  mutate(across(c(army, navy, marine_corps, air_force), ~ ifelse(ccode == 645 & year %in% c(2006, 2007), NA, .)),
         across(c(army, navy, marine_corps, air_force), ~ ifelse(year < 2006, NA, .)),
         region = countrycode::countrycode(iso3c, "iso3c", "region"),
         region = case_when(
           countryname == "German Democratic Republic" ~ "Europe & Central Asia",
           countryname == "Czechoslovakia" ~ "Europe & Central Asia",
           countryname == "Yugoslavia" ~ "Europe & Central Asia",
           countryname == "Kosovo" ~ "Europe & Central Asia",
           countryname == "Zanzibar" ~ "Sub-Saharan Africa",
           countryname == "Yemen Arab Republic" ~ "Middle East & North Africa",
           countryname == "Yemen People's Republic" ~ "Middle East & North Africa",
           countryname == "Republic of Vietnam" ~ "East Asia & Pacific",
           countryname == "Diego Garcia" ~ "South Asia",
           countryname == "Kashmir" ~ "South Asia",
           countryname == "Easter Island" ~ "East Asia & Pacific",
           countryname == "Western Sahara" ~ "East Asia & Pacific",
           countryname == "Sarawak" ~ "East Asia & Pacific",
           countryname == "British West Indies Federation" ~ "Latin America & Caribbean",
           countryname == "Line Islands" ~ "East Asia & Pacific",
           countryname == "Aden" ~ "Middle East & North Africa",
           countryname == "Fiji and Tonga" ~ "East Asia & Pacific",
           countryname == "Svalbard" ~ "Europe & Central Asia",
           countryname == "Coral Sea Islands" ~ "East Asia & Pacific",
           countryname == "Akrotiri" ~ "Europe & Central Asia",
           countryname == "Spratly Islands" ~ "East Asia & Pacific",
           countryname == "Netherlands Antilles" ~ "Latin America & Caribbean",
           countryname == "Wake Island" ~ "East Asia & Pacific",
           countryname == "St. Helena" ~ "Sub-Saharan Africa",
           countryname == "Afloat" ~ "Afloat",
           TRUE ~ region
           ))

troopdata <- bind_rows(troopdata, troopdata.2021) |>
  arrange(ccode, year)

# This is probably the last time we're going to use this workflow to update the data so I'm just using this line to overwrite
# using Michael Allen's most recent csv file. Subsequent versions will use a totally new build structure.
troopdata <- data.table::fread("https://raw.githubusercontent.com/Michael-A-Allen/troopdata/master/data-raw/troopdata.csv") |>
  mutate(countryname = case_when(
    ccode == 403 ~ "Sao Tome and Principe",
    ccode == 437 ~ "Cote d'Ivoire",
    TRUE ~ countryname
  )) |>
  bind_rows(troopdata.2022.2023) |>
  arrange(ccode, year)


readr::write_csv(troopdata, "data-raw/troopdata.csv")
usethis::use_data(troopdata, overwrite = TRUE, internal = FALSE)
