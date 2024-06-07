globalVariables(c('ccode', 'iso3c', 'countryname', 'region', 'year', 'month', 'quarter', 'source', 'location', 'troops_ad', 'army_ad', 'army', 'navy_ad', 'air_force_ad', 'marine_corps_ad', 'coast_guard_ad', 'space_force_ad', 'army_national_guard', 'air_national_guard', 'army_reserve', 'navy_reserve', 'marine_corps_reserve', 'air_force_reserve', 'coast_guard_reserve', 'total_selected_reserve', 'army_civilian', 'navy_civilian', 'marine_corps_civilian', 'air_force_civilian' , 'dod_civilian', 'total_civilian'))

#' Function to retrieve customized U.S. troop deployment data
#'
#' @description \code{get_troopdata()} generates a customized data frame containing country-year observations of U.S. military deployments overseas.

#' @return \code{get_troopdata()} returns a data frame containing country-year observations for U.S. troop deployments.
#'
#' @param host The Correlates of War (COW) numeric country code, ISO3C code, or country name, for the host country or countries in the series. If region == TRUE the user can specify a COW region name and the function will try to match it to the region column in the data. The default is NA.
#' @param branch Logical. Should the function return a single vector containing total troop values or multiple vectors containing total values and values for individual branches? Default is FALSE.
#' @param guard_reserve Logical. Should the function return values for the National Guard and Reserve? Default is FALSE.
#' @param civilians Logical. Should the function return values for civilian DoD personnel? Default is FALSE.
#' @param reports Logical. Should the function return reports for the specified countries and years? Default is FALSE.
#' @param startyear The first year for the series. The default is set to 1950.
#' @param endyear The last year for the series. The default is the maximum year in the currently published data.
#' @param quarters Logical. Should the function return quarterly data? Default is FALSE.
#'
#'
#' @importFrom rlang warn
#' @export
#'
#' @author Michael E. Flynn
#'
#' @references Tim Kane. Global U.S. troop deployment, 1950-2003. Technical Report. Heritage Foundation, Washington, D.C.
#' @references Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2022. "Global U.S. military deployment data: 1950-2020." Conflict Management and Peace Science. 39(3): 351-370.
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




get_troopdata <- function(host = NA,
                          branch = FALSE,
                          startyear = 1950,
                          endyear = max(troopdata::troopdata_rebuild_long$year),
                          quarters = FALSE,
                          guard_reserve = FALSE,
                          civilians = FALSE,
                          reports = FALSE) {

  if(reports == TRUE) {

    tempdata <- troopdata::troopdata_rebuild_reports

  } else {

    tempdata <- troopdata::troopdata_rebuild_long


  # Set warning for year range and assign default values to allow the function complete
  if(startyear < 1950 | endyear > max(tempdata$year)) warn("Specified year is out of range. Available range includes 1950 through 2024")
  if(startyear < 1950) startyear <- 1950
  if(endyear > max(tempdata$year)) endyear <- max(tempdata$year)

  # Set warning for branch and guard_reserve values.
  if(branch)  rlang::warn("Branch data only includes active duty by default. This preserves continuity across time periods as guard and reserve data are not reported prior to 2000s.")
  if(guard_reserve) rlang::warn("Guard and Reserve data only available for 2006 forward.")
  if(quarters) rlang::warn("Some service branches do not report data for all quarters. See the following note from December, 2022, June 2023, and March 2023 DMDC reports: 'The Army is converting its Integrated Personnel and Pay System (IPPS-A) and so the Army did not provide military personnel data for end-of-June 2023.'")


  if (is.na(host)) {

    tempdata <- tempdata %>%
      dplyr::filter(year %in% c(startyear:endyear))

  } else if (is.numeric(host)) {

    host <- c(host)

    tempdata <- tempdata |>
      dplyr::filter(ccode %in% host)

  } else if (is.character(host)) {

    host <- c(host)

    tempdata <- tempdata |>
      dplyr::filter(case_when(
        nchar(host[1]) == 3 ~ iso3c %in% host,
        nchar(host[1]) > 3 ~ grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE),
        !grepl(paste(".*", host, ".*", collapse = "|"), countryname, ignore.case = TRUE) ~ grepl(paste(".*", host, ".*", collapse = "|"), region, ignore.case = TRUE)
      ))

  }

  # Allow users to look at branch specific values
  if (branch==FALSE) {

    tempdata <- tempdata |>
      dplyr::select(ccode, iso3c, countryname, year, month, quarter,
                    !contains("army_ad|navy_ad|air_force_ad|marine_corps_ad|coast_guard_ad|space_force_ad"))

  } else if (branch==TRUE) {

    tempdata <- tempdata |>
      dplyr::select(ccode, iso3c, countryname, year, month, quarter,
                    contains("army_ad|navy_ad|air_force_ad|marine_corps_ad|coast_guard_ad|space_force_ad"))

  } else if (guard_reserve == FALSE) {

    tempdata <- tempdata %>%
      dplyr::select(ccode, iso3c, countryname, year, month, quarter,,
                    !contains("guard|reserve"))

  } else if (civilians == FALSE) {

    tempdata <- tempdata %>%
      dplyr::select(ccode, iso3c, countryname, year, month, quarter,
                    !contains("civilian"))

  } else if (civilians == TRUE) {

    tempdata <- tempdata %>%
      dplyr::select(ccode, iso3c, countryname, year, month, quarter,
                    contains("civilian"))

  }

  # Aggregate time periods

  if(quarters == TRUE) {

    tempdata <- tempdata %>%
      dplyr::group_by(ccode, year, month, quarter) %>%
      dplyr::summarise(dplyr::across(contains("troops|_ad|civilians|guard|reserve"), ~ sum(.x, na.rm = TRUE)))

  } else {

    tempdata <- tempdata %>%
      dplyr::group_by(ccode, year) %>%
      dplyr::summarise(dplyr::across(contains("troops|_ad|civilians|guard|reserve"), ~ sum(.x, na.rm = TRUE)))

  }


  return(tempdata)

  }
}

