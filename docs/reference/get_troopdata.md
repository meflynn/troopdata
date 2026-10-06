# Function to retrieve customized U.S. troop deployment data

`get_troopdata()` generates a customized data frame of U.S. military
personnel by location and year, for every country, territory and other
location in which the Department of Defense reports personnel, the
United States included. It can also return the figures by report period
(`quarters`), the figures for the fifty states and the District of
Columbia (`state_data`), and the rows of the underlying reports
(`reports`).

## Usage

``` r
get_troopdata(
  host = NULL,
  branch = FALSE,
  startyear = 1950,
  endyear = 2026,
  quarters = FALSE,
  guard_reserve = FALSE,
  civilians = FALSE,
  state_data = FALSE,
  reports = FALSE,
  afloat = c("exclude", "include", "separate")
)
```

## Arguments

- host:

  A Gleditsch and Ward numeric country code, an ISO3C code, or a country
  name, for the host country or countries in the series. Territories and
  other locations that the Gleditsch and Ward list does not cover carry
  the package's own codes: Puerto Rico is 6, Greenland 1002 and Guam
  1008, and
  `unique(troopdata_rebuild_long[, c("ccode", "countryname")])` lists
  them all. These are not Correlates of War codes: Germany is 260 here,
  not 255. The values given must all be of one kind; a value that
  matches nothing is left out, and a warning names it. A region name can
  be given instead; see below. With `state_data = TRUE`, give a state
  name or a numeric FIPS code. State names are matched without regard to
  case: a full name returns that state alone (`"kansas"` is Kansas, and
  `"Virginia"` is not also West Virginia), and part of a name returns
  every state whose name contains it. The default, `NULL`, returns every
  location, and so does `NA`. A missing value inside a vector of hosts
  is dropped with a warning.

  A region is asked for by name. `host` is matched, as a substring and
  ignoring case, against the `region` column
  (`unique(get_troopdata()$region)` lists the names), and every location
  in a matching region is returned, one row per location and period,
  exactly as a query with no `host` returns them. Nothing is added up;
  the `region` column says which region each row belongs to. A string
  that matches several regions returns the locations of each: `"Asia"`
  matches `"East Asia & Pacific"`, `"South Asia"` and
  `"Europe & Central Asia"`. A string that matches a country name is
  read as a country, so `"Africa"` returns South Africa and the Central
  African Republic and `"America"` returns American Samoa; give enough
  of the region's name to tell them apart (`"Sub-Saharan Africa"`,
  `"North America"`). In both of these cases a warning says what the
  string matched. A full region name, or a string that matches one
  region only, raises none.

  A country name is matched as a substring, so a query reaches every
  historical form of a divided country: `"Korea"` returns North and
  South, `"Vietnam"` returns North, South and the unified state,
  `"Czech"` returns Czechoslovakia and the Czech Republic. `"Germany"`
  returns both the Federal Republic (260) and the German Democratic
  Republic (265); `"West Germany"` and `"East Germany"` reach them
  individually. Where a name spans several country codes the rows are
  returned separately, one per code and period, and a warning says which
  codes matched – aggregate across `ccode` for a single national series.

  Note that matching on ISO3C codes cannot reach every location in the
  data. A few locations have no ISO3C code and are left out of any ISO3C
  filter: at present the British West Indies (1950-1965), the Spratly
  Islands and Kashmir. Passing `host` as a country name or a Gleditsch
  and Ward country code reaches them, and a warning names them and gives
  the current count whenever an ISO3C filter covers years in which they
  have rows. Most territories and historical states do have a code:
  Greenland is `"GRL"`, Bermuda `"BMU"`, Diego Garcia `"IOT"` and
  Yugoslavia `"YUG"`. A unit with no code of its own carries its
  parent's: the Azores carry Portugal's, `"PRT"`. Locations that share a
  code are returned on rows of their own, so `host = "PRT"` returns
  Portugal and the Azores separately, each with its own country code.
  Add them up to get a total for the ISO3C code.

  Personnel afloat have a location of their own, named `"Afloat"`
  (country code 10200, no ISO3C code, region `"Afloat"`), with values
  for 1950 and 1953 through 2007. It is returned with everything else
  when `host` is left empty; `host = "Afloat"` or `host = 10200` returns
  it alone. It is not a country, so leave it out when adding up
  countries. See `afloat` for what it holds.

- branch:

  Logical. Should the function return the total only, or the total and
  the active duty figures for the individual branches (`army_ad`,
  `navy_ad`, `air_force_ad`, `marine_corps_ad`, `coast_guard_ad` and
  `space_force_ad`)? Default is FALSE.

- startyear:

  The first year for the series. The default is set to 1950. The state
  data begin in 2008.

- endyear:

  The last year for the series. The default is the maximum year in the
  currently published data. The latest year holds only the reports
  published so far, so its annual figures can rest on fewer reports than
  those of a full year.

- quarters:

  Logical. Should the function return the figures of each report rather
  than one row per year? If `FALSE`, the default, each row is a location
  and year, and every column holds the largest value reported for that
  location in that year. If `TRUE`, each row is a location and report
  period, with `month` and `quarter` columns, and its figures are those
  of that one report. See "How values are handled".

- guard_reserve:

  Logical. Should the function return values for the National Guard and
  Reserve, and `troops_all`, the total of active duty, guard and reserve
  personnel? The reports give guard and reserve figures from 2008; they
  are missing (`NA`) for earlier years, where `troops_all` equals
  `troops_ad`. Default is FALSE.

- civilians:

  Logical. Should the function return values for civilian DoD personnel?
  The reports give them from 2008, and they are missing (`NA`) for
  earlier years. Default is FALSE.

- state_data:

  Logical. Should the function return the data for the fifty U.S. states
  and the District of Columbia rather than for countries? These data
  begin in 2008, and `host` is then a state name or a numeric FIPS code.
  Default is FALSE.

- reports:

  Logical. Should the function return reports for the specified
  countries and years? Default is FALSE. The reports are returned as
  reported, without aggregation, so a country code may appear on more
  than one row in a period where the report breaks that country's
  territories out separately. Requires `quarters = TRUE`.

- afloat:

  How to treat Navy and Marine Corps personnel afloat in the reports for
  1950 through 2007. One of `"exclude"` (the default), `"include"` or
  `"separate"`.

  Those reports count personnel ashore and personnel afloat separately,
  and attribute some of the personnel afloat to a location: to the
  country of the nearest port or the country whose line they are printed
  on (1953-1976), and, for the fleet in home waters, to the United
  States (1950, 1953-2007; from 1968 the reports give that figure for
  the United States and its territories together). The rest are given
  for a region or for the world only.

  - `"exclude"`: every location holds personnel ashore. `troops_ad`,
    `navy_ad` and `marine_corps_ad` leave out anyone afloat, and the
    `"Afloat"` location holds everyone afloat worldwide.

  - `"include"`: personnel afloat who are attributed to a location are
    added to that location's `troops_ad`, `navy_ad` and
    `marine_corps_ad`. The `"Afloat"` location holds only those
    attributed to no location.

  - `"separate"`: the figures ashore are as for `"exclude"`, and the
    personnel afloat attributed to each location are returned beside
    them in `troops_afloat`, `navy_afloat` and `marine_corps_afloat`.
    `navy_ad` and `marine_corps_ad` are returned as well, whatever
    `branch` is set to, so the two can be compared. The `"Afloat"`
    location holds only those attributed to no location.

  Added up over every row, the three give the same total; they differ in
  where the personnel afloat are put. In the three afloat columns a zero
  means a report that lists personnel afloat by location has none for
  that one (1953-1976). A missing value means the report gives no figure
  for the location: 1950 and 1977-2007 for everywhere but the United
  States (and Cuba in 1950, where the report puts 171 Marines afloat),
  1951 and 1952, and every year from 2008. For 1954-1956 the figure also
  holds mobile units temporarily based ashore, which those three reports
  do not separate.

  From September 2008 the DMDC reports count a ship's crew at its home
  port, inside the state or country figure, and there is no afloat
  figure at all, so the argument changes nothing from 2008 on and has no
  effect on `state_data = TRUE`. Navy figures on either side of 2008 are
  closest to comparable with `afloat = "include"`.

## Value

A data frame with one row per location and year, or one row per location
and report period when `quarters = TRUE`. Each row carries the
location's identifiers (`ccode`, `iso3c`, `countryname` and `region`, or
`state` and `fipscode` for the state data), the `year` (with `month` and
`quarter` when `quarters = TRUE`), `troops_ad`, the number of active
duty personnel, and the columns asked for with `branch`,
`guard_reserve`, `civilians` and `afloat`. With `reports = TRUE` the
columns are those of
[`troopdata_rebuild_reports`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_reports.md),
with its three afloat columns only when `afloat = "separate"`. The
section "How values are handled" says what the figures are and how they
are put together.

## How values are handled

The figures come from the personnel reports of the Department of
Defense, published today by the Defense Manpower Data Center (DMDC). The
rules below say how the reports become the values this function returns.
The "Rebuild Notes" article on the package website gives more
background.

**Annual values are the highest value reported in the year.** With
`quarters = FALSE` every column holds the largest value reported for
that location in that year. It is not an average, and it is not the
figure of one fixed month. The data have one report a year through 2012
(dated June for 1950 and 1953-1956, and September from 1957), two for
2013 (September and December) and four a year from 2014 (March, June,
September and December), so the rule matters mainly from 2013 on. The
latest year holds only the reports published so far.

The maximum is taken for each column separately, so `troops_ad` can come
from one report and `army_ad` or `navy_ad` from another. The branch
columns of an annual row therefore need not add up to its `troops_ad`,
and `troops_all` need not equal `troops_ad` plus the guard and reserve
columns. For Japan in 2019 the four reports give 56,134, 55,327, 55,245
and 57,094 active duty personnel. The annual `troops_ad` is 57,094, the
December figure, while the annual `army_ad`, 2,671, is the June figure
and the annual `navy_ad`, 20,846, is the March figure. Use
`quarters = TRUE` for figures that all come from one report.

**Totals.** `troops_ad` is active duty personnel. In the country data a
row that comes from a report has a `troops_ad` equal to the sum of its
branch columns. The state data keep the total each report prints, which
is lower than the sum of the branch columns for some states in June
2021, December 2021 and March 2022, so the states do not add up to the
United States figure in those three quarters. `troops_all`, returned
with `guard_reserve = TRUE`, is `troops_ad` plus the seven National
Guard and Reserve columns. The United States figure is the fifty states
and the District of Columbia. Puerto Rico, Guam and the other
territories are locations of their own and are not part of it.

**Zeros.** A country that a report does not list has 0 for that period.
A zero therefore means either that the report prints zero or that it
does not list the country. Territories and the other locations that
carry the package's own codes are treated differently, as are a few
small states in the years before their independence: they have a row
only for the periods in which a report lists them, so an unlisted
territory is absent from the result rather than zero.

**Missing values.** `NA` means that the reports give no figure of that
kind: the guard, reserve and civilian columns and `coast_guard_ad`
before 2008, `space_force_ad` before September 2023, the branch columns
for 1951 and 1952, and the afloat columns as described under `afloat`.
In annual output a value is missing only if it is missing in every
report of that year. Otherwise it is the largest of the values reported.

**Figures that are not taken from a report.**

- 1951 and 1952 have no report. `troops_ad` for those years moves in
  equal steps from the June 1950 figure to the June 1953 figure, and the
  branch columns are missing. This is done for countries. Most
  territories and other locations with the package's own codes, the
  `"Afloat"` location among them, have no rows for those two years.

- The Army reported nothing for December 2022, March 2023 and June 2023.
  In the country data `army_ad`, `army_national_guard` and
  `army_reserve` for those quarters move in equal steps from the
  September 2022 figure to the September 2023 figure, and the totals are
  those figures plus what the other services reported. The state data
  and the reports (`reports = TRUE`) are left as published, with the
  Army figures and the totals missing for those three quarters. The one
  exception is the United States row of the reports, which is not a line
  of a report. For those quarters it carries a fixed Army figure of
  404,114 and zeros, not missing values, in the Army guard and reserve
  columns.

- The June 2023 report prints its civilian columns, and five of its
  guard and reserve columns, one row low for part of the overseas list,
  so that Qatar's line holds Puerto Rico's figures and Uruguay's the
  United Kingdom's. The country data take each figure from the line
  below the one it is printed on. `reports = TRUE` shows the report as
  published.

- Where the reports do not give the personnel deployed to a war zone, a
  figure from Kane's data or from public reporting is used: Afghanistan
  for 2001-2005 and 2018-2020, Iraq for 2003-2007 and 2018-2021, Kuwait
  for 2003-2007 and Syria for 2018-2021. These are totals only, with
  zeros in the branch columns. From December 2017 the reports leave out
  personnel deployed to Afghanistan, Iraq and Syria, and no outside
  figure is used after those years, so the values for Afghanistan from
  2021 and for Iraq and Syria from 2022 are the handful of personnel the
  reports print and understate the U.S. presence. With
  `quarters = TRUE`, the outside figures for Iraq in 2018-2021 and for
  Syria in 2021 are on the June row only, and the other quarters of
  those years hold what the report prints, which is zero or close to it.

- The reports for 1957 through 2013 are dated September (and December in
  2013). A row dated June in those years is not a report. It holds a
  figure from Kane's data, or one of the figures above, and is kept only
  for a location and year in which no report gives a figure or the
  report prints a zero in its place. Nearly all of these rows are zero.

The `source` column of
[`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md)
says where a figure comes from, with two exceptions: the rows of the
three Army quarters carry the label of their report, and the Iraq figure
of 5,200 for June 2018, 2019 and 2020 has no label.

**Where personnel are counted.** Personnel are counted at the location
the report lists them under. Personnel that a report lists under no
location (lines such as "Transients", "Undistributed", "Departmental
Headquarters" and "Unknown") are not in the data, so the rows do not add
up to the worldwide total the report prints. Where a report lists two
places under one country code (Japan and the Ryukyu Islands through
1973, for example) the country figure is their sum, and `reports = TRUE`
shows each row. For 1950 through 2007 the figures are personnel ashore,
and personnel afloat are handled by the `afloat` argument. From
September 2008 the reports count a ship's crew at its home port, inside
the country or state figure. From December 2015 to December 2017 the
reports list between 77,000 and 105,000 personnel, nearly all Navy, in
the United States block but in no state. They cannot be traced to a
state or a country and are in none of the figures, so the United States
total and its Navy figure are lower in those quarters.

## References

Tim Kane. Global U.S. troop deployment, 1950-2003. Technical Report.
Heritage Foundation, Washington, D.C.

Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2022.
"Global U.S. military deployment data: 1950-2020." Conflict Management
and Peace Science. 39(3): 351-370.

## Author

Michael E. Flynn

## Examples

``` r

if (FALSE) { # \dontrun{
library(tidyverse)
library(troopdata)

example <- get_troopdata(host = "United States",
                        branch = TRUE,
                        startyear = 1980,
                        endyear = 2015)

head(example)

} # }
```
