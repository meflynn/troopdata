globalVariables(c('countryname', 'ccode', 'iso3c', 'year', 'troops', 'army', 'navy', 'air_force', 'marine_corps'))

#' Load troop Data
#'
#'
#' @param host The Correlates of War (COW) numeric country code or ISO3C code for the host country or countries in the series
#' @param branch Logical. Should the function return a single vector containing total troop values or multiple vectors containing total values and values for individual branches? Default is FALSE.
#' @param startyear the first year for the series
#' @param endyear The last year for the series
#' @importFrom rlang warn
#' @return Returns a data frame containing country year observations for troop deployments
#' @export
#'
#'
#' @references Tim Kane. Global U.S. troop deployment, 1950-2003. Technical Report. Heritage Foundation, Washington, D.C.
#' @references Michael A. Allen, Michael E. Flynn, Carla Martinez Machain, and Andrew Stravers. 2021. "Global U.S. military deployment data: 1950-2020." Working Paper.
#'
#'
#'@examples
#'
#'\dontrun{
#'library(tidyverse)
#'library(troopdata)
#'
#'example <- get_troopdata(host = NA, branch = TRUE, startyear = 1980, endyear = 2015)
#'
#'head(example)
#'
#'}
#'




get_troopdata <- function(host = NA, branch = FALSE, startyear, endyear) {

  tempdata <- troopdata::troopdata

  # Set warning for year range
  if(startyear < 1950 | endyear > max(tempdata$year)) stop("Specified year is out of range. Available range includes 1950 through 2020.")

  if(branch)  rlang::warn("Branch data only available for 2006 forward.")

  if (is.na(host)) {

    tempdata <- tempdata %>%
      dplyr::filter(year >= startyear & year <= endyear)

  } else if (is.numeric(host)) {

    host <- c(host)

    tempdata <- tempdata %>%
      dplyr::filter(ccode %in% host & year >= startyear & year <= endyear)

  } else {

    host <- c(host)

    tempdata <- tempdata %>%
      dplyr::filter(iso3c %in% host & year >= startyear & year <= endyear)

  }


  if (branch) {

    tempdata <- tempdata %>%
      dplyr::select(countryname, ccode, iso3c, year, troops, army, navy, air_force, marine_corps)

  } else {

    tempdata <- tempdata %>%
      dplyr::select(countryname, ccode, iso3c, year, troops)

  }

}

