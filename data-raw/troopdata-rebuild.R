## code to prepare `DATASET` dataset goes here

library(tidyverse)
library(data.table)
library(haven)
library(here)
library(readxl)
library(purrr)
library(furrr)
library(stringr)

# Load the data
#
# Using the tidyverse package and the read_xlsx function, write a code chunk to load every .xls file in the /Users/michaelflynn/Library/CloudStorage/Dropbox/Projects/Troop Data/Data Files/M05 Military Only folder.
# Load each individual xls file into a list that contains all of the xls files in this folder.
# The list object chould be named "datalist".
#
#

# Load data files from 1950 to 1976
datalist.1950.1977 <- list.files(here("../../Projects/Troop Data/Data Files/M05 Military Only"), pattern = "xls", full.names = TRUE) |>
  purrr::map(.f = readxl::read_xls)

# Read file names into list for 1977 to 2010.
# Use this list to extract dates and names later on.
datalist.1977.2010.names <- list.files(here("../../Projects/Troop Data/Data Files/309A_Reports_1977-2011"), pattern = "\\.xls$", full.names = TRUE)

# Read in actual files from the list
datalist.1977.2010 <- datalist.1977.2010.names |>
  purrr::map(.f = readxl::read_xls)


# Read in file names for 2011 to 2023
datalist.2008.2023.names <- list.files(here("../../Projects/Troop Data/Data Files/2008-Present"), pattern = "\\.xlsx$", full.names = TRUE)

# Read in data files for 2011 to 2023 from the list of file names.
datalist.2008.2023 <- datalist.2008.2023.names |>
  purrr::map(.f = readxl::read_xlsx)



# Pull names from the data frames and use them to generate names for each data frame in the list.
names.1950.1977 <- map(.x = seq_along(datalist.1950.1977),
             .f = ~ str_extract(datalist.1950.1977[[.x]][[1]],
                                pattern = "September\\s{1}([0-9]{4})|June\\s{1}([0-9]{4})") |>
               as.data.frame()
             ) |>
  bind_rows() |>
  drop_na()

listnames.1950.1977 <- as.vector(names.1950.1977[[1]])

# Basic data cleaning for 1950 to 1977
data.clean.1950.1977 <- datalist.1950.1977 |>
  purrr::map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Assign names to the data frames
names(data.clean.1950.1977) <- listnames.1950.1977



# Basic data cleaning for 1977 to 2011
data.clean.1977.2010 <- datalist.1977.2010 |>
  purrr::map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Pull years from file list for the 1976 to 2011 data.
listnames.1977.2010 <- map(.x = seq_along(datalist.1977.2010.names),
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
  purrr::map(.f = ~ .x |>
               janitor::clean_names() |>
               janitor::remove_empty("rows") |>
               janitor::remove_empty("cols")
  )

# Pull years and months from the file list for the 2008 to Present Data
listnames.2008.2023 <- map(.x = seq_along(datalist.2008.2023.names),
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


# Create separate list objects containing the data frames for time periods that have the same spreadsheet formatting.
# Each list object should only contain data frames with the same formatting and number of columns.

data.clean.1950.1953 <- list(data.clean.1950.1977[["June 1950"]],
                          data.clean.1950.1977[["June 1953"]])

data.clean.1954.1956 <- list(data.clean.1950.1977[["June 1954"]],
                          data.clean.1950.1977[["June 1955"]],
                          data.clean.1950.1977[["June 1956"]])

data.clean.1957.1967 <- list(data.clean.1950.1977[["September 1957"]],
                          data.clean.1950.1977[["September 1958"]],
                          data.clean.1950.1977[["September 1959"]],
                          data.clean.1950.1977[["September 1960"]],
                          data.clean.1950.1977[["September 1961"]],
                          data.clean.1950.1977[["September 1962"]],
                          data.clean.1950.1977[["September 1963"]],
                          data.clean.1950.1977[["September 1964"]],
                          data.clean.1950.1977[["September 1965"]],
                          data.clean.1950.1977[["September 1966"]],
                          data.clean.1950.1977[["September 1967"]])

data.clean.1968.1976 <- list(data.clean.1950.1977[["September 1968"]],
                          data.clean.1950.1977[["September 1969"]],
                          data.clean.1950.1977[["September 1970"]],
                          data.clean.1950.1977[["September 1971"]],
                          data.clean.1950.1977[["September 1972"]],
                          data.clean.1950.1977[["September 1973"]],
                          data.clean.1950.1977[["September 1974"]],
                          data.clean.1950.1977[["September 1975"]],
                          data.clean.1950.1977[["September 1976"]])

# Create names to match the column orderings from the four lists of data frames.

names.1950.1953 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                  "Navy Ashore", "Navy Temporary Ashore", "Navy Other", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1954.1956 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                  "Navy Ashore", "Navy Afloat", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1957.1967 <- c("Location", "Total", "Total Ashore", "Total Afloat", "Army Total",
                  "Navy Ashore", "Navy Temporary Ashore", "Navy Other", "Marine Corps Ashore", "Marine Corps Afloat", "Air Force Total")

names.1968.1976 <- c("Location", "Total Ashore", "Total Afloat", "Total", "Army Total", "Navy Ashore", "Navy Afloat", "Navy Total", "Marine Corps Ashore", "Marine Corps Afloat", "Marine Corps Total", "Air Force Total")

names.1977.2010 <- c("Location", "Total", "Army Total", "Navy Total", "Marine Corps Total", "Air Force Total")

# Apply names and remove uninformative or rows
data.clean.1950.1953 <- data.clean.1950.1953 |>
  purrr::map(.f = ~ .x |>
               setNames(names.1950.1953) |>
               filter(!is.na(Location)) |>
               slice(-c(1:2))
  )

data.clean.1954.1956 <- data.clean.1954.1956 |>
  purrr::map(.f = ~ .x |>
               setNames(names.1954.1956) |>
               filter(!is.na(Location)) |>
               slice(-c(1:2))
  )

data.clean.1957.1967 <- data.clean.1957.1967 |>
  purrr::map(.f = ~ .x |>
               setNames(names.1957.1967) |>
               filter(!is.na(Location)) |>
               slice(-c(1:2))
  )

data.clean.1968.1976 <- data.clean.1968.1976 |>
  purrr::map(.f = ~ .x |>
               setNames(names.1968.1976) |>
               filter(!is.na(Location)) |>
               slice(-c(1:2)
  )
  )

data.clean.1977.2010 <- data.clean.1977.2010 |>
  purrr::map(.f = ~ .x |>
               setNames(names.1977.2010) |>
               filter(!is.na(Location)) |>
               slice(-c(1:3)
  )
  )



# Note that each region has an "afloat" category attached. We'll have to deal with this and treat it as its own country/location.
