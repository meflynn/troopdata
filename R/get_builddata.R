globalVariables(c('appn_amount', 'appn_title', 'auth_amount', 'toa_amount',
                   'fiscal_year', 'state_country', 'location_name', 'location_full_name',
                   'organization', 'transaction_type', 'budget_activity_title',
                   'fiscal_category_title', 'project_title', 'latitude', 'longitude',
                   'auth_appn_amount', 'budget_activity', 'budget_activity_short_title',
                   'classification', 'construction_project', 'dollar_type',
                   'existing_footprint', 'existing_mission', 'facility_category_code',
                   'facility_category_title', 'geo_source', 'location_code', 'pe',
                   'percent_recapitalization', 'project_number', 'state_country_sort',
                   'gwcode', 'iso3c'))

#' Function to retrieve customized U.S. military construction spending data.
#'
#' @description \code{get_builddata()} generates a customized data frame containing
#' location-project-year observations of U.S. military construction and housing spending.
#' Users can filter by host country/location, organization, transaction type, fiscal
#' category, budget activity, project title, spending type, and amount range.
#'
#' @return A data frame of location-project-year observations of U.S. military
#' construction spending. Amount fields are in thousands of current US dollars.
#'
#' @param host Character or numeric. If character, the three-letter ISO3C
#'   country code (\code{iso3c} field), or a vector of such codes (e.g.,
#'   \code{c("KWT", "JPN", "DEU")} for Kuwait, Japan, and Germany). Matching is
#'   case-insensitive. If numeric, the value is treated as a Gleditsch and Ward
#'   (G&W) country code, or vector of codes (\code{gwcode} field), matched
#'   exactly. Domestic (US) construction is coded as \code{"USA"} / \code{2}.
#'   Use \code{NA} (the default) to return all locations.
#' @param location Character. A string or regular expression to match against
#'   \code{location_name} and \code{location_full_name}. Matching is case-insensitive.
#'   Use \code{NA} (the default) to return all locations.
#' @param organization Character. One or more organization codes to filter by
#'   (e.g., \code{"A"} for Army, \code{"N"} for Navy, \code{"AF"} for Air Force,
#'   \code{"D"} for Defense-Wide). Use \code{NA} (the default) to include all
#'   organizations. Common codes include: \code{"A"} (Army), \code{"N"} (Navy),
#'   \code{"AF"} (Air Force), \code{"D"} (Defense-Wide), \code{"SOCOM"},
#'   \code{"DHA"} (Defense Health Agency), \code{"DODEA"}, \code{"NSA"}.
#' @param transaction_type Character. One or more transaction types to include
#'   (e.g., \code{"BUDGET"}, \code{"REPROGRAM"}, \code{"CONGRESSIONAL RESCISSION"}).
#'   Use \code{NA} (the default) to include all transaction types.
#' @param fiscal_category Character. One or more fiscal category titles to filter by
#'   (e.g., \code{"Operational Facilities"}, \code{"Family Housing Operations"}).
#'   Use \code{NA} (the default) to include all fiscal categories.
#' @param budget_activity Character. One or more budget activity titles to filter by
#'   (e.g., \code{"MAJOR CONSTRUCTION"}, \code{"LEASING"}). Use \code{NA} (the
#'   default) to include all budget activities.
#' @param project Character. A string or regular expression to match against
#'   \code{project_title}. Matching is case-insensitive. Use \code{NA} (the default)
#'   to return all projects.
#' @param spend_type Character. The type of spending amount to use for filtering and
#'   to retain in the output. One of:
#'   \itemize{
#'     \item \code{"all"} (default): retain all amount columns
#'       (\code{appn_amount}, \code{auth_amount}, \code{toa_amount})
#'     \item \code{"appn"}: appropriations (\code{appn_amount})
#'     \item \code{"auth"}: authorizations (\code{auth_amount})
#'     \item \code{"toa"}: total obligational authority (\code{toa_amount})
#'   }
#'   When \code{spend_type} is not \code{"all"}, rows where the selected amount
#'   is \code{NA} are dropped, and \code{min_amount}/\code{max_amount} are
#'   applied to that column. When \code{spend_type = "all"}, amount filters
#'   are applied to \code{toa_amount}.
#' @param min_amount Numeric. Minimum spending amount in thousands of current US
#'   dollars. Rows below this threshold are excluded. Use \code{NA} (the default)
#'   for no lower bound.
#' @param max_amount Numeric. Maximum spending amount in thousands of current US
#'   dollars. Rows above this threshold are excluded. Use \code{NA} (the default)
#'   for no upper bound.
#' @param startyear Numeric. The first fiscal year for the series.
#' @param endyear Numeric. The last fiscal year for the series.
#'
#' @importFrom rlang warn
#' @importFrom dplyr filter
#' @export
#'
#' @author Michael E. Flynn
#'
#' @references Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2020.
#' "Outside the wire: US military deployments and public opinion in host states."
#' \emph{American Political Science Review}. 114(2): 326-341.
#'
#' @examples
#'
#' \dontrun{
#' library(troopdata)
#'
#' # All observations from 2008 through 2019
#' example <- get_builddata(startyear = 2008, endyear = 2019)
#'
#' # Kuwait and Japan, budget transactions only
#' example2 <- get_builddata(
#'   host = c("KWT", "JPN"),
#'   transaction_type = "BUDGET",
#'   startyear = 2010,
#'   endyear = 2020
#' )
#'
#' # Army and Navy major construction, TOA >= $10 million
#' example3 <- get_builddata(
#'   organization = c("A", "N"),
#'   budget_activity = "MAJOR CONSTRUCTION",
#'   spend_type = "toa",
#'   min_amount = 10000,
#'   startyear = 2015,
#'   endyear = 2023
#' )
#'
#' # Projects matching "hospital" in title
#' example4 <- get_builddata(
#'   project = "hospital",
#'   spend_type = "appn",
#'   startyear = 2010,
#'   endyear = 2023
#' )
#' }


get_builddata <- function(host = NA,
                          location = NA,
                          organization = NA,
                          transaction_type = NA,
                          fiscal_category = NA,
                          budget_activity = NA,
                          project = NA,
                          spend_type = "all",
                          min_amount = NA,
                          max_amount = NA,
                          startyear,
                          endyear) {

  tempdata <- troopdata::builddata

  # Validate spend_type
  valid_spend_types <- c("all", "appn", "auth", "toa")
  if (!spend_type %in% valid_spend_types) {
    stop(paste0(
      "Invalid spend_type '", spend_type, "'. ",
      "Must be one of: ", paste(valid_spend_types, collapse = ", "), "."
    ))
  }

  # Validate year range
  data_min_year <- min(tempdata$fiscal_year, na.rm = TRUE)
  data_max_year <- max(tempdata$fiscal_year, na.rm = TRUE)

  if (startyear < data_min_year | endyear > data_max_year) {
    stop(paste0(
      "Specified year is out of range. ",
      "Available range is ", data_min_year, " through ", data_max_year, "."
    ))
  }

  warn("Spending values are in thousands of current US dollars.")
  warn("Data may include unspecified locations and zero or negative spending values.")

  # Filter by fiscal year
  tempdata <- tempdata %>%
    dplyr::filter(fiscal_year >= startyear & fiscal_year <= endyear)

  # Filter by host. Numeric input is matched against Gleditsch and Ward (G&W)
  # country codes (gwcode field); character input is matched against ISO3C
  # country codes (iso3c field, case-insensitive).
  if (!all(is.na(host))) {
    if (is.numeric(host)) {
      host <- c(host)
      tempdata <- tempdata %>%
        dplyr::filter(gwcode %in% host)
    } else {
      host <- toupper(c(host))
      tempdata <- tempdata %>%
        dplyr::filter(iso3c %in% host)
    }
  }

  # Filter by location name (regex match against location_name and location_full_name)
  if (!all(is.na(location))) {
    tempdata <- tempdata %>%
      dplyr::filter(
        grepl(location, location_name, ignore.case = TRUE) |
          grepl(location, location_full_name, ignore.case = TRUE)
      )
  }

  # Filter by organization
  if (!all(is.na(organization))) {
    organization <- c(organization)
    tempdata <- tempdata %>%
      dplyr::filter(organization %in% !!organization)
  }

  # Filter by transaction type
  if (!all(is.na(transaction_type))) {
    transaction_type <- c(transaction_type)
    tempdata <- tempdata %>%
      dplyr::filter(transaction_type %in% !!transaction_type)
  }

  # Filter by fiscal category
  if (!all(is.na(fiscal_category))) {
    fiscal_category <- c(fiscal_category)
    tempdata <- tempdata %>%
      dplyr::filter(fiscal_category_title %in% fiscal_category)
  }

  # Filter by budget activity
  if (!all(is.na(budget_activity))) {
    budget_activity <- c(budget_activity)
    tempdata <- tempdata %>%
      dplyr::filter(budget_activity_title %in% budget_activity)
  }

  # Filter by project title (regex match)
  if (!all(is.na(project))) {
    tempdata <- tempdata %>%
      dplyr::filter(grepl(project, project_title, ignore.case = TRUE))
  }

  # Determine the amount column for spend_type filtering and min/max
  amount_col <- switch(spend_type,
    "appn" = "appn_amount",
    "auth" = "auth_amount",
    "toa"  = "toa_amount",
    "all"  = "toa_amount"  # min/max applied to toa_amount when spend_type = "all"
  )

  # Drop rows with NA in the selected amount column when a specific spend_type is chosen
  if (spend_type != "all") {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(.data[[amount_col]]))
  }

  # Apply min/max amount filters
  if (!is.na(min_amount)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(.data[[amount_col]]) & .data[[amount_col]] >= min_amount)
    if (spend_type == "all") {
      warn("min_amount and max_amount are applied to toa_amount when spend_type = 'all'.")
    }
  }

  if (!is.na(max_amount)) {
    tempdata <- tempdata %>%
      dplyr::filter(!is.na(.data[[amount_col]]) & .data[[amount_col]] <= max_amount)
  }

  return(tempdata)
}
