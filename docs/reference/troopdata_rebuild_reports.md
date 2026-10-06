# DMDC Deployment Reports

`troopdata_rebuild_reports` returns a data frame containing DMDC reports
on US military deployments.

## Usage

``` r
troopdata_rebuild_reports
```

## Format

A data frame with one row per line of a report, including the following
variables. A country code can appear on more than one row in a period,
because the rows keep the locations and names the reports print (Japan
and the Ryukyu Islands are both under 740, for example).

- `ccode`:

  A numeric vector of Gleditsch and Ward country codes, with the
  package's own codes for territories and other locations the list does
  not cover. See
  [`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md).

- `iso3c`:

  A character vector of ISO three character country codes.

- `countryname`:

  A character vector of country names. They are tidied but not fully
  standardized, so a code can carry more than one name here and a name
  can differ from the one in
  [`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md)
  (260 is `"Germany"` here). `Location` holds the name as the report
  prints it.

- `region`:

  Geographic region, as in
  [`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md),
  but missing for a number of territories and historical locations.

- `year`:

  The year of the observation.

- `month`:

  The month of the observation.

- `quarter`:

  The quarter of the observation.

- `source`:

  The DMDC report source of the observation.

- `Location`:

  The geographic location listed in the DMDC reports.

- `Total`:

  "Total number of US military personnel deployed to the host country.

- `Total Ashore`:

  "Total number of US military personnel deployed to the host country,
  excluding those at sea.

- `Total Afloat`:

  "Total number of US military personnel deployed to the host country,
  at sea.

- `Army Total`:

  Total number of Army personnel deployed to the host country.

- `Navy Ashore`:

  Total number of Navy personnel deployed to the host country, excluding
  those at sea.

- `Navy Temporary Ashore`:

  Total number of Navy personnel deployed to the host country,
  temporarily.

- `Navy Other`:

  Total number of Navy personnel deployed to the host country, in other
  capacities.

- `Marine Corps Ashore`:

  Total number of Marine Corps personnel deployed to the host country,
  excluding those at sea.

- `Marine Corps Afloat`:

  Total number of Marine Corps personnel deployed to the host country,
  at sea.

- `Air Force Total`:

  Total number of Air Force personnel deployed to the host country.

- `Navy Afloat`:

  Total number of Navy personnel deployed to the host country, at sea.

- `Navy Total`:

  Total number of Navy personnel deployed to the host country.

- `Marine Corps Total`:

  Total number of Marine Corps personnel deployed to the host country.

- `troops_ad`:

  The total number of active duty US military personnel deployed to the
  host country.

- `army_ad`:

  Total number of active duty Army personnel deployed to the host
  country.

- `navy_ad`:

  Total number of active duty Navy personnel deployed to the host
  country.

- `marine_corps_ad`:

  Total number of active duty Marine Corps personnel deployed to the
  host country.

- `space_force_ad`:

  Total number of active duty Space Force personnel deployed to the host
  country.

- `air_force_ad`:

  Total number of active duty Air Force personnel deployed to the host
  country.

- `coast_guard_ad`:

  Total number of Coast Guard personnel deployed to the host country.

- `troops_afloat`:

  Navy and Marine Corps personnel afloat that a report attributes to the
  location, 1950 through 2007. Not included in `troops_ad`. See Details.

- `navy_afloat`:

  Navy personnel afloat that a report attributes to the location. Not
  included in `navy_ad`.

- `marine_corps_afloat`:

  Marine Corps personnel afloat that a report attributes to the
  location. Not included in `marine_corps_ad`.

- `Macro Location`:

  The geographic location listed in the DMDC reports.

- `Army Active Duty`:

  Total number of active duty Army personnel deployed to the host
  country.

- `Navy Active Duty`:

  Total number of active duty Navy personnel deployed to the host
  country.

- `Marine Corps Active Duty`:

  Total number of active duty Marine Corps personnel deployed to the
  host country.

- `Air Force Active Duty`:

  Total number of active duty Air Force personnel deployed to the host
  country.

- `Coast Guard Active Duty`:

  Total number of active duty Coast Guard personnel deployed to the host
  country.

- `Space Force Active Duty`:

  Total number of active duty Space Force personnel deployed to the host
  country.

- `Total Active Duty`:

  Total number of active duty US military personnel deployed to the host
  country.

- `Army National Guard`:

  Total number of Army National Guard personnel deployed to the host
  country.

- `Army Reserve`:

  Total number of reserve Army personnel deployed to the host country.

- `Navy Reserve`:

  Total number of reserve Navy personnel deployed to the host country.

- `Marine Corps Reserve`:

  Total number of reserve Marine Corps personnel deployed to the host
  country.

- `Air National Guard`:

  Total number of Air National Guard personnel deployed to the host
  country.

- `Air Force Reserve`:

  Total number of reserve Air Force personnel deployed to the host
  country.

- `Coast Guard Reserve`:

  Total number of reserve Coast Guard personnel deployed to the host
  country.

- `Total Selected Reserve`:

  Total number of reserve US military personnel deployed to the host
  country.

- `Army Civilian`:

  Total number of Army civilian personnel deployed to the host country.

- `Navy Civilian`:

  Total number of Navy civilian personnel deployed to the host country.

- `Marine Corps Civilian`:

  Total number of Marine Corps civilian personnel deployed to the host
  country.

- `Air Force Civilian`:

  Total number of Air Force civilian personnel deployed to the host
  country.

- `DOD Civilian`:

  Total number of Department of Defense civilian personnel deployed to
  the host country.

- `Total Civilian`:

  Total number of civilian personnel deployed to the host country.

- `Grand Total`:

  Total number of US military and civilian personnel deployed to the
  host country.

## Source

<https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005>

[doi:10.1177/07388942211030885](https://doi.org/10.1177/07388942211030885)

## Value

Returns a data frame containing DMDC reports of US military deployments
by location from 1950 through the latest report in this version of the
package, March 2026.

## Details

Before 2008 `troops_ad`, `navy_ad` and `marine_corps_ad` hold personnel
ashore for every location, the United States included. The reports for
1950 through 2007 count Navy and Marine Corps personnel afloat
separately, and attribute some of them to a location: to the country of
the nearest port or the country whose line they are printed on
(1953-1976), and, for the fleet in home waters, to the United States
(1950, 1953-2007; from 1968 the reports give that figure for the United
States and its territories together). Those are in `troops_afloat`,
`navy_afloat` and `marine_corps_afloat`, beside the ashore figures and
not inside them. A zero there means a report that lists personnel afloat
by location has none for that one (1953-1976); a missing value means the
report gives no figure for the location (everywhere but the United
States in 1950 and 1977-2007, apart from 171 Marines afloat at Cuba in
1950; the years 1951 and 1952; and everything from 2008). For 1954-1956
the figure also holds mobile units temporarily based ashore, which those
three reports do not separate.

Everyone afloat is also carried once, worldwide, in a location named
`"Afloat"` (`ccode` 10200, no ISO code, region `"Afloat"`), with values
for 1950 and 1953 through 2007. It is not a country, and it includes the
personnel the three afloat columns attribute to locations: `troops_ad`
added up over every row, that one included, counts everyone the data
place somewhere once, and adding the afloat columns to it as well would
count those personnel twice. (It is still below the worldwide total a
report prints, which also includes the personnel it lists under no
location.)
[`get_troopdata`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
handles this through its `afloat` argument, which leaves the attributed
personnel out of the locations, adds them in, or returns them
separately, and adjusts the `"Afloat"` location to match. From September
2008 the DMDC reports count a ship's crew at its home port, inside the
state or country figure, and there is no afloat figure, so the ashore
Navy figures for countries and states that are home ports step up
between 2007 and 2008.

The reports did not keep to that from December 2015 to December 2017.
They list 77,120 personnel under "Unknown" in the United States block in
December 2015, and between 88,500 and 104,703 in each report from March
2016 to December 2017 under "Armed Forces Europe", "Armed Forces
Pacific" and "Armed Forces the Americas", nearly all of them Navy. Those
personnel cannot be traced to a state or a country and are in none of
the rows here, so the United States figures are lower in those quarters
and return in March 2018.

The derived columns, whose names are in lower case, follow that rule.
The columns that carry a report's own figures, such as `Total`,
`Total Afloat`, `Navy Afloat` and `Navy Other`, are left as the report
prints them; `navy_afloat` is built from `Navy Afloat` or `Navy Other`,
whichever the report of that year uses (the United States row, which is
assembled from several lines, aside). For December 2022, March 2023 and
June 2023 the Army reported nothing: the Army columns and `troops_ad`
are missing on those rows and the other services are as reported. The
United States row is the exception. It is not a line of a report (from
2008 it is the sum of the state lines), and for those three quarters it
carries a fixed Army figure of 404,114, a total built on it, and zeros
rather than missing values in the Army guard and reserve columns and the
totals that include them.
[`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md)
fills the Army figures for those quarters in equal steps between
September 2022 and September 2023 instead, so the two differ for the
United States there.

In 46 rows of December 2021, March 2022 and June 2022 the total a report
prints, which is what `troops_ad` holds here, is lower than the sum of
that row's service columns.
[`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md)
uses the sum.

The June 2023 report prints part of its overseas list one row low: the
six civilian columns from Montenegro to the end of the list, and the
Navy Reserve, Marine Corps Reserve, Air National Guard, Air Force
Reserve and Coast Guard Reserve columns from Morocco to Wake Island.
Each of those lines holds the figures of the location above it, so Qatar
shows Puerto Rico's 2,201 civilians and Puerto Rico shows 7. The rows
here are as published.
[`troopdata_rebuild_long`](https://meflynn.github.io/troopdata/reference/troopdata_rebuild_long.md)
reads those figures from the right line.
