
# Check values for Europe and Latin America for 2008 through 2010 compared to previous versions
library(tidyverse)

comparison.version <- "0.1.4"
comparison.years <- 2000:2007
comparison.regions <- c("Europe & Central Asia", "Latin America")


install.packages("troopdata")
library(troopdata)

test.current <- troopdata::get_troopdata()

# Now download and install a previous version of troopdata and locate the values for the same regions and years
remotes::install_version("troopdata",
                         version = comparison.version,
                         repos = "http://cran.us.r-project.org")
library(troopdata)

test.old <- troopdata::troopdata

test.compare <- test.current %>%
  dplyr::full_join(test.old, by = c("ccode", "year"), suffix = c(".current", ".old")) %>%
  dplyr::mutate(matches = dplyr::case_when(
    troops_ad == troops ~ TRUE,
    TRUE ~ FALSE
  )) %>%
  dplyr::filter(year %in% comparison.years)


print(table(test.compare$matches))
