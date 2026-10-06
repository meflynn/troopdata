# U.S. domestic troop deployment data, by state

`troopdata_rebuild_us_states` returns a data frame containing
information on U.S. military personnel stationed in each of the 50 U.S.
states and the District of Columbia. Territories such as Puerto Rico and
Guam are overseas locations and are in the country data, not here.
Returned by
[`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
when the `state_data` argument is set to `TRUE`.

## Usage

``` r
troopdata_rebuild_us_states
```

## Format

A data frame with one row per state and report period (one report a year
through 2012, two in 2013 and four a year from 2014), including the
following variables:

- `fipscode`:

  A numeric vector of U.S. Federal Information Processing Standards
  (FIPS) state codes. Used as the numeric identifier when subsetting via
  `get_troopdata(host = <numeric>, state_data = TRUE)`.

- `state`:

  A character vector of U.S. state names. Matched without regard to case
  when subsetting via
  `get_troopdata(host = <character>, state_data = TRUE)`: a full name
  returns that state alone (`"kansas"` is Kansas, `"Virginia"` is not
  also West Virginia), and part of a name returns every state whose name
  contains it (`"Carolina"`).

- `year`:

  The year of the observation.

- `month`:

  The month of the observation.

- `quarter`:

  The quarter of the observation.

- `troops_ad`:

  The total number of active duty US military personnel stationed in the
  state, as the report prints it. For 95 state-quarters in June 2021,
  December 2021 and March 2022 the printed total is lower than the sum
  of the branch columns. The country data use the sum for the United
  States in those quarters, so the states add up to 23, 4,330 and 6,046
  fewer personnel than the United States figure there. Missing in
  December 2022, March 2023 and June 2023, when the Army did not report.

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

- `troops_all`:

  The total number of US military personnel stationed in the state
  including guard and reserve: `troops_ad` plus the seven guard and
  reserve components, the same definition as in the country data.
  Missing in December 2022, March 2023 and June 2023, when the Army did
  not report and `troops_ad` is missing here.

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

Returns the full data frame containing state-year-quarter observations
of U.S. military personnel stationed domestically from September 2008,
the first report that lists the states, through the most recent
reporting period.

## Details

From December 2015 to December 2017 the DMDC reports list a large number
of personnel, nearly all Navy, inside the United States block but in no
state: 77,120 under "Unknown" in December 2015, and between 88,500 and
104,703 in each report from March 2016 to December 2017 under "Armed
Forces Europe", "Armed Forces Pacific" and "Armed Forces the Americas".
They cannot be traced to a state and are not in these figures, so the
Navy and total figures of the home-port states are lower in those
quarters and return in March 2018.

The Army reported nothing for December 2022, March 2023 and June 2023.
In those three quarters `army_ad`, `army_national_guard`, `army_reserve`
and the totals that include them (`troops_ad`, `total_selected_reserve`
and `troops_all`) are missing here, and the other columns are as
reported. Unlike the country data, nothing is filled in. The annual
figures that
[`get_troopdata`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
returns for a state are the largest value of each column over the
quarters of the year that have one, so for 2022 and 2023 the totals and
the Army figures come from the quarters the Army reported.
