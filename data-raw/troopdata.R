## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(haven)

troopdata <- haven::read_dta(here::here("../../Projects/Troops/troops 1950-2020.dta")) %>%
  dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps) %>%
  dplyr::filter(year >= 1950) %>%
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
         iso3c = countrycode::countrycode(countryname, "country.name", "iso3c")) %>%
  dplyr::select(countryname, ccode, iso3c, year, troops, army, navy, air_force, marine_corps)

readr::write_csv(troopdata, "data-raw/troopdata.csv")
usethis::use_data(troopdata, overwrite = TRUE, internal = FALSE)
