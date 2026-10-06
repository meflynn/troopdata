# troopdata 1.1.0


# troopdata 1.0.4.9000

- Claude Opus 5.5 was used to aid in detecting errors in the data and code, and in updating the
  code, for this version.

- **Rebuilds the military construction data from the DoD Comptroller Annual Report C-1 exhibits.**
  The packaged object is now `build_data_20260918` (14,070 location-project-year observations,
  FY2000-FY2026, 42 columns), built by `data-raw/build_data_20260603.R`, which reads every sheet of
  every C-1 workbook and writes the `.rda` itself. `get_builddata()` reads that object.
  `data-raw/builddata.R` is superseded, and `builddata`--the 2008-2019 operations and maintenance
  extract--is retained only for reproducibility of earlier analyses.

- **Updates `get_builddata()` to the rebuilt schema.** Label arguments are now matched against the
  values actually present in the data: matching is case-insensitive and returns the canonical
  spelling, and an unmatched value raises an error naming the column to inspect instead of silently
  returning zero rows. `organization = "Marine Corps"` is the motivating case--the C-1 exhibits
  carry Marine Corps construction in the Navy accounts, so that value does not exist.
  `host` validates ISO3C and Gleditsch and Ward codes the same way. Dependencies such as Guam and
  Puerto Rico, which the G&W list does not cover, carry the custom codes the troop data use (see
  below).
- Replaces `get_builddata()`'s `fiscal_category` argument with `facility_category`, which searches
  both levels of the facility taxonomy. `facility_group_title` and `facility_category_title` hold one
  vocabulary split across two columns, and the reports move labels between them--the coarse labels
  arrive under "Facility Group Title" in some years, "Fiscal Category Title" in others, and in the
  facility category column itself from FY2022--so separating them in the data is a reconstruction.
  A value is now matched against the pool of all 192 labels and a row is kept if either column holds
  it, which means callers no longer have to know which header a given report year used. Three labels
  are genuinely present at both levels and return rows from each.
- Adds `include_requests` to `get_builddata()` for dropping budget-request rows, and adds
  `"auth_appn"` to `spend_type`, which had omitted the populated `auth_appn_amount` column.
  `location` and `project` now accept a vector of patterns rather than silently using the first. The
  `spend_type` documentation no longer claims that non-selected amount columns are dropped from the
  output; they are retained.
- Documents which construction fields are reported only for a subset of years, so that filtering on
  `transaction_type`, `pe`, `dollar_type`, `classification` and the rest no longer silently
  restricts the series without explanation.
- Orders the construction data's columns by what a reader looks for first--country, fiscal year,
  location, organization, project, amounts, the fields only some report years carry, and provenance
  last--rather than alphabetically, with each harmonized label immediately followed by the
  `*_reported` string it was derived from. Rows are sorted by country, year, location and descending
  TOA, which collects the rows that report an amount but no usable location at the end of the file
  instead of the beginning.

- **Fixes inflated troop values in `troopdata_rebuild_long`.** Two separate duplication bugs in the
  rebuild caused roughly a fifth of all country-year-quarter observations to be counted twice, and a
  few three times. (1) The country-year scaffold was still grouped when `distinct()` was applied, so
  `countryname` stayed in the distinct key and 23 states whose Gleditsch and Ward list spelling
  differs from the `countrycode` spelling (Romania, Italy, South Korea, Turkey, Russia, Ivory Coast,
  and others) kept two scaffold rows per period; each report value was then summed across both.
  (2) Kane's values are stamped as June observations and were bound in after the reporting-month
  filter, so for 1950-1956 and 2014 forward they were added to the DMDC report for the same period
  rather than used as a fallback. Affected values include Germany, South Korea, Japan, Italy, and
  South Vietnam.
- Fixes country name and code errors flagged on GitHub: ccode 571 (Botswana) was labeled Swaziland,
  and Swaziland/Eswatini appeared under two names. Country names are now assigned in one place and
  applied to both the reports frame and the long frame, so a country code carries the same name in
  every object the package ships.
- Fixes Vietnam. `countrycode`'s Gleditsch and Ward lookup returns 817 (Republic of Vietnam) for
  plain "Vietnam", so reports from 1976 forward were filed under the South Vietnam code and then
  dropped, leaving modern Vietnam with no data. Vietnam is now 817 through 1975 and 816 after.
- Fixes the stepwise imputation covering the December 2022 through June 2023 reporting gap. The
  quarter list was written as `2022.3:2023.3`, and R's colon operator steps by 1, so it covered only
  the two endpoints: the three unreported quarters in between were left empty, while the reported
  September 2023 figures were overwritten with interpolated values that differed from the published
  report for 99 of 168 countries. The gap quarters are now interpolated between the two reported
  quarters that bracket them, and both of those quarters are left as reported.
- External estimates for periods the reports do not cover (Afghanistan, Syria, Iraq, Kuwait, and the
  United Kingdom in 2014) are now applied only where the report carries no branch-level figures to
  add up. Where it does, the reported sum is kept, so `troops_ad` is no longer lower than the sum of
  its own branch columns.
- Separates Guam, the Northern Mariana Islands, and the Marshall Islands, which shared country codes
  in earlier versions. The Northern Marianas move to 1011 and the Marshall Islands to 983, and all
  three now carry their ISO3C codes and a region.
- Fixes Serbia, which appeared as two overlapping series after 2006 because Kane's data codes it as
  345 while the reports and the G&W list use 340.
- Adds ISO3C codes for states that the `gwn` to `iso3c` lookup does not cover (Antigua and Barbuda,
  St. Kitts and Nevis, Sao Tome and Principe, Seychelles, Tonga, Micronesia, Vietnam, and several
  historical states), so searching by ISO3C code no longer silently returns nothing for them.
- `get_troopdata()` resolves a `host` country name through its country code rather than matching
  the name in whichever object is being returned, so `host = "Japan"` now returns the Ryukyu Islands
  rows as well where `reports == TRUE`.
- `get_troopdata()` now raises an error when `host` matches nothing instead of silently returning an
  empty data frame, accepts common alternative spellings (Eswatini, Czechia, Cote d'Ivoire, Turkiye,
  Cabo Verde, Burma, North Macedonia, Timor-Leste), and no longer misroutes hosts to region matching
  because of an operator precedence error in the host type test.
- Fixes the United States total for 2008 onward. It was the sum of every sheet row whose name
  `usmap::fips()` recognizes, which let in two rows from the OVERSEAS block: Puerto Rico, and
  Georgia the country, which shares the state's name (and was then counted again under its own
  code). The total is now the fifty states and DC, taken from the United States block of each
  workbook--1,055,155 rather than 1,055,751 for September 2008. Puerto Rico is its own location
  (country code 6, `PRI`) from 1950 onward. In the reports frame the United States figure from
  September 2023 now includes the Space Force column, which it had omitted.
- Counts the territory personnel that the DMDC reports list alongside the states. From March 2025
  the reports carry Guam, the Northern Mariana Islands, Puerto Rico, and the U.S. Virgin Islands
  twice: under OVERSEAS with the Army at zero, and inside the UNITED STATES block holding the
  personnel the Army reports there. The second set was skipped along with the states and counted
  nowhere. These are overseas locations, so they are now included in each territory's total --
  Puerto Rico is 759 rather than 645 for March 2025, and Guam 6,989 rather than 6,795--and are not
  part of the United States figure. The reports frame keeps both rows, with the second labeled
  "(LISTED WITH STATES)".
- The country-year-quarter data now stops at the latest reported quarter. Every year was expanded
  to four quarters, so adding the March 2026 report produced rows for June, September, and December
  2026 that held zero for every country, the United States included.
- Fixes `troopdata_rebuild_us_states`, which was missing states in 27 of 55 reporting periods. The
  state rows were cut from each sheet with fixed row ranges, but the block is 54, 55 or 58 rows long
  and starts on a different row in some workbooks, so Wyoming was dropped from 18 quarters and West
  Virginia, Wisconsin and (in six of them) Washington from nine more. Every period now carries
  exactly the fifty states and DC. Puerto Rico, which had appeared as a fifty-second "state" from
  March 2025, is an overseas location and is in the country data instead.
- **Fixes `navy_ad`, which was 0 for every country outside the United States from September 2008
  onward.** The branch columns are assembled from differently named report columns in each era, and
  the Navy line named only the pre-2008 ones. Totals were unaffected, so `troops_ad` was right while
  `get_troopdata(branch = TRUE)` returned no Navy personnel anywhere abroad--Japan and Bahrain
  included--in 5,305 country-quarters.
- **Fixes locations that were dropped when a report lists two places under one country code.** The
  build kept only the largest row per country, so where the reports list Japan and the Ryukyu
  Islands (Okinawa) separately, through 1973, one of the two was discarded every year: Japan read
  41,948 for September 1968 where the report shows 41,121 + 41,948 = 83,069. The same rule dropped
  Trieste, Scotland, Jerusalem, the Bonin and Volcano Islands, part of France in 1955-56 and the
  Republic of Panama beside the Canal Zone. Every reported location is now kept, the reports frame
  shows each row, and the country-year data sums them.
- Fixes locations whose names resolved to no country code and were silently left out: Yemen from
  1990, the Marshall Islands (Kwajalein) from 1956, Diego Garcia from 2008 (reported as British
  Indian Ocean Territory), the Kosovo force of 1999-2007 (reported as "Serbia (includes Kosovo)"),
  and Palau, Micronesia, Kiribati, Tonga, Samoa, Seychelles, Grenada, Dominica, Saint Lucia, Saint
  Kitts and Nevis, Antigua and Barbuda, Nauru, and Liechtenstein. These states were in the data at
  zero while the reports list personnel there.
- Fixes Russia for 1971-1976 and 1992-2007, where the value stored was a regional subtotal ("USSR
  and East Europe", "Total - Former Soviet Union") rather than Russia's own row.
- `get_troopdata()` now raises an error when a numeric `host` matches no country code, instead of
  returning an empty data frame. The usual cause is a Correlates of War code: Germany is 260 in the
  Gleditsch and Ward list used here, not 255.
- **Fixes country codes in the construction data.** The C-1 exhibits use their own two-letter
  location codes, several of which are valid ISO codes for a different country, and they were being
  read as ISO codes: Iraq's 70 projects were coded as Iran, Bahrain's 44 as Burundi, the Mariana
  Islands' 121 as Mali, Guantanamo Bay's 40 as the United Kingdom, Turkey's 19 as Tokelau, and
  Kwajalein's 22 as Kuwait, with twelve smaller cases; six more codes (Diego Garcia, Jordan, Norway,
  Luxembourg, the Philippines, Wake Island) resolved to nothing. 424 rows are corrected, using the
  country name each report prints beside the code.
- Fixes Gleditsch and Ward codes in the exercise data: Vietnam was coded 815, a nineteenth century
  polity, rather than 816; Yemen and twelve microstates had no code; and Serbia carried 340 before
  2006, when the list has no Serbia.
- Fixes the `min_duration` and `max_duration` filters in `get_exercises()`, which returned nothing
  whenever the first matching exercise had an unknown start or end day. Dates are now parsed one at
  a time rather than with a single format chosen from the first row.
- **Counts personnel ashore, and carries personnel afloat separately, for 1950 through 2007.** The
  reports before 1977 attribute Navy and Marine Corps personnel afloat to a location in several
  ways--to the country of the nearest port, inside the country's total in 1954-1958 and in
  parentheses beside it in 1953 and 1959-1967, and to selected locations in 1968-1976--and the
  build counted them in that country. A fleet at sea was therefore placed in whichever country it
  was nearest on the day of the count: Greece read 15,066 for September 1960 against 1,976 ashore,
  and Brazil 12,716 for June 1953 against 269. `troops_ad`, `navy_ad` and `marine_corps_ad` now
  hold personnel ashore for every location, the United States included, which is how the reports
  for 1977-2007 already list countries. 477 country-years between 1953 and 1976 are lower as a
  result, by 1.36 million personnel-years in all.
- **Adds an `afloat` argument to `get_troopdata()`**, with three new columns behind it. The
  personnel afloat that a report attributes to a location are kept in `troops_afloat`,
  `navy_afloat` and `marine_corps_afloat`, beside the ashore figures: for countries and
  territories in 1953-1976, and for the United States in 1950 and 1953-2007 (the fleet in home
  waters, which the reports give for the United States and its territories together from 1968).
  `afloat = "exclude"`, the default, leaves them out of every location; `"include"` adds them to
  that location's `troops_ad`, `navy_ad` and `marine_corps_ad`, so Greece reads 15,066 for 1960 and
  the United States 1,029,037 for 2007 rather than 936,447; `"separate"` returns the ashore
  figures with the three afloat columns next to them. Everyone afloat is also carried once,
  worldwide, in a new location, `"Afloat"` (country code 10200, no ISO3C code, region `"Afloat"`),
  with values for 1950 and 1953-2007. It is not a country, so leave it out when adding up
  countries. Under `"exclude"` it holds everyone afloat; under `"include"` and `"separate"` it
  holds only those attributed to no location, so the three choices add up to the same worldwide
  total. From September 2008 the DMDC reports count a ship's crew at its home port, inside the
  state or country figure, and there is no afloat figure, so the argument changes nothing from
  2008 on. For 1954-1956 mobile units temporarily based ashore cannot be separated from personnel
  afloat in the reports and are counted with them.
- **Fixes region queries in `get_troopdata()`.** A `host` that names a region now returns every
  location in that region, one row per location and period, exactly as a query with no `host`
  returns them; the region only chooses which locations come back. It used to return a single row
  per region holding the largest value found in any one country of it, so `host = "Europe"` gave
  246,875 for 1985, which is West Germany alone.
- **Fixes the United States total for 1954-1958 and 1968-2007, which left out Alaska and Hawaii.**
  Where a report has no "United States" line the build kept the continental United States row and
  nothing else, so between 48,000 and 87,000 personnel a year were missing. September 1985 is now
  1,399,473 rather than 1,331,950. With personnel afloat kept in their own columns (above), the
  United States total before 2008 is the fifty states ashore.
- **Uses a Kane row only where the DMDC reports have nothing.** Kane rows are dated June and the
  reports for 1957-2013 are dated September, so both were kept for the same year, and the annual
  figure, the larger of the two, was the Kane one wherever Kane's was higher--Germany, Japan,
  Italy and the United Kingdom in 2006 and 2007 among them. Germany read 85,419 for 2006: the
  report's 64,319 plus 21,100 personnel deployed to Iraq, who are counted in Iraq as well. A
  Kane row is now used only for a country-year in which no report gives a figure. The rows the
  reports print as zero in place of Iraq, Kuwait and Afghanistan in 2002-2007 are not treated as
  figures, so the estimates for those deployments are unchanged. Iraq and Syria from 2018 are also
  left as they were: from December 2017 the reports leave out personnel deployed there and print
  only those assigned permanently (158 and 1 in December 2021), so the figures from public
  reporting are kept beside them. 2021 stays at 2,500 for Iraq and 900 for Syria, and those two
  rows now carry their source.
- Fixes the 2003 and 2004 reports, which are read from PDFs. A figure with a thousands separator
  did not convert to a number, so every location with 1,000 or more personnel lost its row and fell
  back to the Kane total for that year, which has no service branches. Germany, Japan, South Korea,
  the United Kingdom, Italy and others now carry their branch figures for those two years, and Guam
  and Puerto Rico, which had no rows at all, are present.
- Keeps the figures the Navy, Marine Corps, Air Force and Coast Guard reported for December 2022,
  March 2023 and June 2023. Only the Army reported nothing for those quarters, but every column was
  being interpolated, which replaced reported values with estimates: the Marine Corps in Norway read
  24 for March 2023 against 683 reported. Only the Army columns are interpolated now, and the
  totals for those quarters are the sum of the two. The reports data holds those rows as published,
  with the Army columns and the total missing.
- Adds nine territories that have had a country code since the first rebuild and had never reached
  the data, because their names were entered in a different case from the one the reports use:
  Akrotiri, Curacao, Martinique, Sint Maarten, Svalbard, the Spratly Islands, the Coral Sea Islands,
  Bassas da India and the Trucial States. The last two were being counted under India and Oman.
- **The construction data now holds one report per fiscal year.** Every C-1 report covers two or
  three fiscal years, so each year is printed in up to three reports, and the same project-years
  were in the data two and three times: appropriations summed to $599.7 billion against $402.1
  billion in the latest report for each year. Each fiscal year is now taken whole from the most
  recent report that covers it, and supplemental sheets that restate the main sheet are dropped,
  which takes the data from 20,344 rows to 14,070. Matching restatements project by project, as
  before, also merged distinct projects that share a location and a title; those 211 rows are
  restored, and a new `source_row` column gives each row's position in its source sheet. FY2016 is
  the only year still flagged `is_request`. Several fields that only an earlier report printed are
  no longer available for some years; the data documentation lists the coverage of each.
- **Fixes the coordinates in the construction data.** The address sent to the geocoder ended in the
  report's own two-letter code ("Rota, SP", "Misawa AB, JA"), which a geocoder reads as something
  else, so 644 of the 2,808 overseas rows with coordinates were outside their country--Rota in
  Brazil, Misawa on Sumatra, Heidelberg in Guyana--and about 340 domestic rows were in the wrong
  state or abroad. The address now spells out the country or state, and a result is kept only if
  it falls inside that country or state. Rows filed under no country, and locations that are a
  label rather than a place ("Various Locations"), no longer have coordinates.
- **Corrects construction coordinates that were in the right country but not at the installation.**
  The check added above keeps a geocoded point only if it falls inside the country or state the row
  is filed under, which a wrong point can still pass. Compared with where each installation is, 92
  of the 1,406 located addresses were 37 to 2,454 km away. They carry 479 rows and $8.7 billion of
  appropriations, and they include 249 of the 1,706 overseas rows that had coordinates, 15 percent
  of them. A geocoder that does not know a place answers with the centre of the country or state:
  eleven Korean camps, Camp Humphreys among them,
  shared one point in the middle of South Korea, and nine bases in Afghanistan and six in Iraq did
  the same. A name that exists twice resolves to the other place: Yorktown and Langley AFB to the
  Washington suburbs, Camp Butler to Honshu, Incirlik to a village 550 km east of Adana. These, 17
  more found on a second pass and the eight addresses that had no coordinates at all are now
  handled from `data-raw/geocode_overrides.csv`, which gives each point, what it is a point of
  (the base, its airfield, or the nearest town where the base itself could not be found) and the
  page it was read from. 112 addresses (527 rows) are placed by hand and marked
  `geo_source = "manual"`. Five have no coordinates, because the place could not be located (FOB
  Joyce and FOB Wolverine in Afghanistan, Convoy Support Center Scania in Iraq) or because the
  report's location and state contradict each other.
- Restores four construction projects that a filter for total lines had removed because their
  titles begin with "Total": the Total Army School System projects at Augusta, Michigan (FY2002),
  Springfield, Illinois (FY2005), Fort Belvoir (FY2006) and Camp Williams, Utah (FY2007), $59.9
  million of appropriations. Every line of every report with a fiscal year is now in the data, and
  the fiscal-year totals equal the workbooks'.
- The construction data now use the troop data's custom country codes for territories. The
  Gleditsch and Ward list has no code for a dependency, so `gwcode` was missing for 320 rows and a
  numeric `host` could not reach them. They now carry the codes `get_troopdata()` uses for the
  same places: Puerto Rico 6, Greenland 1002, Diego Garcia 1004, Guam 1008, the Northern Mariana
  Islands 1011, the U.S. Virgin Islands 1013, Wake Island 1014, American Samoa 1041 and Ascension
  Island 1042. Every row that has an `iso3c` now has a `gwcode`.
- **Fixes `get_troopdata(state_data = TRUE, guard_reserve = TRUE)`, which failed** with "Column
  `troops_all` doesn't exist" in every version that has had state data. `troops_all` is added to
  `troopdata_rebuild_us_states`, defined as in the country data: active duty plus the guard and
  reserve components.
- Makes the `get_troopdata()` warning about region names accurate. It is raised only when a `host`
  string that is part of a region's name does not return one whole region, and it says what the
  string matched: `"Africa"` and `"America"` are read as country names (South Africa and the
  Central African Republic; American Samoa), and `"Asia"` matches three regions. A full region
  name, a string that matches one region, and a country such as `"South Africa"` raise no warning.
- `get_troopdata()` now reads `host = NA` as no host and returns every location, as
  `get_builddata()` and `get_basedata()` do. It failed with "object 'host.type' not found", although
  the help gave NA as the default and one of the function's own warnings recommended it. A missing
  value inside a vector of hosts is dropped with a warning; it used to be read as the text "NA", so
  `host = c("Japan", NA)` returned every country with "na" in its name. The help for `host` no
  longer says that an ISO3C code cannot reach Greenland, Bermuda, the Azores, Diego Garcia or
  Yugoslavia, all of which have codes.
- `get_troopdata()` now returns locations that share an ISO3C code on rows of their own when
  `host` is an ISO3C code. A location with no code of its own carries its parent's, so the Azores
  carry `"PRT"`, Wake, Midway and Johnston Islands share `"UMI"`, and Akrotiri carries `"GBR"`.
  Those locations were merged into one row per code and year that kept the first location's name
  and the largest of their values: `host = "PRT"` for 1958 returned a single row named Portugal
  with 2,428 personnel, where the data have 71 in Portugal and 2,428 in the Azores, and
  `host = "UMI"` returned Midway without Wake and Johnston Islands. The function's warning already
  said the rows were separate. Across all years, 165 location-years were not returned, 35 rows
  showed another location's value, and the rows returned were 10,405 personnel short. Eleven codes
  were affected: ARE, AUS, CHL, CHN, GBR, GEO, MHL, MYS, PRT, TZA and UMI. Each location now has
  its own row with its own country code, in the same columns as before. Results for a country
  name or a country code as `host` are unchanged.
- Documents a gap in the DMDC reports from December 2015 to December 2017. In those nine reports
  between 77,000 and 105,000 personnel, nearly all Navy, are listed in the United States block
  under "Armed Forces Europe", "Armed Forces Pacific", "Armed Forces the Americas" or "Unknown"
  rather than in a state. They cannot be traced to a state or a country, so they are in none of
  the figures, and the United States total and Navy figures are lower in those quarters. The data
  are left as reported.
- Adds regression tests that compare every country-year-quarter value against the underlying DMDC
  report and check code, name, and ISO3C consistency.
- Adds updated troopdata from the spring of 2025 through December of 2025.
- Adds data for individual US states. Users can now use the `state_data` argument to retrieve data from individual US states from 2008 forward.
- Adds the `get_exercises()` function that allows users to retrieve data on military exercises compiled by Vito D'Orazio and Kevin Galambos.
- Smaller bug fixes and improved coding to speed compiling underlying data. 

# troopdata 1.0.4

- Fixes error where two 2008 reports were included leading to inflated values for 2008.
- Changes Eritrea country code to Ethiopia to reflect corresponding polity in older reports.
- Change deployment values assigned to Hong Kong after 1997 to China. 
- Improved documentation to better explain changes in rebuilt data starting with version 1.0.0 and where discrepancies might arise between the updated data and Kane's original collection. 

# troopdata 1.0.3

* Added most recent deployment data through December 2024.
* Fixes error where some 2008 values were double counted. Germany for example.
* Adjusts count for some states like Germany and UK to better reflect troop counts assigned to those states between 2001 and 2011. This adjustment relies on the baseline data from the DMDC reports for a select group of countries and removes the added values the DMDC reports show as affiliated with those countries that are on deployment to other countries as a part of OIF or OEF operations.
* Adds the `troops_all` variable to reflect the sum of all active duty, guard, and reserve, personnel assigned to host country and removes some guard and reserve personnel that were mistakenly included in the overall total in the `troops_ad` variable, which should just reflect active duty personnel. 
* Fixed some errors where some countries were appearing twice in the data. These were primarily countries with small deployments.
* Added tests to check for duplicate entries in the data.


# troopdata 1.0.2

* Fixes error in package build. Not related to data accuracy.


# troopdata 1.0.1

* Fixed error in Iraq troop deployment values for 2006 and 2007. The estimated values for the entire year were being used as quarterly values and summed up to create incorrect annual values.


# troopdata 1.0.0

* Major rebuild of the troopdata package!
* Complete rebuild of the `get_troopdata()` function to allow for more flexible data retrieval. The new data are based on a fresh scraping of the DMDC reports from 1950 through 2024.
* Deployment data updated through 2024.
* Branch data now available from 1950 through 2024.
* Quarterly report values can be retrieved from 2008 through 2024.
* National Guard and Reserve deployment data now available from 2008 through 2024.
* Civilian assignment data now available from 2008 through 2024.
* More flexible host search field. Search by Correlates of War country code, ISO3C country code, country name, or region.
* Now includes additional deployment data on territories not included in the original deployment data (e.g. Antarctica).
* Users can now use the `get_troopdata()` function to retrieve the original DMDC reports on which the aggregate data is based.
* Fixes error when selecting multiple countries in base and build data functions.




# troopdata 0.1.5

* Addresses a coding error producing false 0 values for some earlier deployments.

# troopdata 0.1.4 Data Update

* September 2021 Counts for Total Troops, Army, Navy, Air Force, and Marine Corps added

* Syria, Iraq, and Afghanistan include estimated totals from news reports due to DMDC not providing estimates.
* Afghanistan estimated at 0 for all categories due to withdrawal finishing on August 31st.
* Syria estimated at 900, no estimates for branches: https://www.politico.com/news/2021/07/27/troops-to-stay-in-syria-biden-500848
* Iraq estimated at 2500, no estimates for branches: https://www.nytimes.com/2021/09/20/us/troops-deploy-iraq.html
  * ccode 1012 Taiwan deleted for 2008-2020
  * ccode 713 Taiwan now properly holds troop counts for 2008-2021
  * Côte d'Ivoire country name reformatted to hopefully cause fewer issues
  * São Tomé and Príncipe name reformatted to hopefully cause fewer issues

* Updated numbers:

 * British Virigin Islands 2016
 * Uruguay 2014-2016, 2020
 * Uzbekistan 2014-2016, 2020
 * Venezuela 2015-2017
 * Vietnam 2012, 2014-2017, 2020
 * US Virgin Islands 2012-2017, 2020
 * Wake Island 2011-2017, 2020
 * Yemen 2009, 2011-2017, 2019-2020
 * Zambia 2009, 2012-2017, 2019-2020
 * Zimbabwe 2009, 2011-2017, 2019-2020
 * Unknown 2009, 2011-2020
 * United States counts updated for Army, Navy, Air Force, and Marine Corps, 2006-2021
 * United States total no longer counts Coast Guard deployments for 2008-2020 to be consistent with other countries

* Note: We plan to include Coast Guard counts for all countries from 2008-2020 in a future update and a second total count


# troopdata 0.1.4

* Introduces get_builddata() function which returns a data frame containing location-year U.S. military construction spending in thousands of current US dollars.
* Adds option to generate regional sums of military personnel by setting host = "region" when calling get_troopdata() function.
* Fixed multiple errors with get_troopdata():
  * 2014 UK values were missing from data.

  * Fixes error with get_troopdata() Kuwait 2006 troop values showing up as 0. Replaced with estimate derived from supplementary sources. See notes below.

  * Provides updated estimated for Iraq (2006, 2007), Kuwait (2006, 2007), and Syria (2018, 2019, 2020)

  * Iraq, Afghanistan, and Syria data for 2018-2020 were estimated from reports and we continue to update those numbers based on information we can get. Just Security has engaged in a legal process and sued the DOD to get precise counts of troops in Iraq, Afghanistan, and Syria, but the DOD has obfuscated the total counts by classifying the majority of deployments as temporary. Read through the whole saga here: https://www.justsecurity.org/75124/just-security-obtains-overseas-troop-counts-that-the-pentagon-concealed-from-the-public/. Thanks to Thomas Campbell at Boise State for pointing out this data. To reflect new public data, we have updated the estimates as follows:

  * Changes:
 
     * Afghanistan 2020: Updated to 8600 from 4500.
    
     * Afghanistan 2019: Updated to 13000 from 14500
    
     * Syria 2018: Updated to 1700 from 2000
    
     * Syria 2019: Updated to 1000 from 400
    
     * Syria 2020: Updated to 900 from 600

     * Kuwait 2006 and 2007 numbers didn’t make sense as it goes from 42600 troops in 2005 to 0 for two years and then back up to 42285 in 2008. For 2006 and 2007, these numbers were rolled into a total “Operation Iraqi Freedom” count that included all nearby countries. We have reverse-engineered this a bit and have new numbers for Kuwait. Kuwait 2006 updated to 44,400 from 0. We got this number from 185,500 total OIF and subtracting the average from 2006 reported in the above document. Kuwait 2007 updated to 48500 from 0.

     * Iraq 2006: Updated to 141100 from 185500, using 2006 average from here: https://fas.org/sgp/crs/natsec/R40682.pdf

     * Iraq 2007: Updated to 170000 from 218500, source for the first number is: https://www.reuters.com/article/us-iraq-usa-pullout/timeline-invasion-surge-withdrawal-u-s-forces-in-iraq-idUSTRE7BE0EL20111215

     * Iraq 2006 and 2007: Individual force counts changed to NA.

These numbers continue to be estimates in a few cases, so we will continue to update these numbers as we get more reliable figures.


# troopdata 0.1.3

* Fixed error where Kane data classifies troops as being present in Vietnam during the Vietnam War but COW recognizes South Vietnam as a separate country.
* Fixed error where `get_troopdata()` function was always returning branch data.

# troopdata 0.1.2

* Modified version number down to better adhere to R package best practices.
* Improved documentation for package and functions.

# troopdata 1.1.0

# troopdata 1.0.0

* troopdata version 1.0.0 release!
* New package providing access to US military deployment and overseas basing data.
* `get_troopdata()` returns a data frame of country-year observations with options to return total troop deployment values or service branch-specific deployment values.
* `get_basedata()` returns a data frame containing David Vine's US basing data with options to return site-specific data or country-level base count data.
* Minor bug fixes.

# troopdata 0.0.0.9000

* Added a `NEWS.md` file to track changes to the package.
