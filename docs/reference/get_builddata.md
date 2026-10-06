# Function to retrieve customized U.S. military construction spending data.

`get_builddata()` subsets `build_data_20260918` to a customized data
frame containing location-project-year observations of U.S. military
construction and housing spending, as published in the U.S. Department
of Defense Comptroller Annual Report C-1 exhibits. Users can filter by
host country/location, organization, transaction type, facility title,
budget activity, project title, spending type, and amount range.

## Usage

``` r
get_builddata(
  host = NA,
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
  endyear
)
```

## Arguments

- host:

  Character or numeric. If character, the three-letter ISO3C country
  code (`iso3c` field), or a vector of such codes (e.g.,
  `c("KWT", "JPN", "DEU")` for Kuwait, Japan, and Germany). Matching is
  case-insensitive. If numeric, the value is treated as a Gleditsch and
  Ward (G&W) country code, or vector of codes (`gwcode` field), matched
  exactly. Domestic (US) construction is coded as `"USA"` / `2`. Use
  `NA` (the default) to return all locations.

  The G&W system does not assign codes to dependencies. Those locations
  carry the custom codes that the troop deployment data use for the same
  places, so one code selects a place in both data sets: Puerto Rico
  (`6`, `"PRI"`), Greenland (`1002`, `"GRL"`), Diego Garcia (`1004`,
  `"IOT"`), Guam (`1008`, `"GUM"`), the Northern Mariana Islands
  (`1011`, `"MNP"`), the U.S. Virgin Islands (`1013`, `"VIR"`), Wake
  Island (`1014`, `"UMI"`), American Samoa (`1041`, `"ASM"`) and
  Ascension Island (`1042`, `"SHN"`). Roughly a quarter of rows report
  an amount but no usable location (`"Unspecified Worldwide Locations"`
  and similar) and have neither code.

- location:

  Character. A string or regular expression to match against
  `location_name` and `location_full_name`. Matching is
  case-insensitive. A vector of patterns is collapsed into a single
  alternation. Use `NA` (the default) to return all locations.

- organization:

  Character. One or more organizations to filter by, given as full
  names: `"Army"`, `"Navy"`, `"Air Force"`, `"Defense-Wide"`,
  `"Special Operations Command"`, `"Defense Logistics Agency"`,
  `"Defense Health Agency"`,
  `"Department of Defense Education Activity"`,
  `"National Security Agency"` and other defense agencies. Matching is
  case-insensitive and unmatched values raise an error. Use `NA` (the
  default) to include all organizations. See
  `sort(unique(troopdata::build_data_20260918$organization))` for the
  full list, and `organization_reported` for the abbreviation each
  source sheet used.

  There is no `"Marine Corps"` value: the C-1 exhibits carry Marine
  Corps construction in the Navy accounts. Guard and reserve components
  appear in `appn_title` rather than here. For FY2004-FY2007 the service
  of an Army, Navy or Air Force line is read from the "Treasury Agency"
  column of the report, which is where those workbooks print it.

- transaction_type:

  Character. One or more transaction types to include: `"BUDGET"`,
  `"REPROGRAM"`, `"REDUCTION"`, `"CONGRESSIONAL RESCISSION"`, or
  `"PUBLIC LAW RESCISSION"`. Use `NA` (the default) to include all
  transaction types. NOTE: this field is reported for FY2001 and FY2002
  only, so filtering on it restricts the result to those years.

- facility_category:

  Character. One or more facility titles to filter by, at either level
  of the DoD facility taxonomy: the coarse group
  (`"Operational facilities"`, `"Family housing operations"`,
  `"Training facilities"`) or the finer three-digit category
  (`"Training buildings"`, `"Airfield operational buildings"`,
  `"Aircraft maintenance facilities"`). Matching is case-insensitive and
  unmatched values raise an error. Use `NA` (the default) to include all
  facility titles.

  A value is matched against `facility_group_title` and
  `facility_category_title` together, and a row is kept if either column
  holds it. The two columns are levels of one vocabulary and the reports
  do not keep them apart: the coarse labels arrive under the header
  "Facility Group Title" in some years, "Fiscal Category Title" in
  others, and in the FY2022-forward workbooks in the facility category
  column itself. Separating them in the data is therefore a
  reconstruction, and searching both is the only way to filter without
  having to know which header a given report year used. Three labels
  (`"Energy conservation"`, `"Family housing P&D"`,
  `"NATO security investment program"`) are genuinely present at both
  levels and return rows from each.

  See
  `sort(unique(c(troopdata::build_data_20260918$facility_group_title, troopdata::build_data_20260918$facility_category_title)))`
  for the 190 values present in the data. Not every row carries a
  facility title, so filtering on this argument drops the rest.

- budget_activity:

  Character. One or more budget activity titles to filter by (e.g.,
  `"MAJOR CONSTRUCTION"`, `"PLANNING AND DESIGN"`, `"LEASING"`). These
  labels are stored in upper case, but matching is case-insensitive. Use
  `NA` (the default) to include all budget activities. Reported for
  FY2001 onward.

- project:

  Character. A string or regular expression to match against
  `project_title`. Matching is case-insensitive. A vector of patterns is
  collapsed into a single alternation. Use `NA` (the default) to return
  all projects.

- spend_type:

  Character. The amount column used for dropping missing values and for
  applying `min_amount` / `max_amount`. One of:

  - `"all"` (default): no amount column is required to be present;
    amount filters are applied to `toa_amount`

  - `"appn"`: appropriations (`appn_amount`), FY2000 onward

  - `"auth"`: authorizations (`auth_amount`), FY2000 onward

  - `"auth_appn"`: authorized for appropriation (`auth_appn_amount`),
    FY2001 onward

  - `"toa"`: total obligational authority (`toa_amount`), FY2001 onward

  When `spend_type` is not `"all"`, rows where the selected amount is
  `NA` are dropped. All amount columns are retained in the output in
  every case. Note that `toa_amount` is not reported for FY2000, so an
  amount filter with `spend_type = "all"` or `"toa"` excludes that year.

- min_amount:

  Numeric. Minimum spending amount in thousands of current US dollars.
  Rows below this threshold are excluded. Use `NA` (the default) for no
  lower bound.

- max_amount:

  Numeric. Maximum spending amount in thousands of current US dollars.
  Rows above this threshold are excluded. Use `NA` (the default) for no
  upper bound.

- include_requests:

  Logical. Each C-1 report covers two or three fiscal years, the last of
  them as a budget request, and the data holds every fiscal year from
  the most recent report that covers it. That is an enacted or actual
  figure for every year except FY2016, whose only report among the
  source files is the one that requests it. FY2010 also has 26 lines
  that come from an overseas contingency operations request sheet and
  are on no enacted sheet. `TRUE` (the default) returns everything, with
  those rows flagged by the `is_request` column. `FALSE` drops FY2016
  and the 26 FY2010 lines.

- startyear:

  Numeric. The first fiscal year for the series.

- endyear:

  Numeric. The last fiscal year for the series.

## Value

A data frame of location-project-year observations of U.S. military
construction spending. Amount fields are in thousands of current US
dollars.

## Details

Each fiscal year is taken whole from the most recent C-1 report that
covers it, so a project-year appears once. A row is one line of that
report; `source_file`, `source_sheet` and `source_row` identify it.

Several fields appear only in a subset of years, because the C-1 exhibit
layout changed over time and a later report does not always print what
an earlier one did. `transaction_type` and `appn_title` are
FY2001-FY2002 only; `pe` FY2003-FY2004; `dollar_type` and
`existing_mission` FY2003-FY2005; `location_code` FY2000-FY2006;
`facility_category_code` FY2000 and FY2003-FY2006; `project_number`
FY2000-FY2006 and FY2013 onward; `state_country_sort` FY2006;
`classification` FY2011 onward; `facility_category_title` FY2003-FY2005,
FY2007-FY2021 and FY2026. FY2006 reports appropriations only:
`toa_amount`, `auth_amount`, `auth_appn_amount` and
`budget_activity_title` are missing for that year, and `toa_amount` for
FY2000. `percent_recapitalization` has no values. Filtering on one of
these implicitly restricts the result to the years that report it.

The `*_reported` columns (`organization_reported`,
`budget_activity_title_reported`, `facility_category_title_reported`,
`location_name_reported`, `project_title_reported`) preserve the label
exactly as printed in the source workbook, before harmonization.
`source_file`, `source_sheet`, `source_row`, `report_year`, and
`sheet_type` record provenance and can be used to trace any row back to
the originating exhibit.

`latitude` and `longitude` are present only where the location was found
inside the country or state the row is filed under. Rows filed under no
country (unspecified, worldwide and classified locations) and rows whose
location is a label rather than a place (`"Various Locations"`) have
none. `geo_source` says where a point came from: a geocoding service, or
`"manual"` for the installations the services placed at the centre of
the country or at another place of the same name, which are entered by
hand.

## References

Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2020.
"Outside the wire: US military deployments and public opinion in host
states." *American Political Science Review*. 114(2): 326-341.

## Author

Michael E. Flynn

## Examples

``` r

if (FALSE) { # \dontrun{
library(troopdata)

# All observations from 2008 through 2019
example <- get_builddata(startyear = 2008, endyear = 2019)

# Kuwait and Japan, budget transactions only. transaction_type is reported
# for FY2001 and FY2002 only.
example2 <- get_builddata(
  host = c("KWT", "JPN"),
  transaction_type = "BUDGET",
  startyear = 2001,
  endyear = 2002
)

# Army and Navy major construction, TOA >= $10 million
example3 <- get_builddata(
  organization = c("Army", "Navy"),
  budget_activity = "MAJOR CONSTRUCTION",
  spend_type = "toa",
  min_amount = 10000,
  startyear = 2015,
  endyear = 2023
)

# Projects matching "hospital" in title
example4 <- get_builddata(
  project = "hospital",
  spend_type = "appn",
  startyear = 2010,
  endyear = 2023
)

# Enacted aircraft maintenance construction, excluding budget requests
example5 <- get_builddata(
  facility_category = "Aircraft maintenance facilities",
  include_requests = FALSE,
  startyear = 2010,
  endyear = 2024
)
} # }
```
