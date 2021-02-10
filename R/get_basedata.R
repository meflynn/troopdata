globalVariables(c('countryname', 'ccode', 'iso3c', 'base', 'lilypad', 'fundedsite', 'basecount', 'lilypadcount', 'fundedsitecount'))

#' Load basing data
#'
#'
#' @param host The Correlates of War (COW) numeric country code or ISO3C code for the host country or countries in the series
#' @param country_count Logical. Should the function return a country-level count of the total number of bases or the country-site data
#' @importFrom rlang warn
#' @return Returns a data frame containing information on bases present within selected host countries
#' @export
#' @references David Vine. 2015. Base Nation. Metropolitan Books. New York, NY.
#'
#' @examples
#'
#' \dontrun{
#' library(tidyverse)
#' library(troopdata)
#'
#' example <- get_basedata(host = NA)
#'
#' head(example)
#'
#' }
#'


get_basedata <- function(host = NA, country_count = FALSE) {

  if (!is.numeric(host) & !is.character(host) & !is.na(host)) {
    warn(message = "Host argument should be numeric value or a vector of numeric values corresponding to COW country codes.")
  }

  basetemp <- troopdata::basedata

  if (is.na(host)) {

    basetemp

  } else if (is.numeric(host)) {

    host <- c(host)

    basetemp <- basetemp %>%
      dplyr::filter(ccode %in% host)

  } else {

    host <- c(host)

    basetemp <- basetemp %>%
      dplyr::filter(iso3c %in% host)

  }

  if (country_count) {

    basetemp <- basetemp %>%
      dplyr::group_by(ccode) %>%
      dplyr::summarise(basecount = sum(base, na.rm = TRUE),
                       lilypadcount = sum(lilypad, na.rm = TRUE),
                       fundedsitecount = sum(fundedsite, na.rm = TRUE))

  } else {

      basetemp

    }

}
