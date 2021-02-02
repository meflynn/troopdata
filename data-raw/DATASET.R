## code to prepare `DATASET` dataset goes here

troopdata <- haven::read_dta(here::here("../../Projects/Troops/troops 1950-2020.dta")) %>%
  dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps)

usethis::use_data(troopdata, overwrite = TRUE)




# Import Vine's base data that we updated through the present.

basedata <- readr::read_csv(here::here("../../Projects/Minerva grant documents/Geographic files/Bases.csv")) %>%
  dplyr::select(`Country Name`, `Country code`, `Base Name`, `Latitude`, `Longitude`, base, lilypad, fundedsite) %>%
  dplyr::rename(country = `Country Name`, `ccode` = `Country code`, basename = `Base Name`, lat = `Latitude`, lon = `Longitude`) %>%
  mutate(lon = as.numeric(lon),
         lat = as.numeric(lat))

usethis::use_data(basedata, overwrite = TRUE)
