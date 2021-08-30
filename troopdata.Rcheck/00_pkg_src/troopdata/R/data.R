#'
#' U.S. overseas troop deployment data
#'
#' @description \code{troopdata} returns a data frame containing information on US military deployments.
#'
#' @return Returns the full data frame containing country-year observations of US military deployments to overseas locations (countries and territories) from 1950 through 2020.
#'
#'
#'
#' @format A data frame with country year observations including the following variables:
#'
#' \describe{
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{troops}}{The total number of US military personnel deployed to the host country.}
#' \item{\code{army}}{Total number of Army personnel deployed to the host country.}
#' \item{\code{navy}}{Total number of Navy personnel deployed to the host country.}
#' \item{\code{air_force}}{Total number of Air Force personnel deployed to the host country.}
#' \item{\code{marine_corps}}{Total number of Marine Corps personnel deployed to the host country.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name troopdata
#'
#' @source \url{https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005}
#'
"troopdata"



#' Vine's U.S. basing data
#'
#' @description \code{basedata} returns a data frame containing David Vine's US basing data.
#'
#' @return Returns the full data frame containing country observations of US military bases from the Cold War period through 2018.
#'
#' @format A data frame with country-base observations including the following variables:
#' \describe{
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{basename}}{Name of the facility.}
#' \item{\code{lat}}{The facility's latitude.}
#' \item{\code{lon}}{The facility's longitude.}
#' \item{\code{base}}{Binary indicator identifying the facility as a major base or not.}
#' \item{\code{lilypad}}{A binary indicator identifying the facility as a lilypad or not. Vine codes lilypads as less than 200 personnel or "other site" designation in Pentagon reports.}
#' \item{\code{fundedsite}}{A binary variable indicating whether or not the facility is a host-state base funded by the US.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name basedata
#'
#' @source \url{https://dra.american.edu/islandora/object/auislandora%3A81234}
#'
"basedata"
