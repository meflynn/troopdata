globalVariables(c('ccode', 'iso3c', 'countryname', 'fipscode', 'region', 'year', 'month', 'quarter', 'source', 'location', 'troops_ad', 'army_ad', 'army', 'navy_ad', 'air_force_ad', 'marine_corps_ad', 'coast_guard_ad', 'space_force_ad', 'army_national_guard', 'air_national_guard', 'army_reserve', 'navy_reserve', 'marine_corps_reserve', 'air_force_reserve', 'coast_guard_reserve', 'total_selected_reserve', 'army_civilian', 'navy_civilian', 'marine_corps_civilian', 'air_force_civilian' , 'dod_civilian', 'total_civilian', 'Total', 'Total Ashore', 'Total Afloat', 'Army Total', 'Navy Total', 'Marine Corps Total', 'Air Force Total', 'Coast Guard Total', 'Space Force Total', 'Army National Guard Total', 'Air National Guard Total', 'Army Reserve Total', 'Navy Reserve Total', 'Marine Corps Reserve Total', 'Air Force Reserve Total', 'Coast Guard Reserve Total', 'Total Selected Reserve Total', 'Army Civilian Total', 'Navy Civilian Total', 'Marine Corps Civilian Total', 'Air Force Civilian Total', 'DoD Civilian Total', 'Total Civilian Total', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian'))

#' Function to retrieve customized U.S. troop deployment data
#'
#' @description \code{get_troopdata()} generates a customized data frame containing country-year observations of U.S. military deployments overseas.

#' @return \code{get_troopdata()} returns a data frame containing country-year observations for U.S. troop deployments.
#'
#' @param host The Correlates of War (COW) numeric country code, ISO3C code, or country name, for the host country or countries in the series. If region == TRUE the user can specify a COW region name and the function will try to match it to the region column in the data. The default is NA.
#' @param startyear The first year for the series. The default is set to 1950.
#' @param endyear The last year for the series. The default is the maximum year in the currently published data.
#' @param branch Logical. Should the function return a single vector containing total troop values or multiple vectors containing total values and values for individual branches? Default is FALSE.
#' @param guard_reserve Logical. Should the function return values for the National Guard and Reserve? Default is FALSE.
#' @param civilians Logical. Should the function return values for civilian DoD personnel? Default is FALSE.
#' @param quarters Logical. Should the function return quarterly data? Default is FALSE.
#' @param reports Logical. Should the function return reports for the specified countries and years? Default is FALSE.
#' @param state_data Logical. Should the function return disaggregated data on US States? Default is FALSE.
#'
#'
#' @importFrom rlang warn
#' @importFrom dplyr sym
#' @importFrom dplyr matches
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
#'example <- get_troopdata(host = "United States",
#'                         branch = TRUE,
#'                         startyear = 1980,
#'                         endyear = 2015)
#'
#'head(example)
#'
#'}
#'




get_troopdata <- function(host = NULL,
                          branch = FALSE,
                          startyear = 1950,
                          endyear = 2025,            # Update year to present
                          quarters = FALSE,
                          guard_reserve = FALSE,
                          civilians = FALSE,
                          state_data = FALSE,
                          reports = FALSE) {


  # First determine if we're using reports or long data format. This depends on reports argument being TRUE or FALSE.
  # Have to include this chunk first so the following if statements can evaluate the temp data object.
  if(reports == TRUE) {

    tempdata <- troopdata::troopdata_rebuild_reports

  } else if (state_data == TRUE) {

    tempdata <- troopdata::troopdata_rebuild_us_states

  }  else {

    tempdata <- troopdata::troopdata_rebuild_long

    }





  # Set warning for year range and assign default values to allow the function complete
  if(startyear < 1950 | endyear > max(tempdata$year)) warn("Specified year is out of range. Available range includes 1950 through 2025")
  if(startyear < 1950) startyear <- 1950
  if(endyear > max(tempdata$year)) endyear <- max(tempdata$year)

  # Set warning for branch and guard_reserve values.
  if(branch)  rlang::warn("Branch data only includes active duty by default. This preserves continuity across time periods as guard and reserve data are not reported prior to 2008 Also note that disaggregated data are not available for 2003 and 2004 as the DMDC did not issue reports for those years. Also note that Iraq does not have branch data for 2003-2007 and troops_ad value is estimated using alternative sources.")
  if(guard_reserve) rlang::warn("Guard and Reserve data only available for 2008 forward. Values will display as NA for earlier time periods.")
  if(quarters) rlang::warn("Some service branches do not report data for all quarters. See the following note from December, 2022, June 2023, and March 2023 DMDC reports: 'The Army is converting its Integrated Personnel and Pay System (IPPS-A) and so the Army did not provide military personnel data for end-of-June 2023.' We use a stepwise imputation process to fill in the gaps between September 2022 and September 2023, taking the difference between the values for these two periods and incrementally adjusting totals for the missing periods between.")
  # Many of the reports are in quarterly format in more recent years. Make user set
  if(reports == TRUE && quarters == FALSE)  stop("Reports are only available in quarterly format. Please set quarters = TRUE.")
  if(guard_reserve == FALSE) warning("total_ad value shows the total number of active duty personnel only and does not include any guard or reserve troops that may be present. For the total number of uniformed personnel please choose guard_reserve = TRUE. Note that guard and reserve data are not included in DMDC reports prior to 2008 so troops_all should be equal to troops_ad for earlier time periods.")

  # Next, if reports is TRUE we want to know if we need to filter by host and year, or include all hosts.
  if (is.numeric(host) || is.character(host)) {


    # Try to determine host type match. What are they searching for?
    invisible(host.type <- if(is.numeric(host[1]) && state_data == FALSE) {
      "ccode"
    } else if (is.character(host[1]) && nchar(host[1]) == 3 && state_data == FALSE) {
      "iso3c"
    } else if (is.character(host[1]) && nchar(host[1]) != 3 && state_data == FALSE && sum(grepl(paste(host, collapse = "|"), tempdata$countryname, ignore.case = TRUE)) == 0 || sum(grepl(paste(host, collapse = "|"), "Africa", ignore.case = TRUE)) > 0) {
      "region"
    } else if (is.character(host[1]) && nchar(host[1]) != 3 && state_data == FALSE &&  sum(grepl(paste(host, collapse = "|"), tempdata$countryname, ignore.case = TRUE)) > 0) {
      "countryname"
    } else if (is.numeric(host[1]) && state_data == TRUE) {
      "fipscode"
    } else if (is.character(host[1]) && state_data == TRUE) {
      "state"
    }
    )

    # Filter by host type using if/else instead of case_when
    if (host.type == "ccode") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), ccode))
    } else if (host.type == "iso3c") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), iso3c, ignore.case = TRUE))
    } else if (host.type == "region") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(".*", host, ".*", collapse = "|", sep = ""), region, ignore.case = TRUE))
    } else if (host.type == "countryname") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE))
    } else if (host.type == "fipscode") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), fipscode))
    } else if (host.type == "state") {
      tempdata <- tempdata %>%
        dplyr::filter(year %in% c(startyear:endyear)) %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), state))
    }

    if (reports == TRUE) {

      return(tempdata)

    }

  } else {

    tempdata <- tempdata %>%
      dplyr::filter(year %in% c(startyear:endyear))

  }


  # Select columns based on user input.

  if (branch==FALSE ) {

    branch.select <- NULL

  } else  {

    branch.select <- c("army_ad", "navy_ad", "air_force_ad", "marine_corps_ad", "coast_guard_ad", "space_force_ad")

  }

  if (guard_reserve==FALSE ) {

    guard_reserve.select <- NULL

  } else  {

    guard_reserve.select <- c("army_national_guard", "air_national_guard", "army_reserve", "navy_reserve", "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve", "total_selected_reserve", "troops_all")

  }

  if (civilians==FALSE ) {

    civilians.select <- NULL

  } else {

    civilians.select <- c("army_civilian", "navy_civilian", "marine_corps_civilian", "air_force_civilian", "dod_civilian", "total_civilian")

  }

  tempdata <- tempdata %>%
    dplyr::select(ccode, year, month, quarter, iso3c, countryname, region, troops_ad, tidyselect::all_of(branch.select), tidyselect::all_of(guard_reserve.select), tidyselect::all_of(civilians.select)) %>%
    dplyr::ungroup()

  # Aggregate time periods
  #
  # We also want to preserve various grouping identifiers. This means we need to decide which groupings are not included in host.type and create a character vector with the other groupings.

  if (is.null(host) && state_data == FALSE) {

    # If no host specified then set countryname as default host type.
    host.type <- "countryname"

    # Create character vector of all possible grouping variables.
    host.terms <- c("ccode", "iso3c", "countryname", "region")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

  } else if (!is.null(host) && state_data == FALSE) {

    # Create character vector of all possible grouping variables.
    host.terms <- c("ccode", "iso3c", "countryname", "region")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

  } else if (is.null(host) && state_data == TRUE) {

    host.type <- "state"

  }


  # The function will drop the unused grouping variables but this should be ok.
  # There are lots of different situations where a given space has multiple grouping variables.
  if (quarters == TRUE && host.type %in% c("ccode", "iso3c", "countryname")) {

    tempdata <- tempdata %>%
      dplyr::group_by(!!sym(host.type), year, month, quarter) %>%
      dplyr::summarise(dplyr::across(.cols = tidyselect::all_of(host.terms), ~ dplyr::first(.x)),
                       dplyr::across(dplyr::matches("_ad|_all|civilian|guard|reserve"), ~ max(.x, na.rm = TRUE)))

  } else if (quarters == FALSE && host.type %in% c("ccode", "iso3c", "countryname")) {

    tempdata <- tempdata %>%
      dplyr::group_by(!!sym(host.type), year) %>%
      dplyr::summarise(dplyr::across(.cols = tidyselect::all_of(host.terms), ~ dplyr::first(.x)),
                       dplyr::across(dplyr::matches("_ad|_all|civilian|guard|reserve"), ~ max(.x, na.rm = TRUE)))

  } else if (quarters == TRUE && host.type == "region") {

    tempdata <- tempdata %>%
      dplyr::group_by(region, year, month, quarter) %>%
      dplyr::summarise(dplyr::across(dplyr::matches("_ad|_all|civilian|guard|reserve"), ~ max(.x, na.rm = TRUE)))

  } else if (quarters == FALSE && host.type == "region") {

    tempdata <- tempdata %>%
      dplyr::group_by(region, year) %>%
      dplyr::summarise(dplyr::across(dplyr::matches("_ad|_all|civilian|guard|reserve"), ~ max(.x, na.rm = TRUE)))

  }

  # Make sure to remove any lingering -Inf values and replace with NA.
  # They're introduced when NA values are summarised.
  tempdata <- dplyr::ungroup(tempdata) %>%
    dplyr::mutate(dplyr::across(everything(),
                                ~ ifelse(is.infinite(.x), NA, .x)))

  return(tempdata)

}
