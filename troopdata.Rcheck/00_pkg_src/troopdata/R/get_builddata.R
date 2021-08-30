globalVariables(c('countryname', 'ccode', 'iso3c', 'year', 'spend_construction', 'lon', 'lat'))

#' Function to retrieve customized U.S. construction spending data.
#'
#' @description \code{get_builddata()} generates a customized data frame containing location-project-year observations of U.S. military construction and housing spending in thousands of current dollars.

#' @return \code{get_builddata()} returns a data frame containing location-project-year observations of U.S. military construction and housing spending in thousands of current dollars.
#'
#' @param host The Correlates of War (COW) numeric country code or ISO3C code for the host country or countries in the series
#' @param startyear The first year for the series
#' @param endyear The last year for the series
#'
#'
#' @importFrom rlang warn
#' @export
#'
#' @author Michael E. Flynn
#'
#' @references Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2020. "Outside the wire: US military deployments and public opinion in host states." American Political Science Review. 114(2): 326-341.
#'
#'
#'@examples
#'
#'\dontrun{
#'library(tidyverse)
#'library(troopdata)
#'
#'example <- get_builddata(host = NA, startyear = 2008, endyear = 2019)
#'
#'head(example)
#'
#'}
#'
#'
#'


get_builddata <- function(host = NA, startyear, endyear) {

  tempdata <- troopdata::builddata

  # Set warning for year
  if(startyear < min(tempdata$year) | endyear > max(tempdata$year)) stop("Specified year is out of range. Available range includes 2008 through 2019")

  warn("Be advised that the data include unspecified locations, as well as 0 or negative spending values.")

  warn("Spending values are in thousands of current US dollars.")

  if(is.na(host)) {

    tempdata <- tempdata %>%
      dplyr::filter(year >= startyear & year <= endyear)

    return(tempdata)

  } else if (is.numeric(host)) {

    host <- c(host)

    tempdata <- tempdata %>%
      dplyr::filter(ccode %in% host & year >= startyear & year <= endyear)

    return(tempdata)

  } else {

    host <- c(host)

    tempdata <- tempdata %>%
      dplyr::filter(ccode %in% host & year >= startyear & year <= endyear)

    return(tempdata)

  }
}
