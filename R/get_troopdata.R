globalVariables(c('ccode', 'iso3c', 'countryname', 'state', 'fipscode', 'region', 'year', 'month', 'quarter', 'source', 'location', 'troops_ad', 'army_ad', 'army', 'navy_ad', 'air_force_ad', 'marine_corps_ad', 'coast_guard_ad', 'space_force_ad', 'army_national_guard', 'air_national_guard', 'army_reserve', 'navy_reserve', 'marine_corps_reserve', 'air_force_reserve', 'coast_guard_reserve', 'total_selected_reserve', 'army_civilian', 'navy_civilian', 'marine_corps_civilian', 'air_force_civilian' , 'dod_civilian', 'total_civilian', 'Total', 'Total Ashore', 'Total Afloat', 'Army Total', 'Navy Total', 'Marine Corps Total', 'Air Force Total', 'Coast Guard Total', 'Space Force Total', 'Army National Guard Total', 'Air National Guard Total', 'Army Reserve Total', 'Navy Reserve Total', 'Marine Corps Reserve Total', 'Air Force Reserve Total', 'Coast Guard Reserve Total', 'Total Selected Reserve Total', 'Army Civilian Total', 'Navy Civilian Total', 'Marine Corps Civilian Total', 'Air Force Civilian Total', 'DoD Civilian Total', 'Total Civilian Total', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian'))

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
#' @param reports Logical. Should the function return reports for the specified countries and years? Default is FALSE. The reports are returned as reported, without aggregation, so a country code may appear on more than one row in a period where the report breaks that country's territories out separately.
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


  # First determine if we're using reports, state_data, or long data format. This depends on reports argument being TRUE or FALSE.
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

  # Next we want to know if we need to filter by host and year, or include all hosts.
  # The reports data keeps the country names the reports themselves use, so one country code can
  # carry several names within it (Japan and the Ryukyu Islands under 740, Guam and the Northern
  # Marianas under 1008). Name matching is always resolved against the country-year data, which
  # holds one canonical name per code, and the resulting codes are what filter the data in hand.
  # That way host = "Japan" returns the Ryukyu rows too.
  canonical <- troopdata::troopdata_rebuild_long

  if (is.numeric(host) || is.character(host)) {

    # Accept common alternative spellings so that a country can be found under either the name the
    # package uses or the name the user is likely to type.
    if (is.character(host)) {

      host.aliases <- c("eswatini" = "Swaziland",
                        "swaziland" = "Eswatini",
                        "czechia" = "Czech Republic",
                        "cote d'ivoire" = "Ivory Coast",
                        "côte d'ivoire" = "Ivory Coast",
                        "turkiye" = "Turkey",
                        "türkiye" = "Turkey",
                        "cape verde" = "Cabo Verde",
                        "burma" = "Myanmar",
                        "north macedonia" = "Macedonia",
                        "timor-leste" = "East Timor")

      host <- vapply(host, function(h) {
        match.name <- host.aliases[tolower(h)]
        if (!is.na(match.name) &&
            !any(grepl(h, canonical$countryname, ignore.case = TRUE)) &&
            any(grepl(match.name, canonical$countryname, ignore.case = TRUE))) {
          unname(match.name)
        } else {
          h
        }
      }, character(1), USE.NAMES = FALSE)

    }

    # Try to determine host type match. What are they searching for?
    #
    # Note on the previous version: `A && B && C || D` parses as `(A && B && C) || D`, so the
    # "Africa" test below could send any host string that is a substring of "Africa" to region
    # matching. A host that matched nothing at all also fell through to region, returning an empty
    # data frame with no explanation, and could leave host.type NULL, which made the comparisons
    # below fail with "argument is of length zero". Each branch is now tested explicitly and an
    # unmatched host is an error rather than a silent empty result.
    host.type <- if (state_data == TRUE && is.numeric(host[1])) {
      "fipscode"
    } else if (state_data == TRUE) {
      "state"
    } else if (is.numeric(host[1])) {
      "ccode"
    } else if (all(nchar(host) == 3) &&
               any(toupper(host) %in% toupper(tempdata$iso3c))) {
      "iso3c"
    } else if (any(grepl(paste(host, collapse = "|"), canonical$countryname, ignore.case = TRUE)) ||
               any(grepl(paste(host, collapse = "|"), tempdata$countryname, ignore.case = TRUE))) {
      "countryname"
    } else if (any(grepl(paste(host, collapse = "|"), tempdata$region, ignore.case = TRUE))) {
      "region"
    } else {
      NA_character_
    }

    if (is.na(host.type)) {
      stop(paste0("`host` value(s) '", paste(host, collapse = "', '"),
                  "' did not match any country name, ISO3C code, country code, or region in the ",
                  "data. Check spelling, or see unique(get_troopdata()$countryname) for the ",
                  "names this version uses."),
           call. = FALSE)
    }

    if (host.type == "state" &&
        !any(grepl(paste(host, collapse = "|"), tempdata$state, ignore.case = TRUE))) {
      stop(paste0("`host` value(s) '", paste(host, collapse = "', '"),
                  "' did not match any state in the data."), call. = FALSE)
    }

    # Filter by host type using if/else instead of case_when
    if (host.type == "ccode") {
      tempdata <- tempdata %>%
        dplyr::filter(ccode %in% host)
    } else if (host.type == "iso3c") {
      tempdata <- tempdata %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), iso3c, ignore.case = TRUE))
    } else if (host.type == "region") {
      tempdata <- tempdata %>%
        dplyr::filter(grepl(paste(".*", host, ".*", collapse = "|", sep = ""), region, ignore.case = TRUE))
    } else if (host.type == "countryname") {

      host.ccodes <- canonical %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE)) %>%
        dplyr::pull(ccode) %>%
        unique()

      tempdata <- tempdata %>%
        dplyr::filter(ccode %in% host.ccodes |
                        grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE))
    } else if (host.type == "fipscode") {
      tempdata <- tempdata %>%
        dplyr::filter(fipscode %in% host)
    } else if (host.type == "state") {
      tempdata <- tempdata %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), state))
    }

  }


  # Filter years if reports is TRUE we'll return the entire report.
  # If reports is not TRUE then we'll keep processing.
  if (reports == TRUE) {

    # The reports are returned as reported: one row per line in the report, with the report's own
    # location and country name. A country code can appear more than once in a period where the
    # report breaks a country's territories out separately (Japan and the Ryukyu Islands under 740,
    # Guam and the Northern Marianas under 1008). Nothing is aggregated here.
    tempdata <- tempdata %>%
      dplyr::filter(year %in% c(startyear:endyear))

    return(tempdata)

  } else {

  tempdata <- tempdata %>%
    dplyr::filter(year %in% c(startyear:endyear))

  }


  # Select columns based on user input.

  if (branch==FALSE) {

    branch.select <- NULL

  } else  {

    branch.select <- c("army_ad", "navy_ad", "air_force_ad", "marine_corps_ad", "coast_guard_ad", "space_force_ad")

  }

  if (guard_reserve==FALSE) {

    guard.reserve.select <- NULL

  } else  {

    guard.reserve.select <- c("army_national_guard", "air_national_guard", "army_reserve", "navy_reserve", "marine_corps_reserve", "air_force_reserve", "coast_guard_reserve", "total_selected_reserve", "troops_all")

  }

  if (civilians==FALSE) {

    civilians.select <- NULL

  } else {

    civilians.select <- c("army_civilian", "navy_civilian", "marine_corps_civilian", "air_force_civilian", "dod_civilian", "total_civilian")

  }


  # Separate US states data and international data

  if (state_data == FALSE) {

    tempdata <- tempdata %>%
      dplyr::select(ccode, year, month, quarter, iso3c, countryname, region, troops_ad, tidyselect::all_of(branch.select), tidyselect::all_of(guard.reserve.select), tidyselect::all_of(civilians.select)) %>%
      dplyr::ungroup()

  } else if (state_data == TRUE) {

    tempdata <- tempdata %>%
      dplyr::select(fipscode, state, year, month, quarter, troops_ad, tidyselect::all_of(branch.select), tidyselect::all_of(guard.reserve.select), tidyselect::all_of(civilians.select)) %>%
      dplyr::ungroup()

  }

  # Aggregate time periods
  #
  # We also want to preserve various grouping identifiers. This means we need to decide which groupings are not included in host.type and create a character vector with the other groupings.

  if (is.null(host) && state_data==FALSE) {

    # If no host specified then set countryname as default host type.
    host.type <- "countryname"

    # Create character vector of all possible grouping variables.
    host.terms <- c("ccode", "iso3c", "countryname", "region")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

  } else if (is.null(host) && state_data==TRUE) {

    # If no host specified for state data make state name default host type.
    host.type <- "state"

    # Create character vector of all possible grouping variables.
    host.terms <- c("state", "fipscode")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

  } else if (!is.null(host) && state_data == FALSE) {

    # Create character vector of all possible grouping variables.
    host.terms <- c("ccode", "iso3c", "countryname", "region")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

    } else if (!is.null(host) && state_data == TRUE) {

    # Create character vector of all possible grouping variables.
    host.terms <- c("state", "fipscode")

    # Remove the host.type from the character vector.
    host.terms <- host.terms[!grepl(paste(host.type, collapse = "|"), host.terms)]

  }


  # The function will drop the unused grouping variables but this should be ok.
  # There are lots of different situations where a given space has multiple grouping variables.
  if (quarters == TRUE && host.type %in% c("ccode", "iso3c", "countryname", "state", "fipscode")) {

    tempdata <- tempdata %>%
      dplyr::group_by(!!sym(host.type), year, month, quarter) %>%
      dplyr::summarise(dplyr::across(.cols = tidyselect::all_of(host.terms), ~ dplyr::first(.x)),
                       dplyr::across(dplyr::matches("_ad|_all|civilian|guard|reserve"), ~ max(.x, na.rm = TRUE)))

  } else if (quarters == FALSE && host.type %in% c("ccode", "iso3c", "countryname", "state", "fipscode")) {

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
    dplyr::mutate(dplyr::across(tidyselect::everything(),
                                ~ ifelse(is.infinite(.x), NA, .x)))

  return(tempdata)

}
