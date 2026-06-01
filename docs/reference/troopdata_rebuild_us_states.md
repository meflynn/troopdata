# U.S. domestic troop deployment data, by state

`troopdata_rebuild_us_states` returns a data frame containing
information on U.S. military personnel stationed in each of the 50 U.S.
states (and U.S. territories where reported). Returned by
[`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
when the `state_data` argument is set to `TRUE`.

## Usage

``` r
troopdata_rebuild_us_states
```

## Format

A data frame with state-year (and state-year-quarter) observations
including the following variables:

- `fipscode`:

  A numeric vector of U.S. Federal Information Processing Standards
  (FIPS) state codes. Used as the numeric identifier when subsetting via
  `get_troopdata(host = <numeric>, state_data = TRUE)`.

- `state`:

  A character vector of U.S. state names. Matched with a
  case-insensitive `grepl` fuzzy match when subsetting via
  `get_troopdata(host = <character>, state_data = TRUE)`.

- `year`:

  The year of the observation.

- `month`:

  The month of the observation.

- `quarter`:

  The quarter of the observation.

- `troops_ad`:

  The total number of active duty US military personnel stationed in the
  state.

- `army_ad`:

  Total number of active duty Army personnel stationed in the state.

- `navy_ad`:

  Total number of active duty Navy personnel stationed in the state.

- `air_force_ad`:

  Total number of active duty Air Force personnel stationed in the
  state.

- `marine_corps_ad`:

  Total number of active duty Marine Corps personnel stationed in the
  state.

- `coast_guard_ad`:

  Total number of active duty Coast Guard personnel stationed in the
  state.

- `space_force_ad`:

  Total number of active duty Space Force personnel stationed in the
  state.

- `army_national_guard`:

  Total number of Army National Guard personnel stationed in the state.

- `air_national_guard`:

  Total number of Air National Guard personnel stationed in the state.

- `army_reserve`:

  Total number of Army Reserve personnel stationed in the state.

- `navy_reserve`:

  Total number of Navy Reserve personnel stationed in the state.

- `marine_corps_reserve`:

  Total number of Marine Corps Reserve personnel stationed in the state.

- `air_force_reserve`:

  Total number of Air Force Reserve personnel stationed in the state.

- `coast_guard_reserve`:

  Total number of Coast Guard Reserve personnel stationed in the state.

- `total_selected_reserve`:

  Total number of reserve US military personnel stationed in the state.

- `army_civilian`:

  Total number of Army civilian personnel stationed in the state.

- `navy_civilian`:

  Total number of Navy civilian personnel stationed in the state.

- `air_force_civilian`:

  Total number of Air Force civilian personnel stationed in the state.

- `marine_corps_civilian`:

  Total number of Marine Corps civilian personnel stationed in the
  state.

- `dod_civilian`:

  Total number of Department of Defense civilian personnel stationed in
  the state.

- `total_civilian`:

  Total number of civilian personnel stationed in the state.

## Source

<https://www.heritage.org/defense/report/global-us-troop-deployment-1950-2005>

[doi:10.1177/07388942211030885](https://doi.org/10.1177/07388942211030885)

## Value

Returns the full data frame containing state-year (and
state-year-quarter) observations of U.S. military personnel stationed
domestically from 1950 through the most recent reporting period.
