## code to prepare `DATASET` dataset goes here

troopdata <- readstata13::read.dta13(here::here("data-raw/troops 1950-2020.dta")) %>%
  dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps)

usethis::use_data(troopdata, overwrite = TRUE)
