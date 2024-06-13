globalVariables(c('countryname', 'ccode', 'iso3c', 'base', 'lilypad', 'fundedsite', 'basecount', 'lilypadcount', 'fundedsitecount', '.data'))

#' Function to retrieve customized U.S. basing data
#'
#' @description \code{get_basedata()} generates a customized data frame containing data obtained from David Vine's U.S. basing data.
#'
#' @return \code{get_basedata()} returns a data frame containing information on U.S. military bases present within selected host countries. This can be customized to include country-base observations or country-count observations.
#'
#' @details Our research team updated these data through 2018.
#'
#' @author Michael E. Flynn
#'
#' @param host The Correlates of War (COW) numeric country code or ISO3C code for the host country or countries in the series
#' @param country_count Logical. Should the function return a country-level count of the total number of bases or the country-site data
#' @param groupvar A character string indicating how country count totals should be generated. Accepted values are 'countryname', 'ccode', or 'iso3c'. Can take on Required when using country_count argument.
#' @importFrom rlang warn
#' @export
#' @references
#'
#' David Vine. 2015. Base Nation. Metropolitan Books. New York, NY.
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


get_basedata <- function(host = NA, country_count = FALSE, groupvar = NULL) {

  if(country_count == TRUE) rlang::warn("Must specify grouping variable when using country_count.")
  if(!is.null(groupvar)) rlang::warn("group var must equal 'countryname', 'ccode', or 'iso3c'.")


  basetemp <- troopdata::basedata


  if (is.numeric(host)) {

    basetemp <- basetemp %>%
      dplyr::filter(ccode %in% host)


  } else if (is.character(host)) {

    basetemp <- basetemp %>%
      dplyr::filter(iso3c %in% host)

  } else {

    basetemp <- basetemp

  }

  if (country_count==TRUE) {


    basetemp <- basetemp %>%
      dplyr::group_by(.data[[groupvar]]) %>%
      dplyr::summarise(basecount = sum(base, na.rm = TRUE),
                       lilypadcount = sum(lilypad, na.rm = TRUE),
                       fundedsitecount = sum(fundedsite, na.rm = TRUE))

    return(basetemp)

  } else {

    return(basetemp)

    }

}
