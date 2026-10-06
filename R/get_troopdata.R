globalVariables(c('ccode', 'iso3c', 'countryname', 'state', 'fipscode', 'region', 'year', 'month', 'quarter', 'source', 'location', 'troops_ad', 'army_ad', 'army', 'navy_ad', 'air_force_ad', 'marine_corps_ad', 'coast_guard_ad', 'space_force_ad', 'troops_afloat', 'navy_afloat', 'marine_corps_afloat', 'army_national_guard', 'air_national_guard', 'army_reserve', 'navy_reserve', 'marine_corps_reserve', 'air_force_reserve', 'coast_guard_reserve', 'total_selected_reserve', 'army_civilian', 'navy_civilian', 'marine_corps_civilian', 'air_force_civilian' , 'dod_civilian', 'total_civilian', 'Total', 'Total Ashore', 'Total Afloat', 'Army Total', 'Navy Total', 'Marine Corps Total', 'Air Force Total', 'Coast Guard Total', 'Space Force Total', 'Army National Guard Total', 'Air National Guard Total', 'Army Reserve Total', 'Navy Reserve Total', 'Marine Corps Reserve Total', 'Air Force Reserve Total', 'Coast Guard Reserve Total', 'Total Selected Reserve Total', 'Army Civilian Total', 'Navy Civilian Total', 'Marine Corps Civilian Total', 'Air Force Civilian Total', 'DoD Civilian Total', 'Total Civilian Total', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian', 'Marine Corps Civilian', 'Air Force Civilian', 'DoD Civilian', 'Total Civilian', 'Total Selected Reserve', 'Army National Guard', 'Air National Guard', 'Army Reserve', 'Navy Reserve', 'Marine Corps Reserve', 'Air Force Reserve', 'Coast Guard Reserve', 'Total Selected Reserve', 'Army Civilian', 'Navy Civilian'))

# Largest reported value in a period, or NA when nothing was reported for it.
#
# max(x, na.rm = TRUE) on an all-NA group returns -Inf and raises "no non-missing arguments to max".
# The -Inf was cleaned up further down, but the warning still reached the user on any query covering
# a country-period with no reported values, for example a branch = TRUE query spanning 2003-2004.
#
# Internal: not exported, and documented with plain `#` comments rather than `#'` ones. It sits
# ABOVE the roxygen block below on purpose. roxygen2 attaches a block to the next object it finds,
# so defining this between that block and get_troopdata() handed get_troopdata()'s title, @param
# tags and @export to max_reported(): get_troopdata() silently stopped being exported and lost its
# help page, while max_reported() got an Rd file documenting arguments it does not have. Put a new
# helper here or after get_troopdata(), never in between.
max_reported <- function(x) {

  if (all(is.na(x))) {
    return(NA_real_)
  }

  max(x, na.rm = TRUE)

}


# Applies the `afloat` argument of get_troopdata() to the country-year data or the reports.
#
# Both carry, for 1950 through 2007, the personnel afloat a report attributes to a location in
# troops_afloat, navy_afloat and marine_corps_afloat, beside troops_ad, navy_ad and
# marine_corps_ad, which are personnel ashore. The row for personnel afloat worldwide (country
# code 10200) holds everyone afloat, those attributed to a location included.
#
#   "exclude"   leaves the figures as stored and drops the three afloat columns.
#   "include"   adds each location's afloat personnel to its totals and drops the three columns.
#   "separate"  keeps the three columns beside the ashore figures.
#
# With "include" and "separate" the attributed personnel are also taken out of the worldwide row,
# report by report, so that it holds only personnel afloat who are attributed to no location and
# nobody appears twice. Summed over every row, the three choices give the same total.
#
# Internal, and above the roxygen block for the reason given at max_reported().
resolve_afloat <- function(data, afloat) {

  afloat.columns <- c("troops_afloat", "navy_afloat", "marine_corps_afloat")

  # The state data has none of these columns. It starts in 2008, when the reports count a ship's
  # crew at its home port and there is no afloat figure to treat one way or another.
  if (!all(afloat.columns %in% names(data))) {
    return(data)
  }

  data <- dplyr::ungroup(data)

  if (afloat == "exclude") {
    return(dplyr::select(data, -dplyr::all_of(afloat.columns)))
  }

  worldwide <- !is.na(data$ccode) & data$ccode == 10200
  period <- paste(data$year, data$month, data$quarter)

  # A location's attributed figure, with missing read as none and the worldwide row left out.
  attributed <- function(column) {
    ifelse(worldwide | is.na(data[[column]]), 0, data[[column]])
  }

  # The same figure added up over every location in a report, repeated on each of its rows.
  placed <- function(column) {
    totals <- tapply(attributed(column), period, sum)
    as.numeric(totals[period])
  }

  placed.navy <- placed("navy_afloat")
  placed.marine.corps <- placed("marine_corps_afloat")

  before <- data$troops_ad[worldwide]

  data$navy_ad[worldwide] <- pmax(data$navy_ad[worldwide] - placed.navy[worldwide], 0)
  data$marine_corps_ad[worldwide] <- pmax(data$marine_corps_ad[worldwide] -
                                             placed.marine.corps[worldwide], 0)
  data$troops_ad[worldwide] <- pmax(before - placed.navy[worldwide] -
                                      placed.marine.corps[worldwide], 0)

  if ("troops_all" %in% names(data)) {
    data$troops_all[worldwide] <- data$troops_all[worldwide] + (data$troops_ad[worldwide] - before)
  }

  if (afloat == "include") {

    data$navy_ad <- data$navy_ad + attributed("navy_afloat")
    data$marine_corps_ad <- data$marine_corps_ad + attributed("marine_corps_afloat")
    data$troops_ad <- data$troops_ad + attributed("troops_afloat")

    if ("troops_all" %in% names(data)) {
      data$troops_all <- data$troops_all + attributed("troops_afloat")
    }

    data <- dplyr::select(data, -dplyr::all_of(afloat.columns))

  }

  data

}

# Notes for a character `host` that looks like a region but will not return one whole region.
#
# `host` is tried as a country name before it is tried as a region, and both are substring
# matches. So a string that is part of a region's name can do two things a user asking for a
# region does not expect: it can be read as a country, because it is also part of a country name
# ("Africa" is in "South Africa", "America" in "American Samoa"), or it can match several regions
# at once ("Asia" is in three of them). A note is returned for those two cases and for no other:
# a full region name, a string that matches exactly one region, and a country name that merely
# shares a word with a region ("South Africa") are all left alone. The note names what the
# string actually matched, read from the data, so it cannot go out of date.
#
# `countrynames` and `region.labels` are the distinct names in the data; `host.type` is how the
# whole `host` argument was read.
region_host_notes <- function(host, host.type, countrynames, region.labels) {

  countrynames <- sort(unique(countrynames[!is.na(countrynames)]))
  region.labels <- sort(unique(region.labels[!is.na(region.labels)]))

  quoted <- function(x) paste0("'", x, "'", collapse = ", ")

  listed <- function(x, most = 6) {
    if (length(x) > most) {
      paste0(paste(x[seq_len(most)], collapse = ", "), " and ", length(x) - most, " more")
    } else {
      paste(x, collapse = ", ")
    }
  }

  notes <- character()

  for (h in unique(host)) {

    regions.matched <- region.labels[grepl(h, region.labels, ignore.case = TRUE)]

    # Not part of any region's name, or the name of a location in its own right ("Afloat" and
    # "Antarctica" are both a location and the region that holds it).
    if (length(regions.matched) == 0 || tolower(h) %in% tolower(countrynames)) next

    if (host.type == "countryname") {

      countries.matched <- countrynames[grepl(h, countrynames, ignore.case = TRUE)]

      if (length(countries.matched) > 0) {
        notes <- c(notes, paste0(
          "`host` value '", h, "' was read as a country name, not as a region, because it is ",
          "part of ", if (length(countries.matched) == 1) "a country name" else "country names",
          ". The only ", if (length(countries.matched) == 1) "name it matches is " else
            "names it matches are ", listed(countries.matched),
          ". To get a region, give its full name: ", quoted(regions.matched), "."))
      } else {
        notes <- c(notes, paste0(
          "`host` value '", h, "' matched no country name and returned nothing. The other ",
          "values in `host` were read as country names, and a region cannot be combined with ",
          "country names in one call."))
      }

    } else if (host.type == "region" && length(regions.matched) > 1 &&
               !tolower(h) %in% tolower(region.labels)) {

      notes <- c(notes, paste0(
        "`host` value '", h, "' is not the full name of a region and matched ",
        length(regions.matched), " of them: ", quoted(regions.matched), ". The locations of ",
        "all ", length(regions.matched), " were returned. Give a full name to get one region."))

    }

  }

  notes

}


#' Function to retrieve customized U.S. troop deployment data
#'
#' @description \code{get_troopdata()} generates a customized data frame containing country-year observations of U.S. military deployments overseas.
#'
#' @return \code{get_troopdata()} returns a data frame containing country-year observations for U.S. troop deployments.
#'
#' @param host The Correlates of War (COW) numeric country code, ISO3C code, or country name, for the host country or countries in the series. A region name can be given instead; see below. The default, \code{NULL}, returns every location, and so does \code{NA}. A missing value inside a vector of hosts is dropped with a warning.
#'
#'   A region is asked for by name. \code{host} is matched, as a substring and ignoring case,
#'   against the \code{region} column (\code{unique(get_troopdata()$region)} lists the names), and
#'   every location in a matching region is returned, one row per location and period, exactly as
#'   a query with no \code{host} returns them. Nothing is added up; the \code{region} column says
#'   which region each row belongs to. A string that matches several regions returns the locations
#'   of each: \code{"Asia"} matches \code{"East Asia & Pacific"}, \code{"South Asia"} and
#'   \code{"Europe & Central Asia"}. A string that matches a country name is read as a country, so
#'   \code{"Africa"} returns South Africa and the Central African Republic and \code{"America"}
#'   returns American Samoa; give enough of the region's name to tell them apart
#'   (\code{"Sub-Saharan Africa"}, \code{"North America"}). In both of these cases a warning
#'   says what the string matched. A full region name, or a string that matches one region
#'   only, raises none.
#'
#'   A country name is matched as a substring, so a query reaches every historical form of a
#'   divided country: \code{"Korea"} returns North and South, \code{"Vietnam"} returns North, South
#'   and the unified state, \code{"Czech"} returns Czechoslovakia and the Czech Republic.
#'   \code{"Germany"} returns both the Federal Republic (260) and the German Democratic Republic
#'   (265); \code{"West Germany"} and \code{"East Germany"} reach them individually. Where a name
#'   spans several country codes the rows are returned separately, one per code and period, and a
#'   warning says which codes matched -- aggregate across \code{ccode} for a single national series.
#'
#'   Note that matching on ISO3C codes cannot reach every location in the data. A few locations
#'   have no ISO3C code and are left out of any ISO3C filter: at present the British West Indies
#'   (1950-1965), the Spratly Islands and Kashmir. Passing \code{host} as a
#'   country name or a Gleditsch and Ward country code reaches them, and a warning names them and
#'   gives the current count whenever an ISO3C filter is used. Most territories and historical
#'   states do have a code: Greenland is \code{"GRL"}, Bermuda \code{"BMU"}, Diego Garcia
#'   \code{"IOT"} and Yugoslavia \code{"YUG"}. A unit with no code of its own carries its
#'   parent's: the Azores carry Portugal's, \code{"PRT"}. Locations that share a code are returned
#'   on rows of their own, so \code{host = "PRT"} returns Portugal and the Azores separately, each
#'   with its own country code. Add them up to get a total for the ISO3C code.
#'
#'   Personnel afloat have a location of their own, named \code{"Afloat"} (country code 10200,
#'   no ISO3C code, region \code{"Afloat"}), with values for 1950 and 1953 through 2007. It is
#'   returned with everything else when \code{host} is left empty; \code{host = "Afloat"} or
#'   \code{host = 10200} returns it alone. It is not a country, so leave it out when adding up
#'   countries. See \code{afloat} for what it holds.
#' @param startyear The first year for the series. The default is set to 1950.
#' @param endyear The last year for the series. The default is the maximum year in the currently published data.
#' @param branch Logical. Should the function return a single vector containing total troop values or multiple vectors containing total values and values for individual branches? Default is FALSE.
#' @param guard_reserve Logical. Should the function return values for the National Guard and Reserve? Default is FALSE.
#' @param civilians Logical. Should the function return values for civilian DoD personnel? Default is FALSE.
#' @param quarters Logical. Should the function return quarterly data? Default is FALSE.
#' @param reports Logical. Should the function return reports for the specified countries and years? Default is FALSE. The reports are returned as reported, without aggregation, so a country code may appear on more than one row in a period where the report breaks that country's territories out separately.
#' @param state_data Logical. Should the function return disaggregated data on US States? Default is FALSE.
#' @param afloat How to treat Navy and Marine Corps personnel afloat in the reports for 1950
#'   through 2007. One of \code{"exclude"} (the default), \code{"include"} or
#'   \code{"separate"}.
#'
#'   Those reports count personnel ashore and personnel afloat separately, and attribute some of
#'   the personnel afloat to a location: to the country of the nearest port or the country whose
#'   line they are printed on (1953-1976), and, for the fleet in home waters, to the United States
#'   (1950, 1953-2007; from 1968 the reports give that figure for the United States and its
#'   territories together). The rest are given for a region or for the world only.
#'
#'   \itemize{
#'     \item \code{"exclude"}: every location holds personnel ashore. \code{troops_ad},
#'       \code{navy_ad} and \code{marine_corps_ad} leave out anyone afloat, and the
#'       \code{"Afloat"} location holds everyone afloat worldwide.
#'     \item \code{"include"}: personnel afloat who are attributed to a location are added to
#'       that location's \code{troops_ad}, \code{navy_ad} and \code{marine_corps_ad}. The
#'       \code{"Afloat"} location holds only those attributed to no location.
#'     \item \code{"separate"}: the figures ashore are as for \code{"exclude"}, and the
#'       personnel afloat attributed to each location are returned beside them in
#'       \code{troops_afloat}, \code{navy_afloat} and \code{marine_corps_afloat}.
#'       \code{navy_ad} and \code{marine_corps_ad} are returned as well, whatever \code{branch}
#'       is set to, so the two can be compared. The \code{"Afloat"} location holds only those
#'       attributed to no location.
#'   }
#'
#'   Added up over every row, the three give the same total; they differ in where the personnel
#'   afloat are put. In the three afloat columns a zero means a report that lists personnel afloat
#'   by location has none for that one (1953-1976). A missing value means the report gives no
#'   figure for the location: 1950 and 1977-2007 for everywhere but the United States, 1951 and
#'   1952, and every year from 2008. For 1954-1956 the figure also holds mobile units temporarily
#'   based ashore, which those three reports do not separate.
#'
#'   From September 2008 the DMDC reports count a ship's crew at its home port, inside the state
#'   or country figure, and there is no afloat figure at all, so the argument changes nothing from
#'   2008 on and has no effect on \code{state_data = TRUE}. Navy figures on either side of 2008
#'   are closest to comparable with \code{afloat = "include"}.
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
                          endyear = 2026,            # Update year to present
                          quarters = FALSE,
                          guard_reserve = FALSE,
                          civilians = FALSE,
                          state_data = FALSE,
                          reports = FALSE,
                          afloat = c("exclude", "include", "separate")) {

  afloat <- match.arg(afloat)

  # A missing host means no host. get_builddata() and get_basedata() take host = NA for "every
  # location", and this function's own help and warnings used to suggest it, but NA matched none
  # of the branches below and the call failed with "object 'host.type' not found". A missing value
  # inside a vector of hosts was worse: pasted into the search pattern it became the text "NA",
  # which is part of China, Ghana, Canada and many other names, so c("Japan", NA) returned
  # eighteen countries for 2000. Missing values are dropped here, before anything looks at host.
  if (!is.null(host)) {

    if (anyNA(host) && !all(is.na(host))) rlang::warn("Missing values in `host` were ignored.")

    host <- host[!is.na(host)]

    if (length(host) == 0) host <- NULL

  }


  # First determine if we're using reports, state_data, or long data format. This depends on reports argument being TRUE or FALSE.
  # Have to include this chunk first so the following if statements can evaluate the temp data object.
  if(reports == TRUE) {

    tempdata <- troopdata::troopdata_rebuild_reports

  } else if (state_data == TRUE) {

    tempdata <- troopdata::troopdata_rebuild_us_states

  }  else {

    tempdata <- troopdata::troopdata_rebuild_long

    }

  # Personnel afloat: leave them out of the locations, add them in, or keep them beside the
  # ashore figures. Done before any filtering, because taking the attributed personnel out of the
  # worldwide row needs every location in the report, not only the ones `host` asks for.
  tempdata <- resolve_afloat(tempdata, afloat)


  # Set warning for year range and assign default values to allow the function complete
  if(startyear < 1950 | endyear > max(tempdata$year)) warn(paste0("Specified year is out of range. Available range includes 1950 through ", max(tempdata$year), "."))
  if(startyear < 1950) startyear <- 1950
  if(endyear > max(tempdata$year)) endyear <- max(tempdata$year)

  # The warning for a `host` that looks like a region but will not return one whole region is
  # raised further down, once it is known how `host` was read; see region_host_notes().

  # Set warning for branch and guard_reserve values.
  if(branch)  rlang::warn("Branch data only includes active duty by default. This preserves continuity across time periods as guard and reserve data are not reported prior to 2008. Also note that Iraq does not have branch data for 2003-2007 and troops_ad value is estimated using alternative sources.")
  if(guard_reserve) rlang::warn("Guard and Reserve data only available for 2008 forward. Values will display as NA for earlier time periods.")
  if(quarters) rlang::warn("Some service branches do not report data for all quarters. See the following note from December, 2022, June 2023, and March 2023 DMDC reports: 'The Army is converting its Integrated Personnel and Pay System (IPPS-A) and so the Army did not provide military personnel data for end-of-June 2023.' We use a stepwise imputation process to fill in the Army values between September 2022 and September 2023, taking the difference between the values for these two periods and incrementally adjusting the Army figures for the missing periods between. The other services reported for those quarters and their values are shown as reported; totals are the sum of the two.")
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
                        # The two German states are stored under their formal names, so the forms a
                        # user is most likely to type need pointing at them. Plain "Germany" is
                        # handled by the group alias in the countryname branch below, which returns
                        # both.
                        "east germany" = "German Democratic Republic",
                        "west germany" = "Federal Republic of Germany",
                        "cote d'ivoire" = "Ivory Coast",
                        "c\u00f4te d'ivoire" = "Ivory Coast",
                        "turkiye" = "Turkey",
                        "t\u00fcrkiye" = "Turkey",
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

    # Set warning for host region call. Only for a string that is part of a region's name and
    # was either read as a country ("Africa", "America") or matched several regions ("Asia").
    if (is.character(host) && host.type %in% c("countryname", "region")) {

      region.notes <- region_host_notes(host, host.type,
                                        c(canonical$countryname, tempdata$countryname),
                                        c(canonical$region, tempdata$region))

      if (length(region.notes) > 0) rlang::warn(paste(region.notes, collapse = " "))

    }

    # Filter by host type using if/else instead of case_when
    if (host.type == "ccode") {

      # A numeric host that matches no country code used to return an empty data frame with no
      # explanation. The usual cause is a Correlates of War code: Germany is 255 there and 260 in
      # the Gleditsch and Ward list this package uses.
      unmatched.codes <- setdiff(host, tempdata$ccode)

      if (length(unmatched.codes) > 0 && !any(host %in% tempdata$ccode)) {
        stop(paste0("`host` code(s) ", paste(unmatched.codes, collapse = ", "),
                    " did not match any country code in the data. Numeric `host` values are ",
                    "matched against Gleditsch and Ward codes, which differ from Correlates of ",
                    "War codes for some states (Germany is 260, not 255)."),
             call. = FALSE)
      } else if (length(unmatched.codes) > 0) {
        rlang::warn(paste0("`host` code(s) ", paste(unmatched.codes, collapse = ", "),
                           " did not match any country code in the data and were ignored."))
      }

      tempdata <- tempdata %>%
        dplyr::filter(ccode %in% host)
    } else if (host.type == "iso3c") {

      # Not every entity in the data carries an ISO3C code, so an ISO3C filter cannot reach all of
      # them. Those rows hold iso3c = NA and are invisible to this branch. The gap used to fall on
      # places with large deployments (Greenland, Bermuda, the Azores, Diego Garcia, Yugoslavia);
      # the build now gives those a code, and what is left is small: the British West Indies of
      # 1950-1965, the Spratly Islands and Kashmir.
      #
      # The figures are computed from the data at call time rather than written into the message, so
      # the warning stays accurate, shrinks as codes are filled in, and stops firing altogether once
      # none are missing.
      #
      # Personnel afloat (10200) are left out of the count. They have no ISO3C code because they
      # are in no country, not because one is missing.
      unreachable <- canonical %>%
        dplyr::filter(is.na(iso3c), ccode != 10200, year >= startyear, year <= endyear)

      if (nrow(unreachable) > 0) {

        unreachable.top <- unreachable %>%
          dplyr::group_by(countryname) %>%
          dplyr::summarise(troops = sum(troops_ad, na.rm = TRUE), .groups = "drop") %>%
          # .data$ because `troops` is created by the summarise above rather than being a column of
          # any packaged object. A bare reference reads to R CMD check as an undeclared global, and
          # declaring it in globalVariables() would put a name there that matches no column in the
          # data -- the pronoun says "this is a column of the frame in hand" and needs no declaration.
          dplyr::slice_max(.data$troops, n = 5)

        rlang::warn(paste0(
          "Filtering `host` on ISO3C codes cannot reach every location in the data. ",
          nrow(unreachable), " observations across ",
          dplyr::n_distinct(unreachable$ccode),
          " countries and territories carry no ISO3C code, so they are excluded from any ISO3C ",
          "filter no matter which codes you ask for -- together ",
          format(sum(unreachable$troops_ad, na.rm = TRUE), big.mark = ",", trim = TRUE),
          " reported personnel between ", startyear, " and ", endyear, ". ",
          "The largest in this window: ",
          paste0(unreachable.top$countryname, " (",
                 format(unreachable.top$troops, big.mark = ",", trim = TRUE), ")",
                 collapse = ", "),
          ". To include them, pass `host` as a country name or a Gleditsch and Ward country code, ",
          "or leave `host` unset and subset afterwards."
        ))

      }

      tempdata <- tempdata %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), iso3c, ignore.case = TRUE))

      # Some sub-national units carry their parent state's ISO3C because they have none of their own
      # -- the Azores under PRT, Tibet under CHN, Wake, Midway and Johnston all under UMI. That is
      # deliberate (Lajes is in Portugal, so host = "PRT" should reach it) but it means one ISO3C can
      # return several country codes, and anyone aggregating by iso3c has to sum across them rather
      # than assume one row per code-year.
      shared.iso <- tempdata %>%
        dplyr::filter(!is.na(iso3c)) %>%
        dplyr::distinct(iso3c, ccode, countryname) %>%
        dplyr::group_by(iso3c) %>%
        dplyr::filter(dplyr::n() > 1) %>%
        dplyr::summarise(units = paste(sort(unique(countryname)), collapse = ", "),
                         .groups = "drop")

      if (nrow(shared.iso) > 0) {
        rlang::warn(paste0(
          "One or more of the requested ISO3C codes covers more than one country code, because a ",
          "sub-national unit with no ISO3C of its own carries its parent's: ",
          paste0(shared.iso$iso3c, " = ", shared.iso$units, collapse = "; "),
          ". These are returned as separate rows, so aggregate across `ccode` rather than assuming ",
          "one row per ISO3C and period."
        ))
      }
    } else if (host.type == "region") {
      tempdata <- tempdata %>%
        dplyr::filter(grepl(paste(".*", host, ".*", collapse = "|", sep = ""), region, ignore.case = TRUE))
    } else if (host.type == "countryname") {

      # A substring match on countryname reaches every historical form of most divided countries:
      # "Korea" finds North and South, "Vietnam" finds North, South and the unified state, "Czech"
      # finds Czechoslovakia and the Czech Republic, "Congo" finds both Congos. Germany is the one
      # exception, because the two German states are "Federal Republic of Germany" and "German
      # Democratic Republic" -- "Germany" is not a substring of the second, so host = "Germany"
      # silently returned the west only and dropped 1950-1990 East Germany.
      #
      # Group aliases name the country codes a query should reach in addition to whatever the
      # substring match finds, for the cases where no single string spans every form of a country.
      host.groups <- list("germany" = c(260, 265))

      group.ccodes <- unlist(host.groups[tolower(trimws(host))], use.names = FALSE)

      host.ccodes <- canonical %>%
        dplyr::filter(grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE)) %>%
        dplyr::pull(ccode) %>%
        unique()

      host.ccodes <- unique(c(host.ccodes, group.ccodes))

      tempdata <- tempdata %>%
        dplyr::filter(ccode %in% host.ccodes |
                        grepl(paste(host, collapse = "|"), countryname, ignore.case = TRUE))

      # A country name can legitimately span several codes -- Germany, Korea, Vietnam, Yemen, the two
      # Congos -- which are returned as separate rows, so say so rather than let a sum double count.
      spanned <- tempdata %>%
        dplyr::distinct(ccode, countryname) %>%
        dplyr::arrange(countryname)

      if (nrow(spanned) > 1) {
        rlang::warn(paste0(
          "`host` matched more than one country code: ",
          paste0(spanned$countryname, " (", spanned$ccode, ")", collapse = ", "),
          ". These are returned as separate rows, so aggregate across `ccode` if you want one ",
          "series for the country as a whole."
        ))
      }
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

  # afloat = "separate" returns the personnel afloat attributed to a location beside the figures
  # ashore. The Navy and Marine Corps ashore columns come with them even when branch = FALSE, and
  # each afloat column sits next to the ashore column it belongs with. The state data has no
  # afloat columns.
  afloat.select <- NULL

  if (afloat == "separate" && state_data == FALSE) {

    afloat.select <- "troops_afloat"

    if (branch == FALSE) {

      branch.select <- c("navy_ad", "navy_afloat", "marine_corps_ad", "marine_corps_afloat")

    } else {

      branch.select <- c("army_ad", "navy_ad", "navy_afloat", "air_force_ad", "marine_corps_ad",
                         "marine_corps_afloat", "coast_guard_ad", "space_force_ad")

    }

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
      dplyr::select(ccode, year, month, quarter, iso3c, countryname, region, troops_ad, tidyselect::all_of(afloat.select), tidyselect::all_of(branch.select), tidyselect::all_of(guard.reserve.select), tidyselect::all_of(civilians.select)) %>%
      dplyr::ungroup()

  } else if (state_data == TRUE) {

    tempdata <- tempdata %>%
      dplyr::select(fipscode, state, year, month, quarter, troops_ad, tidyselect::all_of(branch.select), tidyselect::all_of(guard.reserve.select), tidyselect::all_of(civilians.select)) %>%
      dplyr::ungroup()

  }

  # A region given as `host` only chooses which locations are returned. The rows were filtered on
  # the region column above; from here on the query is handled like one with no host at all, so
  # every location in the region comes back on a row of its own, per period, with its code, name
  # and region. Nothing is added up across the locations of a region.
  if (!is.null(host) && state_data == FALSE && host.type == "region") {
    host.type <- "countryname"
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


  # An ISO3C code can belong to more than one location: the Azores carry Portugal's, Wake, Midway
  # and Johnston Islands share UMI, Akrotiri carries GBR. Grouping on the ISO3C code alone merged
  # those locations into one row per code and period, with the first location's name and the
  # largest of their values, so host = "PRT" for 1958 returned "Portugal" with the 2,428 personnel
  # of the Azores and lost Portugal's own 71. The country code is therefore a grouping variable
  # too when the host is an ISO3C code, and each location keeps a row of its own. It is placed
  # after the period so that the columns come out in the order they always had.
  location.group <- character()

  if (state_data == FALSE && host.type == "iso3c") {

    location.group <- "ccode"

    host.terms <- host.terms[host.terms != "ccode"]

  }

  # The function will drop the unused grouping variables but this should be ok.
  # There are lots of different situations where a given space has multiple grouping variables.
  if (quarters == TRUE && host.type %in% c("ccode", "iso3c", "countryname", "state", "fipscode")) {

    tempdata <- tempdata %>%
      dplyr::group_by(!!sym(host.type), year, month, quarter, !!!rlang::syms(location.group)) %>%
      dplyr::summarise(dplyr::across(.cols = tidyselect::all_of(host.terms), ~ dplyr::first(.x)),
                       dplyr::across(dplyr::matches("_ad|_all|_afloat|civilian|guard|reserve"), ~ max_reported(.x)))

  } else if (quarters == FALSE && host.type %in% c("ccode", "iso3c", "countryname", "state", "fipscode")) {

    tempdata <- tempdata %>%
      dplyr::group_by(!!sym(host.type), year, !!!rlang::syms(location.group)) %>%
      dplyr::summarise(dplyr::across(.cols = tidyselect::all_of(host.terms), ~ dplyr::first(.x)),
                       dplyr::across(dplyr::matches("_ad|_all|_afloat|civilian|guard|reserve"), ~ max_reported(.x)))

  }

  # Make sure to remove any lingering -Inf values and replace with NA.
  # They're introduced when NA values are summarised.
  tempdata <- dplyr::ungroup(tempdata) %>%
    dplyr::mutate(dplyr::across(tidyselect::everything(),
                                ~ ifelse(is.infinite(.x), NA, .x)))

  return(tempdata)

}
