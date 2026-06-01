globalVariables(c('MMEID', 'Ex_Name', 'Series_Name', 'Location', 'lat', 'lon',
                  'StartDate', 's.year', 's.month', 's.day',
                  'EndDate', 'e.year', 'e.month', 'e.day',
                  'CPX', 'Air', 'Land', 'Sea', 'Amphibious', 'Cyber',
                  'Warfighting', 'Peacekeeping', 'Humanitarian',
                  'FocusDescription', 'AdditionalParticipantInfo',
                  'country', 'gwcode', 'year', 'duration', 'participant_count',
                  'start_date_parsed', 'end_date_parsed', '.data'))

#' Function to retrieve customized multilateral military exercise data
#'
#' @description \code{get_exercises()} generates a customized data frame
#'   containing exercise-country-year observations of multilateral military
#'   exercises. Users can subset the data by participating country, year,
#'   exercise duration, geographic location, exercise name, the
#'   domain(s) of the exercise (e.g., air, land, sea), the mission focus
#'   (warfighting, humanitarian, peacekeeping), and the number of
#'   participating countries.
#'
#' @return \code{get_exercises()} returns a data frame containing
#'   exercise-country-year observations of multilateral military exercises
#'   that match the specified filter criteria.
#'
#' @param country The Gleditsch and Ward (G&W) numeric country code or country
#'   name for the participating country or countries to include. Numeric input
#'   is matched exactly against the \code{gwcode} column. Character input is
#'   matched against the \code{country} column using a case-insensitive
#'   \code{grepl} fuzzy match, so partial names are accepted (e.g.,
#'   "korea" returns both Koreas). Multiple values can be supplied as a vector.
#'   The default is NULL, which returns all participating countries.
#' @param startyear The first year for the series. The default is set to
#'   the minimum year in the currently published data.
#' @param endyear The last year for the series. The default is the maximum
#'   year in the currently published data.
#' @param min_duration Numeric. Minimum exercise duration in days (inclusive).
#'   Default is NULL (no minimum filter).
#' @param max_duration Numeric. Maximum exercise duration in days (inclusive).
#'   Default is NULL (no maximum filter).
#' @param location Character. A string or vector of strings used to subset
#'   exercises by geographic location. Matched against the \code{Location}
#'   column with a case-insensitive \code{grepl} fuzzy match. Default is NULL.
#' @param exercise_name Character. A string or vector of strings used to
#'   subset exercises by name. Matched against both the \code{Ex_Name} and
#'   \code{Series_Name} columns with a case-insensitive \code{grepl} fuzzy
#'   match (e.g., "cobra" matches "Cobra Gold"). Default is NULL.
#' @param domain Character. A string or vector of strings indicating one or
#'   more exercise domains (warfighting environments) to include. Accepted
#'   values are \code{"air"}, \code{"land"}, \code{"sea"},
#'   \code{"amphibious"}, and \code{"cyber"}. Matching is case-insensitive.
#'   An exercise is returned if it is flagged for any of the supplied
#'   domains (logical OR). Default is NULL, which returns all domains.
#' @param focus Character. A string or vector of strings indicating one or
#'   more mission focuses to include. Accepted values are
#'   \code{"warfighting"}, \code{"humanitarian"}, and \code{"peacekeeping"}.
#'   Matching is case-insensitive. An exercise is returned if it is flagged
#'   for any of the supplied focuses (logical OR). Default is NULL, which
#'   returns all mission focuses.
#' @param min_participants Numeric. Minimum number of participating countries
#'   in the exercise (inclusive). Default is NULL (no minimum filter).
#' @param max_participants Numeric. Maximum number of participating countries
#'   in the exercise (inclusive). Default is NULL (no maximum filter).
#'
#' @importFrom rlang warn
#' @importFrom dplyr filter mutate if_any all_of
#' @export
#'
#' @author Michael E. Flynn
#'
#' @references
#' D'Orazio, Vito; Galambos, Kevin, 2021, "Multinational Military Exercises, 1980-2010", https://doi.org/10.7910/DVN/KHFODX, Harvard Dataverse, V1.
#'
#' Gleditsch, Kristian S., and Michael D. Ward. 1999. "Interstate System
#' Membership: A Revised List of the Independent States since 1816."
#' \emph{International Interactions} 25(4): 393-413.
#'
#' @examples
#'
#' \dontrun{
#' library(tidyverse)
#' library(troopdata)
#'
#' # Pull all exercises that include South Korea between 2000 and 2015.
#' korea_exercises <- get_exercises(country = "korea",
#'                                  startyear = 2000,
#'                                  endyear = 2015)
#'
#' # Pull all naval and amphibious exercises lasting at least 5 days.
#' sea_exercises <- get_exercises(domain = c("sea", "amphibious"),
#'                                min_duration = 5)
#'
#' # Pull all "Cobra Gold" exercises in Thailand.
#' cobra_gold <- get_exercises(exercise_name = "cobra gold",
#'                             location = "thailand")
#'
#' # Pull large-scale humanitarian exercises (10 or more participants).
#' large_hadr <- get_exercises(focus = "humanitarian",
#'                             min_participants = 10)
#' }


get_exercises <- function(country = NULL,
                          startyear = NULL,
                          endyear = NULL,
                          min_duration = NULL,
                          max_duration = NULL,
                          location = NULL,
                          exercise_name = NULL,
                          domain = NULL,
                          focus = NULL,
                          min_participants = NULL,
                          max_participants = NULL) {


  # Pull the long-format multilateral military exercises data.
  tempdata <- troopdata::mme_long


  # Set warnings/defaults for the year range. Mirrors the structure used in
  # get_troopdata() so the function can complete even if the user passes a
  # year that falls outside the available range.
  data_min_year <- min(tempdata$year, na.rm = TRUE)
  data_max_year <- max(tempdata$year, na.rm = TRUE)

  if (is.null(startyear)) startyear <- data_min_year
  if (is.null(endyear))   endyear   <- data_max_year

  if (startyear < data_min_year || endyear > data_max_year) {
    rlang::warn(paste0("Specified year is out of range. Available range includes ",
                       data_min_year, " through ", data_max_year, "."))
  }
  if (startyear < data_min_year) startyear <- data_min_year
  if (endyear   > data_max_year) endyear   <- data_max_year


  # ---- Country filter --------------------------------------------------------
  # Determine whether the user is searching by Gleditsch and Ward numeric
  # country code or by country name. Country names use grepl-based fuzzy
  # matching (case-insensitive), mirroring the convention used in
  # get_troopdata(). Note: the data column is also named `country`, so the
  # function argument has to be copied to a differently-named local
  # (`country.input`) before being passed into dplyr::filter() -- otherwise
  # dplyr's data mask resolves `country` to the column, not the argument,
  # and the gwcode branch silently filters down to zero rows.
  if (is.numeric(country)) {

    country.type  <- "gwcode"
    country.input <- country

    tempdata <- tempdata %>%
      dplyr::filter(gwcode %in% country.input)

  } else if (is.character(country)) {

    country.type    <- "country"
    country.pattern <- paste(country, collapse = "|")

    tempdata <- tempdata %>%
      dplyr::filter(grepl(country.pattern,
                          .data$country,
                          ignore.case = TRUE))

  }


  # ---- Year filter -----------------------------------------------------------
  tempdata <- tempdata %>%
    dplyr::filter(year >= startyear & year <= endyear)


  # ---- Duration filter -------------------------------------------------------
  # Compute exercise duration in days from the start and end dates if a
  # duration column is not already present. We try to coerce StartDate and
  # EndDate to Date objects; rows with unparseable dates (e.g., values like
  # "1980-01-xx") will produce NA and be excluded only when a duration filter
  # is supplied.
  if (!"duration" %in% names(tempdata)) {

    tempdata <- tempdata %>%
      dplyr::mutate(
        start_date_parsed = suppressWarnings(as.Date(StartDate,
                                                     tryFormats = c("%Y-%m-%d", "%m/%d/%y", "%m/%d/%Y"),
                                                     optional   = TRUE)),
        end_date_parsed   = suppressWarnings(as.Date(EndDate,
                                                     tryFormats = c("%Y-%m-%d", "%m/%d/%y", "%m/%d/%Y"),
                                                     optional   = TRUE)),
        duration = as.numeric(end_date_parsed - start_date_parsed)
      ) %>%
      dplyr::select(-start_date_parsed, -end_date_parsed)
  }

  if (!is.null(min_duration)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(duration) & duration >= min_duration)
  }

  if (!is.null(max_duration)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(duration) & duration <= max_duration)
  }


  # ---- Location filter -------------------------------------------------------
  if (!is.null(location) && is.character(location)) {

    tempdata <- tempdata %>%
      dplyr::filter(grepl(paste(location, collapse = "|"),
                          Location,
                          ignore.case = TRUE))
  }


  # ---- Exercise name filter --------------------------------------------------
  # Match against both Ex_Name and Series_Name so users can target individual
  # exercises (e.g., "Cobra Gold 23") or whole exercise series ("Cobra Gold").
  if (!is.null(exercise_name) && is.character(exercise_name)) {

    name_pattern <- paste(exercise_name, collapse = "|")

    tempdata <- tempdata %>%
      dplyr::filter(grepl(name_pattern, Ex_Name,     ignore.case = TRUE) |
                    grepl(name_pattern, Series_Name, ignore.case = TRUE))
  }


  # ---- Exercise domain filter ------------------------------------------------
  # Domains describe the warfighting environment of the exercise. The MME
  # data flags these using binary 0/1 columns: Air, Land, Sea, Amphibious,
  # and Cyber. Map user-supplied lowercase domain names to those columns and
  # keep any exercise flagged for at least one of them.
  if (!is.null(domain) && is.character(domain)) {

    domain.map <- c(
      air        = "Air",
      land       = "Land",
      sea        = "Sea",
      amphibious = "Amphibious",
      cyber      = "Cyber"
    )

    domain.requested <- tolower(trimws(domain))
    domain.unknown   <- domain.requested[!domain.requested %in% names(domain.map)]

    if (length(domain.unknown) > 0) {
      rlang::warn(paste0("Unknown exercise domain(s) ignored: ",
                         paste(domain.unknown, collapse = ", "),
                         ". Accepted values: ",
                         paste(names(domain.map), collapse = ", "), "."))
    }

    domain.cols <- unname(domain.map[domain.requested[domain.requested %in% names(domain.map)]])

    if (length(domain.cols) > 0) {
      tempdata <- tempdata %>%
        dplyr::filter(dplyr::if_any(dplyr::all_of(domain.cols),
                                    ~ !is.na(.x) & .x == 1))
    }
  }


  # ---- Exercise focus filter -------------------------------------------------
  # Focus describes the mission purpose of the exercise. The MME data flags
  # these using binary 0/1 columns: Warfighting, Humanitarian, and
  # Peacekeeping. Map user-supplied lowercase focus names to those columns
  # and keep any exercise flagged for at least one of them.
  if (!is.null(focus) && is.character(focus)) {

    focus.map <- c(
      warfighting  = "Warfighting",
      humanitarian = "Humanitarian",
      peacekeeping = "Peacekeeping"
    )

    focus.requested <- tolower(trimws(focus))
    focus.unknown   <- focus.requested[!focus.requested %in% names(focus.map)]

    if (length(focus.unknown) > 0) {
      rlang::warn(paste0("Unknown exercise focus(es) ignored: ",
                         paste(focus.unknown, collapse = ", "),
                         ". Accepted values: ",
                         paste(names(focus.map), collapse = ", "), "."))
    }

    focus.cols <- unname(focus.map[focus.requested[focus.requested %in% names(focus.map)]])

    if (length(focus.cols) > 0) {
      tempdata <- tempdata %>%
        dplyr::filter(dplyr::if_any(dplyr::all_of(focus.cols),
                                    ~ !is.na(.x) & .x == 1))
    }
  }


  # ---- Participant count filter ----------------------------------------------
  # Filter on the participant_count column that ships with mme_long. This is
  # a precomputed total of the participating countries for each exercise
  # (the same value is repeated across all rows that share an MMEID), so we
  # can filter directly without recomputing from the data.
  if (!is.null(min_participants)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(participant_count) & participant_count >= min_participants)
  }

  if (!is.null(max_participants)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(participant_count) & participant_count <= max_participants)
  }


  return(tempdata)

}
