library(tidyverse)
library(readr)


# Import Vine's base data that we updated through the present.

basedata <- readr::read_csv(here::here("../../Projects/Minerva grant documents/Geographic files/Bases.csv")) %>%
  dplyr::select(`Country Name`, `Country code`, `Base Name`, `Latitude`, `Longitude`, base, lilypad, fundedsite) %>%
  dplyr::rename(countryname = `Country Name`, `ccode` = `Country code`, basename = `Base Name`, lat = `Latitude`, lon = `Longitude`) %>%
  dplyr::mutate(lon = as.numeric(lon),
                lat = as.numeric(lat),
                iso3c = countrycode::countrycode(ccode, "cown", "iso3c",
                                                 custom_match = c("347" = "KSV"))) %>%
  dplyr::select(countryname, ccode, iso3c, basename, lat, lon, base, lilypad, fundedsite)

readr::write_csv(basedata, "data-raw/basedata.csv")
usethis::use_data(basedata, overwrite = TRUE, internal = FALSE)
