#' U.S. overseas troop deployment data
#'
#' @description \code{troopdata} returns a data frame containing information on US military deployments.
#'
#' @return Returns the full data frame containing observations of US military deployments to overseas locations (countries and territories) from 1950 through 2024.
#'
#'
#' @format A data frame with country year observations including the following variables:
#'
#' \describe{
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{region}}{Correlates of War geographic region name.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{month}}{The month of the observation.}
#' \item{\code{quarter}}{The quarter of the observation.}
#' \item{\code{year_quarter}}{The year and quarter of the observation.}
#' \item{\code{source}}{The DMDC report source of the observation.}
#' \item{\code{troops_ad}}{The total number of active duty US military personnel deployed to the host country.}
#' \item{\code{troops_all}}{The total number of US military personnel deployed to the host country including guard and reserve.}
#' \item{\code{army_ad}}{Total number of active duty Army personnel deployed to the host country.}
#' \item{\code{navy_ad}}{Total number of active duty Navy personnel deployed to the host country.}
#' \item{\code{air_force_ad}}{Total number of active duty Air Force personnel deployed to the host country.}
#' \item{\code{space_force_ad}}{Total number of active duty Space Force personnel deployed to the host country.}
#' \item{\code{marine_corps_ad}}{Total number of Marine Corps personnel deployed to the host country.}
#' \item{\code{coast_guard_ad}}{Total number of Coast Guard personnel deployed to the host country.}
#' \item{\code{total_selected_reserve}}{Total number of reserve US military personnel deployed to the host country.}
#' \item{\code{army_reserve}}{Total number of reserve Army personnel deployed to the host country.}
#' \item{\code{navy_reserve}}{Total number of reserve Navy personnel deployed to the host country.}
#' \item{\code{air_force_reserve}}{Total number of reserve Air Force personnel deployed to the host country.}
#' \item{\code{marine_corps_reserve}}{Total number of reserve Marine Corps personnel deployed to the host country.}
#' \item{\code{coast_guard_reserve}}{Total number of reserve Coast Guard personnel deployed to the host country.}
#' \item{\code{army_national_guard}}{Total number of Army National Guard personnel deployed to the host country.}
#' \item{\code{air_national_guard}}{Total number of Air National Guard personnel deployed to the host country.}
#' \item{\code{army_civilian}}{Total number of Army civilian personnel deployed to the host country.}
#' \item{\code{navy_civilian}}{Total number of Navy civilian personnel deployed to the host country.}
#' \item{\code{air_force_civilian}}{Total number of Air Force civilian personnel deployed to the host country.}
#' \item{\code{marine_corps_civilian}}{Total number of Marine Corps civilian personnel deployed to the host country.}
#' \item{\code{dod_civilian}}{Total number of Department of Defense civilian personnel deployed to the host country.}
#' \item{\code{total_civilian}}{Total number of civilian personnel deployed to the host country.}
#'}
#'
#'
#' @docType data
#' @keywords datasets
#' @name troopdata_rebuild_long
#' @source \url{https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005}
#' @source \doi{10.1177/07388942211030885}
#'
"troopdata_rebuild_long"




#' DMDC Deployment Reports
#'
#' @description \code{troopdata_rebuild_reports} returns a data frame containing DMDC reports on US military deployments.
#'
#' @return Returns a data frame containing DMDC reports of US military deployments to overseas locations from 1950 through 2024.
#'
#' @format A data frame with country year quarter observations including the following variables:
#'
#' \describe{
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{region}}{Correlates of War geographic region name.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{month}}{The month of the observation.}
#' \item{\code{quarter}}{The quarter of the observation.}
#' \item{\code{source}}{The DMDC report source of the observation.}
#' \item{\code{Location}}{The geographic location listed in the DMDC reports.}
#' \item{\code{Total}}{"Total number of US military personnel deployed to the host country.}
#' \item{\code{Total Ashore}}{"Total number of US military personnel deployed to the host country, excluding those at sea.}
#' \item{\code{Total Afloat}}{"Total number of US military personnel deployed to the host country, at sea.}
#' \item{\code{Army Total}}{Total number of Army personnel deployed to the host country.}
#' \item{\code{Navy Ashore}}{Total number of Navy personnel deployed to the host country, excluding those at sea.}
#' \item{\code{Navy Temporary Ashore}}{Total number of Navy personnel deployed to the host country, temporarily.}
#' \item{\code{Navy Other}}{Total number of Navy personnel deployed to the host country, in other capacities.}
#' \item{\code{Marine Corps Ashore}}{Total number of Marine Corps personnel deployed to the host country, excluding those at sea.}
#' \item{\code{Marine Corps Afloat}}{Total number of Marine Corps personnel deployed to the host country, at sea.}
#' \item{\code{Air Force Total}}{Total number of Air Force personnel deployed to the host country.}
#' \item{\code{Navy Afloat}}{Total number of Navy personnel deployed to the host country, at sea.}
#' \item{\code{Navy Total}}{Total number of Navy personnel deployed to the host country.}
#' \item{\code{Marine Corps Total}}{Total number of Marine Corps personnel deployed to the host country.}
#' \item{\code{troops_ad}}{The total number of active duty US military personnel deployed to the host country.}
#' \item{\code{army_ad}}{Total number of active duty Army personnel deployed to the host country.}
#' \item{\code{navy_ad}}{Total number of active duty Navy personnel deployed to the host country.}
#' \item{\code{marine_corps_ad}}{Total number of active duty Marine Corps personnel deployed to the host country.}
#' \item{\code{space_force_ad}}{Total number of active duty Space Force personnel deployed to the host country.}
#' \item{\code{air_force_ad}}{Total number of active duty Air Force personnel deployed to the host country.}
#' \item{\code{coast_guard_ad}}{Total number of Coast Guard personnel deployed to the host country.}
#' \item{\code{Macro Location}}{The geographic location listed in the DMDC reports.}
#' \item{\code{Army Active Duty}}{Total number of active duty Army personnel deployed to the host country.}
#' \item{\code{Navy Active Duty}}{Total number of active duty Navy personnel deployed to the host country.}
#' \item{\code{Marine Corps Active Duty}}{Total number of active duty Marine Corps personnel deployed to the host country.}
#' \item{\code{Air Force Active Duty}}{Total number of active duty Air Force personnel deployed to the host country.}
#' \item{\code{Coast Guard Active Duty}}{Total number of active duty Coast Guard personnel deployed to the host country.}
#' \item{\code{Space Force Active Duty}}{Total number of active duty Space Force personnel deployed to the host country.}
#' \item{\code{Total Active Duty}}{Total number of active duty US military personnel deployed to the host country.}
#' \item{\code{Army National Guard}}{Total number of Army National Guard personnel deployed to the host country.}
#' \item{\code{Army Reserve}}{Total number of reserve Army personnel deployed to the host country.}
#' \item{\code{Navy Reserve}}{Total number of reserve Navy personnel deployed to the host country.}
#' \item{\code{Marine Corps Reserve}}{Total number of reserve Marine Corps personnel deployed to the host country.}
#' \item{\code{Air National Guard}}{Total number of Air National Guard personnel deployed to the host country.}
#' \item{\code{Air Force Reserve}}{Total number of reserve Air Force personnel deployed to the host country.}
#' \item{\code{Coast Guard Reserve}}{Total number of reserve Coast Guard personnel deployed to the host country.}
#' \item{\code{Total Selected Reserve}}{Total number of reserve US military personnel deployed to the host country.}
#' \item{\code{Army Civilian}}{Total number of Army civilian personnel deployed to the host country.}
#' \item{\code{Navy Civilian}}{Total number of Navy civilian personnel deployed to the host country.}
#' \item{\code{Marine Corps Civilian}}{Total number of Marine Corps civilian personnel deployed to the host country.}
#' \item{\code{Air Force Civilian}}{Total number of Air Force civilian personnel deployed to the host country.}
#' \item{\code{DOD Civilian}}{Total number of Department of Defense civilian personnel deployed to the host country.}
#' \item{\code{Total Civilian}}{Total number of civilian personnel deployed to the host country.}
#' \item{\code{Grand Total}}{Total number of US military and civilian personnel deployed to the host country.}
#' }
#'
#'
#' @docType data
#' @keywords datasets
#' @name troopdata_rebuild_reports
#' @source \url{https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005}
#' @source \doi{10.1177/07388942211030885}
#'
"troopdata_rebuild_reports"




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
#' @source \url{https://aura.american.edu/articles/online_resource/Lists_of_U_S_Military_Bases_Abroad_1776-2020/23856486}
#'
"basedata"


#' U.S. Military overseas construction spending data
#'
#' @description \code{builddata} returns a data frame containing geocoded location-project-year overseas military construction spending data.
#'
#' @return Returns the full data frame containing location-project-year observations of U.S. military construction spending data from 2008-2019.
#'
#' @format A data frame with country-base observations including the following variables:
#' \describe{
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{ccode}}{A numeric vector of Correlates of War country codes.}
#' \item{\code{year}}{Year of observed country-year spending.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{location}}{Name of the facility where spending occurred, or host country where detailed facility information is unavailable.}
#' \item{\code{spend_construction}}{Total obligational authority associated with the observed location-year in thousands of current US dollars.}
#' \item{\code{lat}}{The facility's latitude.}
#' \item{\code{lon}}{The facility's longitude.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name builddata
#'
#'
"builddata"




#' U.S. domestic troop deployment data, by state
#'
#' @description \code{troopdata_rebuild_us_states} returns a data frame
#'   containing information on U.S. military personnel stationed in each of
#'   the 50 U.S. states (and U.S. territories where reported). Returned by
#'   \code{get_troopdata()} when the \code{state_data} argument is set to
#'   \code{TRUE}.
#'
#' @return Returns the full data frame containing state-year (and
#'   state-year-quarter) observations of U.S. military personnel stationed
#'   domestically from 1950 through the most recent reporting period.
#'
#' @format A data frame with state-year (and state-year-quarter) observations
#'   including the following variables:
#'
#' \describe{
#' \item{\code{fipscode}}{A numeric vector of U.S. Federal Information
#'   Processing Standards (FIPS) state codes. Used as the numeric identifier
#'   when subsetting via \code{get_troopdata(host = <numeric>, state_data = TRUE)}.}
#' \item{\code{state}}{A character vector of U.S. state names. Matched with a
#'   case-insensitive \code{grepl} fuzzy match when subsetting via
#'   \code{get_troopdata(host = <character>, state_data = TRUE)}.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{month}}{The month of the observation.}
#' \item{\code{quarter}}{The quarter of the observation.}
#' \item{\code{troops_ad}}{The total number of active duty US military personnel stationed in the state.}
#' \item{\code{army_ad}}{Total number of active duty Army personnel stationed in the state.}
#' \item{\code{navy_ad}}{Total number of active duty Navy personnel stationed in the state.}
#' \item{\code{air_force_ad}}{Total number of active duty Air Force personnel stationed in the state.}
#' \item{\code{marine_corps_ad}}{Total number of active duty Marine Corps personnel stationed in the state.}
#' \item{\code{coast_guard_ad}}{Total number of active duty Coast Guard personnel stationed in the state.}
#' \item{\code{space_force_ad}}{Total number of active duty Space Force personnel stationed in the state.}
#' \item{\code{army_national_guard}}{Total number of Army National Guard personnel stationed in the state.}
#' \item{\code{air_national_guard}}{Total number of Air National Guard personnel stationed in the state.}
#' \item{\code{army_reserve}}{Total number of Army Reserve personnel stationed in the state.}
#' \item{\code{navy_reserve}}{Total number of Navy Reserve personnel stationed in the state.}
#' \item{\code{marine_corps_reserve}}{Total number of Marine Corps Reserve personnel stationed in the state.}
#' \item{\code{air_force_reserve}}{Total number of Air Force Reserve personnel stationed in the state.}
#' \item{\code{coast_guard_reserve}}{Total number of Coast Guard Reserve personnel stationed in the state.}
#' \item{\code{total_selected_reserve}}{Total number of reserve US military personnel stationed in the state.}
#' \item{\code{army_civilian}}{Total number of Army civilian personnel stationed in the state.}
#' \item{\code{navy_civilian}}{Total number of Navy civilian personnel stationed in the state.}
#' \item{\code{air_force_civilian}}{Total number of Air Force civilian personnel stationed in the state.}
#' \item{\code{marine_corps_civilian}}{Total number of Marine Corps civilian personnel stationed in the state.}
#' \item{\code{dod_civilian}}{Total number of Department of Defense civilian personnel stationed in the state.}
#' \item{\code{total_civilian}}{Total number of civilian personnel stationed in the state.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name troopdata_rebuild_us_states
#' @source \url{https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005}
#' @source \doi{10.1177/07388942211030885}
#'
"troopdata_rebuild_us_states"




#' Multilateral Military Exercises (MME) data, long format
#'
#' @description \code{mme_long} returns a data frame containing
#'   exercise-country-year observations of multilateral military exercises.
#'   Built from the MME version 7 data (\url{https://doi.org/10.7910/DVN/KHFODX})
#'   and reshaped so each row represents a single participating country in
#'   a single year of a single exercise. This is the data object underlying
#'   \code{get_exercises()}.
#'
#' @return Returns the full data frame of exercise-country-year observations
#'   of multilateral military exercises from 1980 forward.
#'
#' @format A data frame with exercise-country-year observations including
#'   the following variables:
#'
#' \describe{
#' \item{\code{MMEID}}{Unique exercise identifier from the MME source data.}
#' \item{\code{Ex_Name}}{The name of the individual exercise (e.g.,
#'   "Cobra Gold 23").}
#' \item{\code{Series_Name}}{The name of the broader exercise series the
#'   exercise belongs to (e.g., "Cobra Gold").}
#' \item{\code{gwcode}}{Numeric Gleditsch and Ward country code for the
#'   participating country. Looked up from \code{country} via the
#'   \code{countrycode} package; \code{NA} for non-country participants
#'   such as "NATO" or regional groupings.}
#' \item{\code{country}}{Character vector of participating country names as
#'   recorded in the MME source data.}
#' \item{\code{year}}{The year of the observation. Exercises spanning
#'   multiple years are expanded so that each year between \code{s.year}
#'   and \code{e.year} produces its own row.}
#' \item{\code{Location}}{The geographic location where the exercise was
#'   held (free-text from the source data).}
#' \item{\code{lat}}{Latitude of the exercise location.}
#' \item{\code{lon}}{Longitude of the exercise location.}
#' \item{\code{StartDate}}{Original start-date string from the source data.}
#' \item{\code{s.year}}{Numeric year the exercise began.}
#' \item{\code{s.month}}{Numeric month the exercise began.}
#' \item{\code{s.day}}{Numeric day the exercise began (may be \code{"xx"}
#'   when unknown).}
#' \item{\code{EndDate}}{Original end-date string from the source data.}
#' \item{\code{e.year}}{Numeric year the exercise ended.}
#' \item{\code{e.month}}{Numeric month the exercise ended.}
#' \item{\code{e.day}}{Numeric day the exercise ended (may be \code{"xx"}
#'   when unknown).}
#' \item{\code{CPX}}{Binary indicator: command post exercise.}
#' \item{\code{Air}}{Binary indicator: air domain.}
#' \item{\code{Land}}{Binary indicator: land domain.}
#' \item{\code{Sea}}{Binary indicator: sea domain.}
#' \item{\code{Amphibious}}{Binary indicator: amphibious domain.}
#' \item{\code{Cyber}}{Binary indicator: cyber domain.}
#' \item{\code{Warfighting}}{Binary indicator: warfighting focus.}
#' \item{\code{Peacekeeping}}{Binary indicator: peacekeeping focus.}
#' \item{\code{Humanitarian}}{Binary indicator: humanitarian focus.}
#' \item{\code{FocusDescription}}{Free-text description of the exercise's
#'   focus from the source data.}
#' \item{\code{AdditionalParticipantInfo}}{Free-text notes about
#'   participants from the source data.}
#' \item{\code{participant_count}}{Total number of participating countries
#'   in the exercise. The same value is repeated across all rows that share
#'   an MMEID. Used by the \code{min_participants} and \code{max_participants}
#'   arguments of \code{get_exercises()}.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name mme_long
#' @source D'Orazio, Vito; Galambos, Kevin, 2021, "Multinational Military
#'   Exercises, 1980-2010", \doi{10.7910/DVN/KHFODX}, Harvard Dataverse, V1.
#'
"mme_long"
