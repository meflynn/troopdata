#'
#' Troop Data
#'
#' @description \code{get_troopdata()} returns a data frame containing information on US military deployments.
#'
#' @return Data on US military deployments to overseas locations (countries and territories) from 1950 through 2020. The data were originally
#' compiled by Tim Kane of the Heritage Foundation using Defense Manpower Data Center quarterly reports on US troop deployments.
#' These data originally ended in 2005 but we have updated them to run through 2020. We have also used news reports to update deployment
#' figures for particular countries like Iraq where the DOD stopped reporting data.
#'
#'
#' @format A data frame with country year observations including the following variables:
#' \describe{
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{troops}}{The total number of US military personnel deployed to the host country.}
#' \item{\code{army}}{Total number of Army personnel deployed to the host country.}
#' \item{\code{navy}}{Total number of Navy personnel deployed to the host country.}
#' \item{\code{air_force}}{Total number of Air Force personnel deployed to the host country.}
#' \item{\code{marine_corps}}{Total number of Marine Corps personnel deployed to the host country.}
#' }
#'
#'@source \url{https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005}
#'
"troopdata"



#' Base data
#'
#' @description \code{get_basedata()} returns a data frame containing David Vine's US basing data.
#'
#' @return Data on US military bases from the Cold War period through the present. These data were initially collected by David Vine (2015). We
#' updated the data through 2018 for inclusion in this package. The data include two versions. The first is the country-base data, which
#' also includes information on the type of military facility and the longitude and latitude of the facility. The second version presents
#' a simple country-count data frame, where the count is the number of bases located in that country.
#'
#' @format A data frame with country year observations including the following variables:
#' \describe{
#' \item{\code{country}}{A character string giving the host country's name.}
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{basename}}{Name of the facility.}
#' \item{\code{lat}}{The facility's latitude.}
#' \item{\code{lon}}{The facility's longitude.}
#' \item{\code{base}}{Binary indicator identifying the faciltiy as a major base  or not.}
#' \item{\code{lilypad}}{A binary indicator identifying the faciltiy as a lilypad or not.}
#' \item{\code{fundedsite}}{A binary variable indicating whether or not the facility is }
#' }
#'
#'@source \url{https://dra.american.edu/islandora/object/auislandora%3A81234}
#'
"basedata"
