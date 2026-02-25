# DMDC Deployment Reports

`troopdata_rebuild_reports` returns a data frame containing DMDC reports
on US military deployments.

## Usage

``` r
troopdata_rebuild_reports
```

## Format

A data frame with country year quarter observations including the
following variables:

- `ccode`:

  A numeric vector of Correlates of War country codes.

- `iso3c`:

  A character vector of ISO three character country codes.

- `countryname`:

  A character vector of country names.

- `region`:

  Correlates of War geographic region name.

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
to overseas locations from 1950 through 2024.
