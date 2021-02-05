## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(haven)

troopdata <- haven::read_dta(here::here("../../Projects/Troops/troops 1950-2020.dta")) %>%
  dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps) %>%
  dplyr::filter(year >= 1950)

readr::write_csv(troopdata, "data-raw/troopdata.csv")
usethis::use_data(troopdata, overwrite = TRUE, internal = FALSE)
