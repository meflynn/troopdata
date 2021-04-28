## code to build expenditures data

library(tidyverse)
library(here)
library(readr)

builddata <- read_csv(here::here("../../Projects/Minerva grant documents/Military Spending/operations-and-maintenance/data-spend-geocoded-20210428.csv"))

readr::write_csv(builddata, "data-raw/builddata.csv")
usethis::use_data(builddata, overwrite = TRUE, internal = FALSE)

