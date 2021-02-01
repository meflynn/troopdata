#' Load Troop Data
#'
#'
#' @param host The Correlates of War (COW) numeric country code for the host country or countries in the series
#' @param branch Logical. Should the function return a single vector containing total troop values or multiple vectors containing total values and values for individual branches? Default is FALSE.
#' @param startyear the first year for the series
#' @param endyear The last year for the series
#' @return Returns a data frame containing country year observations for troop deployments
#' @export

get_troopdata <- function(host = NA, branch = FALSE, startyear, endyear) {

  tempdata <- troopdata::troopdata

  # Set warning for year range
  if(startyear < 1950 | endyear > max(tempdata$year)) {
    stop("Specified year is out of range. Available range includes 1950 through 2020.")
  }

  if(branch) {
    warn("Branch data only available for 2006 forward.")
  }

  if (is.na(host)) {

    tempdata <- tempdata %>%
      dplyr::filter(year >= startyear & year <= endyear)

  }

  else {

    host <- c(host)

    tempdata <- tempdata %>%
      dplyr::filter(ccode %in% host & year >= startyear & year <= endyear)

  }

  if (branch) {

    tempdata <- tempdata %>%
      dplyr::select(ccode, year, troops, army, navy, air_force, marine_corps)

  } else {

    tempdata <- tempdata %>%
      dplyr::select(ccode, year, troops)

  }

}

