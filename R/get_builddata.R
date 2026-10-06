globalVariables(c('build_data_20260918',
                  'appn_amount', 'appn_title', 'auth_amount', 'auth_appn_amount',
                  'budget_activity', 'budget_activity_title',
                  'budget_activity_title_reported', 'classification',
                  'dollar_type', 'existing_mission', 'facility_category_code',
                  'facility_category_title', 'facility_category_title_reported',
                  'facility_group_title', 'fiscal_year', 'geo_source', 'gwcode',
                  'is_request', 'iso3c', 'latitude', 'location_code',
                  'location_full_name', 'location_name', 'location_name_reported',
                  'longitude', 'organization', 'organization_reported', 'pe',
                  'percent_recapitalization', 'project_number', 'project_title',
                  'project_title_reported', 'report_year', 'sheet_type',
                  'source_file', 'source_row', 'source_sheet', 'state_country',
                  'state_country_name', 'state_country_sort', 'toa_amount',
                  'transaction_type'))

# Internal helper. Resolves user-supplied label values against the distinct
# values actually present in one or more columns of build_data_20260918.
# Matching is case-insensitive and whitespace-insensitive; the canonical
# spelling stored in the data is returned. Unmatched values are an error rather
# than a silent zero-row result. Where several columns are given, the values of
# all of them form one pool, which is what lets a single argument search two
# levels of the same taxonomy.
bd_match_values <- function(input, data, column, arg_name) {

  choices <- unique(unlist(lapply(column, function(cl) data[[cl]]),
                           use.names = FALSE))
  choices <- choices[!is.na(choices)]

  input <- trimws(as.character(input))
  input <- input[!is.na(input) & nzchar(input)]

  if (length(input) == 0) {
    return(character(0))
  }

  idx <- match(toupper(input), toupper(choices))

  if (anyNA(idx)) {
    bad <- input[is.na(idx)]
    stop(paste0(
      "Unmatched `", arg_name, "` value", if (length(bad) > 1) "s" else "", ": ",
      paste0("\"", bad, "\"", collapse = ", "), ".\n",
      "This argument filters the ",
      paste0("`", column, "`", collapse = " and "),
      if (length(column) > 1) " columns. " else " column. ",
      "See ",
      paste0("sort(unique(troopdata::build_data_20260918$", column, "))",
             collapse = " and "),
      " for the values present in the data."
    ), call. = FALSE)
  }

  unique(choices[idx])
}

# Internal helper. Collapses one or more regular expressions into a single
# alternation pattern so that vector input behaves like the user expects
# instead of silently using only the first element.
bd_pattern <- function(x) {

  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]

  paste(x, collapse = "|")
}

#' Function to retrieve customized U.S. military construction spending data.
#'
#' @description \code{get_builddata()} subsets \code{build_data_20260918} to a customized
#' data frame containing location-project-year observations of U.S. military
#' construction and housing spending, as published in the U.S. Department of
#' Defense Comptroller Annual Report C-1 exhibits. Users can filter by host
#' country/location, organization, transaction type, facility title, budget
#' activity, project title, spending type, and amount range.
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
#'
#'   The G&W system does not assign codes to dependencies. Those locations carry
#'   the custom codes that the troop deployment data use for the same places, so
#'   one code selects a place in both data sets: Puerto Rico (\code{6},
#'   \code{"PRI"}), Greenland (\code{1002}, \code{"GRL"}), Diego Garcia
#'   (\code{1004}, \code{"IOT"}), Guam (\code{1008}, \code{"GUM"}), the Northern
#'   Mariana Islands (\code{1011}, \code{"MNP"}), the U.S. Virgin Islands
#'   (\code{1013}, \code{"VIR"}), Wake Island (\code{1014}, \code{"UMI"}),
#'   American Samoa (\code{1041}, \code{"ASM"}) and Ascension Island
#'   (\code{1042}, \code{"SHN"}). Roughly a quarter of rows report an amount but no usable location
#'   (\code{"Unspecified Worldwide Locations"} and similar) and have neither code.
#' @param location Character. A string or regular expression to match against
#'   \code{location_name} and \code{location_full_name}. Matching is
#'   case-insensitive. A vector of patterns is collapsed into a single
#'   alternation. Use \code{NA} (the default) to return all locations.
#' @param organization Character. One or more organizations to filter by, given as
#'   full names: \code{"Army"}, \code{"Navy"}, \code{"Air Force"},
#'   \code{"Defense-Wide"}, \code{"Special Operations Command"},
#'   \code{"Defense Logistics Agency"}, \code{"Defense Health Agency"},
#'   \code{"Department of Defense Education Activity"}, \code{"National Security
#'   Agency"} and other defense agencies. Matching is case-insensitive and
#'   unmatched values raise an error. Use \code{NA} (the default) to include all
#'   organizations. See \code{sort(unique(troopdata::build_data_20260918$organization))}
#'   for the full list, and \code{organization_reported} for the abbreviation
#'   each source sheet used.
#'
#'   There is no \code{"Marine Corps"} value: the C-1 exhibits carry Marine Corps
#'   construction in the Navy accounts. Guard and reserve components appear in
#'   \code{appn_title} rather than here. For FY2004-FY2007 the service of an
#'   Army, Navy or Air Force line is read from the "Treasury Agency" column of
#'   the report, which is where those workbooks print it.
#' @param transaction_type Character. One or more transaction types to include:
#'   \code{"BUDGET"}, \code{"REPROGRAM"}, \code{"REDUCTION"},
#'   \code{"CONGRESSIONAL RESCISSION"}, or \code{"PUBLIC LAW RESCISSION"}.
#'   Use \code{NA} (the default) to include all transaction types. NOTE: this
#'   field is reported for FY2001 and FY2002 only, so filtering on it restricts
#'   the result to those years.
#' @param facility_category Character. One or more facility titles to filter by,
#'   at either level of the DoD facility taxonomy: the coarse group
#'   (\code{"Operational facilities"}, \code{"Family housing operations"},
#'   \code{"Training facilities"}) or the finer three-digit category
#'   (\code{"Training buildings"}, \code{"Airfield operational buildings"},
#'   \code{"Aircraft maintenance facilities"}). Matching is case-insensitive and
#'   unmatched values raise an error. Use \code{NA} (the default) to include all
#'   facility titles.
#'
#'   A value is matched against \code{facility_group_title} and
#'   \code{facility_category_title} together, and a row is kept if either column
#'   holds it. The two columns are levels of one vocabulary and the reports do not
#'   keep them apart: the coarse labels arrive under the header "Facility Group
#'   Title" in some years, "Fiscal Category Title" in others, and in the
#'   FY2022-forward workbooks in the facility category column itself. Separating
#'   them in the data is therefore a reconstruction, and searching both is the
#'   only way to filter without having to know which header a given report year
#'   used. Three labels (\code{"Energy conservation"},
#'   \code{"Family housing P&D"}, \code{"NATO security investment program"}) are
#'   genuinely present at both levels and return rows from each.
#'
#'   See
#'   \code{sort(unique(c(troopdata::build_data_20260918$facility_group_title,
#'   troopdata::build_data_20260918$facility_category_title)))} for the 190 values
#'   present in the data. Not every row carries a facility title, so filtering on
#'   this argument drops the rest.
#' @param budget_activity Character. One or more budget activity titles to filter by
#'   (e.g., \code{"MAJOR CONSTRUCTION"}, \code{"PLANNING AND DESIGN"},
#'   \code{"LEASING"}). These labels are stored in upper case, but matching is
#'   case-insensitive. Use \code{NA} (the default) to include all budget
#'   activities. Reported for FY2001 onward.
#' @param project Character. A string or regular expression to match against
#'   \code{project_title}. Matching is case-insensitive. A vector of patterns is
#'   collapsed into a single alternation. Use \code{NA} (the default) to return
#'   all projects.
#' @param spend_type Character. The amount column used for dropping missing values
#'   and for applying \code{min_amount} / \code{max_amount}. One of:
#'   \itemize{
#'     \item \code{"all"} (default): no amount column is required to be present;
#'       amount filters are applied to \code{toa_amount}
#'     \item \code{"appn"}: appropriations (\code{appn_amount}), FY2000 onward
#'     \item \code{"auth"}: authorizations (\code{auth_amount}), FY2000 onward
#'     \item \code{"auth_appn"}: authorized for appropriation
#'       (\code{auth_appn_amount}), FY2001 onward
#'     \item \code{"toa"}: total obligational authority (\code{toa_amount}),
#'       FY2001 onward
#'   }
#'   When \code{spend_type} is not \code{"all"}, rows where the selected amount
#'   is \code{NA} are dropped. All amount columns are retained in the output in
#'   every case. Note that \code{toa_amount} is not reported for FY2000, so an
#'   amount filter with \code{spend_type = "all"} or \code{"toa"} excludes that
#'   year.
#' @param min_amount Numeric. Minimum spending amount in thousands of current US
#'   dollars. Rows below this threshold are excluded. Use \code{NA} (the default)
#'   for no lower bound.
#' @param max_amount Numeric. Maximum spending amount in thousands of current US
#'   dollars. Rows above this threshold are excluded. Use \code{NA} (the default)
#'   for no upper bound.
#' @param include_requests Logical. Each C-1 report covers two or three fiscal
#'   years, the last of them as a budget request, and the data holds every
#'   fiscal year from the most recent report that covers it. That is an enacted
#'   or actual figure for every year except FY2016, whose only report among the
#'   source files is the one that requests it. FY2010 also has 26 lines that
#'   come from an overseas contingency operations request sheet and are on no
#'   enacted sheet. \code{TRUE} (the default) returns everything, with those
#'   rows flagged by the \code{is_request} column. \code{FALSE} drops FY2016
#'   and the 26 FY2010 lines.
#' @param startyear Numeric. The first fiscal year for the series.
#' @param endyear Numeric. The last fiscal year for the series.
#'
#' @details Each fiscal year is taken whole from the most recent C-1 report that
#' covers it, so a project-year appears once. A row is one line of that report;
#' \code{source_file}, \code{source_sheet} and \code{source_row} identify it.
#'
#' Several fields appear only in a subset of years, because the C-1 exhibit
#' layout changed over time and a later report does not always print what an
#' earlier one did. \code{transaction_type} and \code{appn_title} are FY2001-FY2002
#' only; \code{pe} FY2003-FY2004; \code{dollar_type} and \code{existing_mission}
#' FY2003-FY2005; \code{location_code} FY2000-FY2006;
#' \code{facility_category_code} FY2000 and FY2003-FY2006;
#' \code{project_number} FY2000-FY2006 and FY2013 onward;
#' \code{state_country_sort} FY2006; \code{classification} FY2011 onward;
#' \code{facility_category_title} FY2003-FY2005, FY2007-FY2021 and FY2026.
#' FY2006 reports appropriations only: \code{toa_amount}, \code{auth_amount},
#' \code{auth_appn_amount} and \code{budget_activity_title} are missing for that
#' year, and \code{toa_amount} for FY2000. \code{percent_recapitalization} has no
#' values. Filtering on one of these implicitly restricts the result to the
#' years that report it.
#'
#' The \code{*_reported} columns (\code{organization_reported},
#' \code{budget_activity_title_reported}, \code{facility_category_title_reported},
#' \code{location_name_reported}, \code{project_title_reported}) preserve the
#' label exactly as printed in the source workbook, before harmonization.
#' \code{source_file}, \code{source_sheet}, \code{source_row},
#' \code{report_year}, and \code{sheet_type} record provenance and can be used to
#' trace any row back to the originating exhibit.
#'
#' \code{latitude} and \code{longitude} are present only where the location was
#' found inside the country or state the row is filed under. Rows filed under
#' no country (unspecified, worldwide and classified locations) and rows whose
#' location is a label rather than a place (\code{"Various Locations"}) have none.
#' \code{geo_source} says where a point came from: a geocoding service, or
#' \code{"manual"} for the installations the services placed at the centre of
#' the country or at another place of the same name, which are entered by hand.
#'
#' @importFrom rlang warn .data
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
#' # Kuwait and Japan, budget transactions only. transaction_type is reported
#' # for FY2001 and FY2002 only.
#' example2 <- get_builddata(
#'   host = c("KWT", "JPN"),
#'   transaction_type = "BUDGET",
#'   startyear = 2001,
#'   endyear = 2002
#' )
#'
#' # Army and Navy major construction, TOA >= $10 million
#' example3 <- get_builddata(
#'   organization = c("Army", "Navy"),
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
#'
#' # Enacted aircraft maintenance construction, excluding budget requests
#' example5 <- get_builddata(
#'   facility_category = "Aircraft maintenance facilities",
#'   include_requests = FALSE,
#'   startyear = 2010,
#'   endyear = 2024
#' )
#' }


get_builddata <- function(host = NA,
                          location = NA,
                          organization = NA,
                          transaction_type = NA,
                          facility_category = NA,
                          budget_activity = NA,
                          project = NA,
                          spend_type = "all",
                          min_amount = NA,
                          max_amount = NA,
                          include_requests = TRUE,
                          startyear,
                          endyear) {

  tempdata <- troopdata::build_data_20260918

  # Validate spend_type
  valid_spend_types <- c("all", "appn", "auth", "auth_appn", "toa")
  if (length(spend_type) != 1 || !spend_type %in% valid_spend_types) {
    stop(paste0(
      "Invalid spend_type '", paste(spend_type, collapse = ", "), "'. ",
      "Must be one of: ", paste(valid_spend_types, collapse = ", "), "."
    ))
  }

  # Validate include_requests
  if (length(include_requests) != 1 || !is.logical(include_requests) ||
      is.na(include_requests)) {
    stop("`include_requests` must be either TRUE or FALSE.")
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

  # Resolve label arguments against the values present in the data before any
  # subsetting, so that a valid label outside the requested year window returns
  # zero rows rather than raising an error.
  organization_vals <- if (!all(is.na(organization))) {
    bd_match_values(organization, tempdata, "organization", "organization")
  } else NULL

  transaction_vals <- if (!all(is.na(transaction_type))) {
    bd_match_values(transaction_type, tempdata, "transaction_type",
                    "transaction_type")
  } else NULL

  facility_category_vals <- if (!all(is.na(facility_category))) {
    bd_match_values(facility_category, tempdata,
                    c("facility_group_title", "facility_category_title"),
                    "facility_category")
  } else NULL

  budget_activity_vals <- if (!all(is.na(budget_activity))) {
    bd_match_values(budget_activity, tempdata, "budget_activity_title",
                    "budget_activity")
  } else NULL

  # Resolve host codes against the data as well.
  host_vals <- NULL
  if (!all(is.na(host))) {
    if (is.numeric(host)) {
      host_vals <- unique(host[!is.na(host)])
      unmatched <- setdiff(host_vals, unique(tempdata$gwcode))
      if (length(unmatched) > 0) {
        stop(paste0(
          "Unmatched numeric `host` code", if (length(unmatched) > 1) "s" else "",
          ": ", paste(unmatched, collapse = ", "), ".\n",
          "Numeric input is matched against Gleditsch and Ward codes ",
          "(`gwcode`). Dependencies such as Guam (1008) and Puerto Rico (6) ",
          "carry the custom codes the troop data use; see ",
          "sort(unique(troopdata::build_data_20260918$gwcode))."
        ), call. = FALSE)
      }
    } else {
      host_vals <- unique(toupper(trimws(as.character(host[!is.na(host)]))))
      unmatched <- setdiff(host_vals, unique(tempdata$iso3c))
      if (length(unmatched) > 0) {
        stop(paste0(
          "Unmatched `host` code", if (length(unmatched) > 1) "s" else "", ": ",
          paste0("\"", unmatched, "\"", collapse = ", "), ".\n",
          "Character input is matched against three-letter ISO3C codes ",
          "(`iso3c`). See sort(unique(troopdata::build_data_20260918$iso3c))."
        ), call. = FALSE)
      }
    }
  }

  warn("Spending values are in thousands of current US dollars.")
  warn("Data may include unspecified locations and zero or negative spending values.")

  # Filter by fiscal year
  tempdata <- tempdata %>%
    dplyr::filter(fiscal_year >= startyear & fiscal_year <= endyear)

  # Filter by host. Numeric input is matched against Gleditsch and Ward (G&W)
  # country codes (gwcode field); character input is matched against ISO3C
  # country codes (iso3c field, case-insensitive).
  if (length(host_vals) > 0) {
    if (is.numeric(host)) {
      tempdata <- tempdata %>%
        dplyr::filter(gwcode %in% host_vals)
    } else {
      tempdata <- tempdata %>%
        dplyr::filter(iso3c %in% host_vals)
    }
  }

  # Filter by location name (regex match against location_name and location_full_name)
  location_pattern <- if (!all(is.na(location))) bd_pattern(location) else ""
  if (nzchar(location_pattern)) {
    tempdata <- tempdata %>%
      dplyr::filter(
        grepl(location_pattern, location_name, ignore.case = TRUE) |
          grepl(location_pattern, location_full_name, ignore.case = TRUE)
      )
  }

  # Filter by organization
  if (length(organization_vals) > 0) {
    tempdata <- tempdata %>%
      dplyr::filter(organization %in% organization_vals)
  }

  # Filter by transaction type
  if (length(transaction_vals) > 0) {
    tempdata <- tempdata %>%
      dplyr::filter(transaction_type %in% transaction_vals)
  }

  # Filter by facility taxonomy. The group and category columns hold two levels
  # of the same vocabulary and the reports move labels between them, so a value
  # is matched against either one.
  if (length(facility_category_vals) > 0) {
    tempdata <- tempdata %>%
      dplyr::filter(facility_group_title %in% facility_category_vals |
                      facility_category_title %in% facility_category_vals)
  }

  # Filter by budget activity
  if (length(budget_activity_vals) > 0) {
    tempdata <- tempdata %>%
      dplyr::filter(budget_activity_title %in% budget_activity_vals)
  }

  # Filter by project title (regex match)
  project_pattern <- if (!all(is.na(project))) bd_pattern(project) else ""
  if (nzchar(project_pattern)) {
    tempdata <- tempdata %>%
      dplyr::filter(grepl(project_pattern, project_title, ignore.case = TRUE))
  }

  # Drop budget-request rows when only enacted amounts are wanted
  if (!include_requests) {
    tempdata <- tempdata %>%
      dplyr::filter(!is_request)
  }

  # Determine the amount column for spend_type filtering and min/max
  amount_col <- switch(spend_type,
    "appn"      = "appn_amount",
    "auth"      = "auth_amount",
    "auth_appn" = "auth_appn_amount",
    "toa"       = "toa_amount",
    "all"       = "toa_amount"  # min/max applied to toa_amount when spend_type = "all"
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

  if (nrow(tempdata) == 0) {
    warn("No observations match the specified arguments.")
  }

  return(tempdata)
}
