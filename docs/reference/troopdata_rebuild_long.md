# U.S. overseas troop deployment data

`troopdata` returns a data frame containing information on US military
deployments.

## Usage

``` r
troopdata_rebuild_long
```

## Format

A data frame with country year observations including the following
variables:

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

- `year_quarter`:

  The year and quarter of the observation.

- `source`:

  The DMDC report source of the observation.

- `troops_ad`:

  The total number of active duty US military personnel deployed to the
  host country.

- `troops_all`:

  The total number of US military personnel deployed to the host country
  including guard and reserve.

- `army_ad`:

  Total number of active duty Army personnel deployed to the host
  country.

- `navy_ad`:

  Total number of active duty Navy personnel deployed to the host
  country.

- `air_force_ad`:

  Total number of active duty Air Force personnel deployed to the host
  country.

- `space_force_ad`:

  Total number of active duty Space Force personnel deployed to the host
  country.

- `marine_corps_ad`:

  Total number of Marine Corps personnel deployed to the host country.

- `coast_guard_ad`:

  Total number of Coast Guard personnel deployed to the host country.

- `total_selected_reserve`:

  Total number of reserve US military personnel deployed to the host
  country.

- `army_reserve`:

  Total number of reserve Army personnel deployed to the host country.

- `navy_reserve`:

  Total number of reserve Navy personnel deployed to the host country.

- `air_force_reserve`:

  Total number of reserve Air Force personnel deployed to the host
  country.

- `marine_corps_reserve`:

  Total number of reserve Marine Corps personnel deployed to the host
  country.

- `coast_guard_reserve`:

  Total number of reserve Coast Guard personnel deployed to the host
  country.

- `army_national_guard`:

  Total number of Army National Guard personnel deployed to the host
  country.

- `air_national_guard`:

  Total number of Air National Guard personnel deployed to the host
  country.

- `army_civilian`:

  Total number of Army civilian personnel deployed to the host country.

- `navy_civilian`:

  Total number of Navy civilian personnel deployed to the host country.

- `air_force_civilian`:

  Total number of Air Force civilian personnel deployed to the host
  country.

- `marine_corps_civilian`:

  Total number of Marine Corps civilian personnel deployed to the host
  country.

- `dod_civilian`:

  Total number of Department of Defense civilian personnel deployed to
  the host country.

- `total_civilian`:

  Total number of civilian personnel deployed to the host country.

## Source

<https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005>

[doi:10.1177/07388942211030885](https://doi.org/10.1177/07388942211030885)

## Value

Returns the full data frame containing observations of US military
deployments to overseas locations (countries and territories) from 1950
through 2024.
