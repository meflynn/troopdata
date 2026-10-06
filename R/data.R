#' U.S. overseas troop deployment data
#'
#' @description \code{troopdata_rebuild_long} is the data frame behind \code{\link{get_troopdata}}: U.S. military personnel by location and report period, for every country, territory and other location in the reports, the United States included.
#'
#' @return Returns the full data frame containing observations of US military deployments by location (countries and territories) from 1950 through the latest report in this version of the package, March 2026.
#'
#'
#' @format A data frame with one row per location and report period (a year and a quarter), including the following variables:
#'
#' \describe{
#' \item{\code{ccode}}{A numeric vector of Gleditsch and Ward country codes. Territories and other locations that the Gleditsch and Ward list does not cover carry the package's own codes (Puerto Rico 6, Greenland 1002, Guam 1008 and others, all above 1000 except Puerto Rico). These are not Correlates of War codes: Germany is 260, not 255.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes. A location with no code of its own carries its parent's (the Azores carry \code{"PRT"}), and a few locations have none.}
#' \item{\code{countryname}}{A character vector of country names.}
#' \item{\code{region}}{Geographic region, using the names of the World Bank regions. Countries take the region the \code{countrycode} package gives them, territories and other locations with the package's own codes are assigned one by the package, and \code{"Afloat"} and \code{"Antarctica"} are regions of their own.}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{month}}{The month of the report: March, June, September or December.}
#' \item{\code{quarter}}{The quarter of the observation, 1 through 4.}
#' \item{\code{year_quarter}}{The year and quarter of the observation.}
#' \item{\code{source}}{Where the row's figures come from: the month and year of the DMDC report, \code{"Kane 2006"} for a figure from Kane's data, \code{"Stepwise Imputation"} for 1951 and 1952, or a label beginning \code{"Estimate"} for a figure from public reporting. Missing where no report lists the location for that period, which is where the zeros described in Details come from; 17 rows with no source are not zero, the Iraq figure of 5,200 for June 2018, 2019 and 2020 among them. The rows of December 2022, March 2023 and June 2023 carry the label of their report although their Army figures are filled in.}
#' \item{\code{troops_ad}}{The total number of active duty US military personnel deployed to the host country. In a row that comes from a report it equals the sum of the branch columns.}
#' \item{\code{troops_all}}{The total number of US military personnel deployed to the host country including guard and reserve: \code{troops_ad} plus the seven National Guard and Reserve columns. Equal to \code{troops_ad} before 2008, when the reports give no guard or reserve figures.}
#' \item{\code{army_ad}}{Total number of active duty Army personnel deployed to the host country.}
#' \item{\code{navy_ad}}{Total number of active duty Navy personnel deployed to the host country.}
#' \item{\code{air_force_ad}}{Total number of active duty Air Force personnel deployed to the host country.}
#' \item{\code{space_force_ad}}{Total number of active duty Space Force personnel deployed to the host country.}
#' \item{\code{marine_corps_ad}}{Total number of Marine Corps personnel deployed to the host country.}
#' \item{\code{coast_guard_ad}}{Total number of Coast Guard personnel deployed to the host country.}
#' \item{\code{troops_afloat}}{Navy and Marine Corps personnel afloat that a report attributes to the location, 1950 through 2007. Not included in \code{troops_ad}. See Details.}
#' \item{\code{navy_afloat}}{Navy personnel afloat that a report attributes to the location. Not included in \code{navy_ad}.}
#' \item{\code{marine_corps_afloat}}{Marine Corps personnel afloat that a report attributes to the location. Not included in \code{marine_corps_ad}.}
#' \item{\code{total_selected_reserve}}{Total number of reserve US military personnel deployed to the host country. This and the other guard, reserve and civilian columns are reported from 2008 and are missing for earlier years.}
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
#' @details
#' \strong{Report periods.} Each row holds the figures of one period. The data have one report a
#' year through 2012 (dated June for 1950 and 1953-1956, and September from 1957), two for 2013
#' (September and December) and four a year from 2014 (March, June, September and December), and
#' they stop at the latest report. \code{\link{get_troopdata}} returns these rows with
#' \code{quarters = TRUE}. Its annual figures (\code{quarters = FALSE}) are the largest value of
#' each column over the periods of a year, taken column by column, so they are not stored here
#' and the columns of an annual row need not come from the same report.
#'
#' \strong{Zeros and missing values.} A country that a report does not list has 0 for that
#' period and no \code{source}. A zero therefore means either that the report prints zero or that
#' it does not list the country. Territories and the other locations that carry the package's own
#' codes, and a few small states in the years before their independence, have a row only for the
#' periods in which a report lists them, so the data are not a balanced panel for them.
#' \code{NA} means that the reports give no figure of that kind:
#' the guard, reserve and civilian columns and \code{coast_guard_ad} before 2008,
#' \code{space_force_ad} before September 2023, the branch columns for 1951 and 1952, and the
#' afloat columns as described below.
#'
#' \strong{Figures that are not taken from a report.} The \code{source} column marks them,
#' apart from the two cases noted under \code{source} above.
#' \itemize{
#'   \item 1951 and 1952 have no report. \code{troops_ad} for those years moves in equal steps
#'     from the June 1950 figure to the June 1953 figure, and the branch columns are missing.
#'     This is done for countries. Most territories and other locations with the package's own
#'     codes, the \code{"Afloat"} location among them, have no rows for those two years.
#'   \item The Army reported nothing for December 2022, March 2023 and June 2023.
#'     \code{army_ad}, \code{army_national_guard} and \code{army_reserve} for those quarters move
#'     in equal steps from the September 2022 figure to the September 2023 figure, and
#'     \code{troops_ad}, \code{total_selected_reserve} and \code{troops_all} are those figures
#'     plus what the other services reported. The other columns are as reported.
#'     \code{\link{troopdata_rebuild_reports}} and \code{\link{troopdata_rebuild_us_states}}
#'     keep those quarters as published, with the Army figures and the totals missing.
#'   \item The June 2023 report prints part of its overseas list one row low: the civilian
#'     columns from Montenegro to the end of the list, and the Navy Reserve, Marine Corps
#'     Reserve, Air National Guard, Air Force Reserve and Coast Guard Reserve columns from
#'     Morocco to Wake Island. Qatar's line holds Puerto Rico's 2,201 civilians and Uruguay's
#'     the United Kingdom's 1,383. The figures here are read from the line below the one they
#'     are printed on, which is where the March and September 2023 reports and the report's
#'     own totals put them. \code{\link{troopdata_rebuild_reports}} keeps the report as
#'     published.
#'   \item Where the reports do not give the personnel deployed to a war zone, a figure from
#'     Kane's data or from public reporting is used: Afghanistan for 2001-2005 and 2018-2020, Iraq
#'     for 2003-2007 and 2018-2021, Kuwait for 2003-2007 and Syria for 2018-2021. These are
#'     totals only, with zeros in the branch columns. From December 2017 the reports leave out
#'     personnel deployed to Afghanistan, Iraq and Syria, and no outside figure is used after
#'     those years, so the values for Afghanistan from 2021 and for Iraq and Syria from 2022 are
#'     the handful of personnel the reports print and understate the U.S. presence. The outside
#'     figures for Iraq in 2018-2021 and for Syria in 2021 are on the June row only, and the other
#'     quarters of those years hold what the report prints, which is zero or close to it.
#'   \item The reports for 1957 through 2013 are dated September (and December in 2013). A row
#'     dated June in those years is not a report. It holds a figure from Kane's data, or one of
#'     the estimates above, and is kept only for a location and year in which no report gives a
#'     figure or the report prints a zero in its place. Nearly all of these rows are zero.
#' }
#'
#' \strong{Locations.} Personnel are counted at the location the report lists them under.
#' Personnel that a report lists under no location (lines such as "Transients", "Undistributed",
#' "Departmental Headquarters" and "Unknown") are not in the data. Where a report lists two
#' places under one country code (Japan and the Ryukyu Islands through 1973, for example) the row
#' is their sum. The United States is the fifty states and the
#' District of Columbia. Puerto Rico, Guam and the other territories are locations of their own.
#'
#' \strong{Personnel ashore and afloat.}
#' Before 2008 \code{troops_ad}, \code{navy_ad} and \code{marine_corps_ad} hold personnel ashore
#' for every location, the United States included. The reports for 1950 through 2007 count Navy
#' and Marine Corps personnel afloat separately, and attribute some of them to a location: to the
#' country of the nearest port or the country whose line they are printed on (1953-1976), and,
#' for the fleet in home waters, to the United States (1950, 1953-2007; from 1968 the reports give
#' that figure for the United States and its territories together). Those are in
#' \code{troops_afloat}, \code{navy_afloat} and \code{marine_corps_afloat}, beside the ashore
#' figures and not inside them. A zero there means a report that lists personnel afloat by
#' location has none for that one (1953-1976); a missing value means the report gives no figure
#' for the location (everywhere but the United States in 1950 and 1977-2007, apart from 171
#' Marines afloat at Cuba in 1950; the years 1951 and 1952; and everything from 2008). For 1954-1956 the figure also holds mobile units temporarily
#' based ashore, which those three reports do not separate.
#'
#' Everyone afloat is also carried once, worldwide, in a location named \code{"Afloat"}
#' (\code{ccode} 10200, no ISO code, region \code{"Afloat"}), with values for 1950 and 1953
#' through 2007. It is not a country, and it includes the personnel the three afloat columns
#' attribute to locations: \code{troops_ad} added up over every row, that one included, counts
#' everyone the data place somewhere once, and adding the afloat columns to it as well would
#' count those personnel twice. (It is still below the worldwide total a report prints, which
#' also includes the personnel it lists under no location.) \code{\link{get_troopdata}} handles this through its \code{afloat} argument, which
#' leaves the attributed personnel out of the locations, adds them in, or returns them separately,
#' and adjusts the \code{"Afloat"} location to match. From September 2008 the DMDC reports count a
#' ship's crew at its home port, inside the state or country figure, and there is no afloat figure,
#' so the ashore Navy figures for countries and states that are home ports step up between 2007
#' and 2008.
#'
#' The reports did not keep to that from December 2015 to December 2017. They list 77,120
#' personnel under "Unknown" in the United States block in December 2015, and between 88,500 and
#' 104,703 in each report from March 2016 to December 2017 under "Armed Forces Europe", "Armed
#' Forces Pacific" and "Armed Forces the Americas", nearly all of them Navy. Those personnel
#' cannot be traced to a state or a country and are in none of the figures here, the
#' \code{"Afloat"} location included. The United States total and its Navy figure are therefore
#' lower in those quarters and return in March 2018: the annual Navy figure for the United
#' States is 278,123 in 2015, 188,184 in 2016, 198,679 in 2017 and 289,853 in 2018. Japan's Navy
#' figure for December 2015 (41,546, against 22,030 in September 2015 and 12,234 in March 2016)
#' is as that report prints it, and is why the annual figure for Japan in 2015, 71,567, stands
#' well above the years around it.
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
#' @return Returns a data frame containing DMDC reports of US military deployments by location from 1950 through the latest report in this version of the package, March 2026.
#'
#' @format A data frame with one row per line of a report, including the following variables. A country code can appear on more than one row in a period, because the rows keep the locations and names the reports print (Japan and the Ryukyu Islands are both under 740, for example).
#'
#' \describe{
#' \item{\code{ccode}}{A numeric vector of Gleditsch and Ward country codes, with the package's own codes for territories and other locations the list does not cover. See \code{\link{troopdata_rebuild_long}}.}
#' \item{\code{iso3c}}{A character vector of ISO three character country codes.}
#' \item{\code{countryname}}{A character vector of country names. They are tidied but not fully standardized, so a code can carry more than one name here and a name can differ from the one in \code{\link{troopdata_rebuild_long}} (260 is \code{"Germany"} here). \code{Location} holds the name as the report prints it.}
#' \item{\code{region}}{Geographic region, as in \code{\link{troopdata_rebuild_long}}, but missing for a number of territories and historical locations.}
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
#' \item{\code{troops_afloat}}{Navy and Marine Corps personnel afloat that a report attributes to the location, 1950 through 2007. Not included in \code{troops_ad}. See Details.}
#' \item{\code{navy_afloat}}{Navy personnel afloat that a report attributes to the location. Not included in \code{navy_ad}.}
#' \item{\code{marine_corps_afloat}}{Marine Corps personnel afloat that a report attributes to the location. Not included in \code{marine_corps_ad}.}
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
#' @details
#' Before 2008 \code{troops_ad}, \code{navy_ad} and \code{marine_corps_ad} hold personnel ashore
#' for every location, the United States included. The reports for 1950 through 2007 count Navy
#' and Marine Corps personnel afloat separately, and attribute some of them to a location: to the
#' country of the nearest port or the country whose line they are printed on (1953-1976), and,
#' for the fleet in home waters, to the United States (1950, 1953-2007; from 1968 the reports give
#' that figure for the United States and its territories together). Those are in
#' \code{troops_afloat}, \code{navy_afloat} and \code{marine_corps_afloat}, beside the ashore
#' figures and not inside them. A zero there means a report that lists personnel afloat by
#' location has none for that one (1953-1976); a missing value means the report gives no figure
#' for the location (everywhere but the United States in 1950 and 1977-2007, apart from 171
#' Marines afloat at Cuba in 1950; the years 1951 and 1952; and everything from 2008). For 1954-1956 the figure also holds mobile units temporarily
#' based ashore, which those three reports do not separate.
#'
#' Everyone afloat is also carried once, worldwide, in a location named \code{"Afloat"}
#' (\code{ccode} 10200, no ISO code, region \code{"Afloat"}), with values for 1950 and 1953
#' through 2007. It is not a country, and it includes the personnel the three afloat columns
#' attribute to locations: \code{troops_ad} added up over every row, that one included, counts
#' everyone the data place somewhere once, and adding the afloat columns to it as well would
#' count those personnel twice. (It is still below the worldwide total a report prints, which
#' also includes the personnel it lists under no location.) \code{\link{get_troopdata}} handles this through its \code{afloat} argument, which
#' leaves the attributed personnel out of the locations, adds them in, or returns them separately,
#' and adjusts the \code{"Afloat"} location to match. From September 2008 the DMDC reports count a
#' ship's crew at its home port, inside the state or country figure, and there is no afloat figure,
#' so the ashore Navy figures for countries and states that are home ports step up between 2007
#' and 2008.
#'
#' The reports did not keep to that from December 2015 to December 2017. They list 77,120
#' personnel under "Unknown" in the United States block in December 2015, and between 88,500 and
#' 104,703 in each report from March 2016 to December 2017 under "Armed Forces Europe", "Armed
#' Forces Pacific" and "Armed Forces the Americas", nearly all of them Navy. Those personnel
#' cannot be traced to a state or a country and are in none of the rows here, so the United
#' States figures are lower in those quarters and return in March 2018.
#'
#' The derived columns, whose names are in lower case, follow that rule. The columns that carry a
#' report's own figures, such as \code{Total}, \code{Total Afloat}, \code{Navy Afloat} and
#' \code{Navy Other}, are left as the report prints them; \code{navy_afloat} is built from
#' \code{Navy Afloat} or \code{Navy Other}, whichever the report of that year uses (the United
#' States row, which is assembled from several lines, aside). For December 2022, March 2023 and June 2023 the Army reported nothing: the
#' Army columns and \code{troops_ad} are missing on those rows and the other services are as reported.
#' The United States row is the exception. It is not a line of a report (from 2008 it is the sum
#' of the state lines), and for those three quarters it carries a fixed Army figure of 404,114, a
#' total built on it, and zeros rather than missing values in the Army guard and reserve columns
#' and the totals that include them. \code{\link{troopdata_rebuild_long}} fills the Army figures
#' for those quarters in equal steps between September 2022 and September 2023 instead, so the
#' two differ for the United States there.
#'
#' In 46 rows of December 2021, March 2022 and June 2022 the total a report prints, which is
#' what \code{troops_ad} holds here, is lower than the sum of that row's service columns.
#' \code{\link{troopdata_rebuild_long}} uses the sum.
#'
#' The June 2023 report prints part of its overseas list one row low: the six civilian columns
#' from Montenegro to the end of the list, and the Navy Reserve, Marine Corps Reserve, Air
#' National Guard, Air Force Reserve and Coast Guard Reserve columns from Morocco to Wake Island.
#' Each of those lines holds the figures of the location above it, so Qatar shows Puerto Rico's
#' 2,201 civilians and Puerto Rico shows 7. The rows here are as published.
#' \code{\link{troopdata_rebuild_long}} reads those figures from the right line.
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


#' U.S. Military construction spending data
#'
#' @description \code{build_data_20260918} returns a data frame containing geocoded location-project-year military construction spending data, for projects in the United States and overseas.
#'
#' @return Returns the full data frame containing location-project-year observations of U.S. military construction spending, compiled from the DoD Comptroller Annual Report C-1 exhibits. All amounts are in thousands of current US dollars. Each fiscal year is taken from the most recent report that covers it, so a project-year appears once, and each row is one line of that report.
#'
#' @format A data frame of location-project-year observations including the following variables:
#' \describe{
#' \item{\code{fiscal_year}}{Fiscal year of the project.}
#' \item{\code{state_country}}{Two-letter state or country code as reported. Overseas codes mix ISO2C with legacy FIPS 10-4 and DoD codes.}
#' \item{\code{state_country_name}}{Readable form of the state or country as reported. The only form available for codes such as ZU (Unspecified Worldwide Locations), which have no country identifier.}
#' \item{\code{iso3c}}{ISO three character country code. NA for unspecified and worldwide locations. The 392 lines of FY2007-FY2016 that are filed under "Unspecified Worldwide Locations" but name a U.S. installation in their project title (\code{"USA-224: Fort Hood, TX"}) carry \code{"USA"}; \code{state_country} and \code{location_name} are left as the report prints them, and the installation and state are in \code{location_full_name}.}
#' \item{\code{gwcode}}{Gleditsch and Ward country code. The G&W list has no code for a dependency, so territories carry the custom codes the troop data use for the same places: Puerto Rico 6, Greenland 1002, Diego Garcia 1004, Guam 1008, the Northern Mariana Islands 1011, the U.S. Virgin Islands 1013, Wake Island 1014, American Samoa 1041 and Ascension Island 1042. NA for unspecified and worldwide locations.}
#' \item{\code{location_name}}{Installation or location, in title case with initialisms preserved. The reports write the same place in block capitals one year and title case the next; a derived list of protected tokens keeps forms like \code{"MCAS Iwakuni"}, \code{"MacDill AFB"} and \code{"RAF Lakenheath"} intact.}
#' \item{\code{location_name_reported}, \code{project_title_reported}}{The location and project title as the source sheet wrote them, before case harmonization.}
#' \item{\code{location_full_name}}{The address sent to the geocoder: the location followed by the country, or by the state and \code{"United States"}. NA for rows that are not geocoded.}
#' \item{\code{location_code}}{Comptroller location code.}
#' \item{\code{latitude}, \code{longitude}}{Coordinates of the location, kept only where the geocoded point falls inside the country or state the row is filed under. NA for rows filed under no country (unspecified, worldwide and classified locations), for locations that are a label rather than a place (\code{"Various Locations"}), and where no point inside the country or state was found. A point inside the right country is not always the installation: a geocoder that does not know a place answers with the centre of the country, or with another place of the same name. The installations found to be placed that way are corrected by hand (\code{geo_source} is \code{"manual"}); the few that could not be located have no coordinates.}
#' \item{\code{geo_source}}{Where the coordinates came from: the geocoding service that resolved the location (\code{"arcgis"} for every geocoded row in the current data), or \code{"manual"} for a point entered by hand from \code{data-raw/geocode_overrides.csv}, which records what each point is and the page it was read from.}
#' \item{\code{organization}}{Service or agency, harmonized across years to full names: \code{"Army"}, \code{"Navy"}, \code{"Air Force"}, \code{"Defense-Wide"}, \code{"Special Operations Command"} and other defense agencies. Marine Corps construction is carried in the Navy accounts and has no value of its own; guard and reserve components appear in \code{appn_title}.}
#' \item{\code{organization_reported}}{The organization string as the source sheet wrote it, before harmonization.}
#' \item{\code{project_number}, \code{project_title}}{Project identifier and description. The title is in title case with initialisms preserved.}
#' \item{\code{appn_amount}, \code{auth_amount}, \code{auth_appn_amount}, \code{toa_amount}}{Appropriation, authorization, authorization of appropriation, and total obligational authority, in thousands of current US dollars. Negative values occur for rescissions and reprogramming.}
#' \item{\code{appn_title}}{Appropriation account title.}
#' \item{\code{budget_activity}}{Budget activity number. Meaningful only within an appropriation account: activity 1 is major construction in the MILCON accounts but FY 2005 BRAC, new construction or direct loan subsidy in others.}
#' \item{\code{budget_activity_title}}{Budget activity, harmonized to one label per activity across years. The source workbooks write these inconsistently, with case variants, abbreviations, truncations and typos.}
#' \item{\code{budget_activity_title_reported}}{The budget activity label as the source sheet wrote it, before harmonization.}
#' \item{\code{facility_category_title_reported}}{The facility title as the source sheet wrote it, before case and abbreviation harmonization.}
#' \item{\code{facility_category_code}, \code{facility_category_title}}{The three-digit DoD facility category code and its title, in sentence case with initialisms preserved. One code maps to exactly one title.}
#' \item{\code{facility_group_title}}{The coarse level of the DoD facility taxonomy, in sentence case. The reports carry it under three different headers -- "Facility Group Title", "Fiscal Category Title", and, in the most recent years, the facility category column -- and all three are collected here. Kept separate from \code{facility_category_title}, the finer three-digit level of the same taxonomy, though the split is a reconstruction rather than something the reports maintain; \code{get_builddata()} therefore searches both columns from its single \code{facility_category} argument.}
#' \item{\code{transaction_type}}{Type of budget action, where reported (\code{"BUDGET"}, \code{"REPROGRAM"}, rescissions). NA for most rows.}
#' \item{\code{sheet_type}}{Which kind of sheet the row came from: \code{"base"} for regular fiscal-year sheets, or \code{"oco"} for an overseas contingency operations exhibit. The other supplemental exhibits restate lines of the regular sheets and are not in the data.}
#' \item{\code{source_file}, \code{source_sheet}, \code{source_row}}{Workbook and sheet the row was read from, and its position in that sheet counting from 1 below the header. Together they identify one line of one report. A report can list two projects that agree in every other column, and this is what tells them apart.}
#' \item{\code{report_year}}{Latest fiscal year covered by the source workbook, i.e. the report vintage. Consecutive reports restate the same fiscal years, and every fiscal year here comes from the most recent report that covers it.}
#' \item{\code{is_request}}{TRUE where the row is a budget request rather than an enacted figure: the fiscal year is the terminal year of its source report, or the row comes from a request sheet. That is all of FY2016, whose later reports are not among the source files, and 26 lines of FY2010 from the overseas contingency operations request sheet (\code{"C1_2010_OCO_Req"}) that are on no enacted sheet.}
#' \item{\code{classification}}{Security classification marking carried on the row, \code{"U"} for unclassified. FY2011 onward.}
#' \item{\code{dollar_type}}{Kind of dollar figure the row reports (\code{"Budget"} or \code{"Congressional Rescission"}). FY2003-FY2005.}
#' \item{\code{existing_mission}}{Whether the project supports an existing mission, as reported. FY2003-FY2005.}
#' \item{\code{pe}}{Program element. FY2003-FY2004.}
#' \item{\code{percent_recapitalization}}{Share of the project classed as recapitalization. No values: only the FY2008 report printed it, and the years it covers are taken from later reports.}
#' \item{\code{state_country_sort}}{Sort key the source sheet used for the state or country column. FY2006.}
#' }
#'
#' @section Year coverage: The C-1 exhibit layout changed over time, and a later
#'   report does not always print what an earlier one did, so several fields are
#'   reported only for a subset of years: \code{transaction_type} and
#'   \code{appn_title} FY2001-FY2002; \code{pe} FY2003-FY2004;
#'   \code{dollar_type} and \code{existing_mission} FY2003-FY2005;
#'   \code{location_code} FY2000-FY2006; \code{facility_category_code} FY2000
#'   and FY2003-FY2006; \code{project_number} FY2000-FY2006 and FY2013 onward;
#'   \code{state_country_sort} FY2006; \code{classification} FY2011 onward;
#'   \code{facility_category_title} FY2003-FY2005, FY2007-FY2021 and FY2026;
#'   \code{facility_group_title} FY2000 and FY2007 onward;
#'   \code{state_country_name} FY2006 and FY2009 onward. FY2006 reports
#'   appropriations only, so \code{toa_amount}, \code{auth_amount},
#'   \code{auth_appn_amount} and \code{budget_activity_title} are missing for
#'   that year; \code{toa_amount} and \code{auth_appn_amount} are also missing
#'   for FY2000, and \code{budget_activity_title} for FY2000 and FY2008. The
#'   workbooks that supply FY2004-FY2007 give the service of an Army, Navy or
#'   Air Force line in their "Treasury Agency" column rather than under
#'   "Organization"; \code{organization} is filled from it, and
#'   \code{organization_reported} holds the letter printed there (\code{"A"},
#'   \code{"N"} or \code{"F"}). The series runs FY2000 through FY2026.
#'
#' @docType data
#' @keywords datasets
#' @name build_data_20260918
#'
#'
"build_data_20260918"


#' U.S. Military overseas construction spending data (superseded)
#'
#' @description \code{builddata} is the original geocoded construction spending data, compiled from
#' operations and maintenance records rather than the Comptroller Annual Report C-1 exhibits. It is
#' retained for reproducibility of earlier analyses. \code{get_builddata()} reads
#' \code{build_data_20260918} instead.
#'
#' @return Returns a data frame containing location-year observations of U.S. military construction
#' spending data from 2008-2019.
#'
#' @format A data frame with location-year observations including the following variables:
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
#'   the 50 U.S. states and the District of Columbia. Territories such as
#'   Puerto Rico and Guam are overseas locations and are in the country data,
#'   not here. Returned by
#'   \code{get_troopdata()} when the \code{state_data} argument is set to
#'   \code{TRUE}.
#'
#' @details From December 2015 to December 2017 the DMDC reports list a large number of
#' personnel, nearly all Navy, inside the United States block but in no state: 77,120 under
#' "Unknown" in December 2015, and between 88,500 and 104,703 in each report from March 2016 to
#' December 2017 under "Armed Forces Europe", "Armed Forces Pacific" and "Armed Forces the
#' Americas". They cannot be traced to a state and are not in these figures, so the Navy and
#' total figures of the home-port states are lower in those quarters and return in March 2018.
#'
#' The Army reported nothing for December 2022, March 2023 and June 2023. In those three quarters
#' \code{army_ad}, \code{army_national_guard}, \code{army_reserve} and the totals that include
#' them (\code{troops_ad}, \code{total_selected_reserve} and \code{troops_all}) are missing
#' here, and the other columns are as reported. Unlike the country data, nothing is filled in.
#' The annual figures that \code{\link{get_troopdata}} returns for a state are the largest value
#' of each column over the quarters of the year that have one, so for 2022 and 2023 the totals
#' and the Army figures come from the quarters the Army reported.
#'
#' @return Returns the full data frame containing state-year-quarter
#'   observations of U.S. military personnel stationed domestically from
#'   September 2008, the first report that lists the states, through the most
#'   recent reporting period.
#'
#' @format A data frame with one row per state and report period (one report
#'   a year through 2012, two in 2013 and four a year from 2014), including
#'   the following variables:
#'
#' \describe{
#' \item{\code{fipscode}}{A numeric vector of U.S. Federal Information
#'   Processing Standards (FIPS) state codes. Used as the numeric identifier
#'   when subsetting via \code{get_troopdata(host = <numeric>, state_data = TRUE)}.}
#' \item{\code{state}}{A character vector of U.S. state names. Matched without
#'   regard to case when subsetting via
#'   \code{get_troopdata(host = <character>, state_data = TRUE)}: a full name
#'   returns that state alone (\code{"kansas"} is Kansas, \code{"Virginia"} is
#'   not also West Virginia), and part of a name returns every state whose name
#'   contains it (\code{"Carolina"}).}
#' \item{\code{year}}{The year of the observation.}
#' \item{\code{month}}{The month of the observation.}
#' \item{\code{quarter}}{The quarter of the observation.}
#' \item{\code{troops_ad}}{The total number of active duty US military personnel stationed in the state, as the report prints it. For 95 state-quarters in June 2021, December 2021 and March 2022 the printed total is lower than the sum of the branch columns. The country data use the sum for the United States in those quarters, so the states add up to 23, 4,330 and 6,046 fewer personnel than the United States figure there. Missing in December 2022, March 2023 and June 2023, when the Army did not report.}
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
#' \item{\code{troops_all}}{The total number of US military personnel stationed in the state including guard and reserve: \code{troops_ad} plus the seven guard and reserve components, the same definition as in the country data. Missing in December 2022, March 2023 and June 2023, when the Army did not report and \code{troops_ad} is missing here.}
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
#'   Built from the MME version 7 data (\doi{10.7910/DVN/KHFODX})
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
#'   "Cobra Gold 93").}
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
