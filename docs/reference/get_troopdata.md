# Function to retrieve customized U.S. troop deployment data

`get_troopdata()` generates a customized data frame containing
country-year observations of U.S. military deployments overseas.

## Usage

``` r
get_troopdata(
  host = NULL,
  branch = FALSE,
  startyear = 1950,
  endyear = 2025,
  quarters = FALSE,
  guard_reserve = FALSE,
  civilians = FALSE,
  state_data = FALSE,
  reports = FALSE
)
```

## Arguments

- host:

  The Correlates of War (COW) numeric country code, ISO3C code, or
  country name, for the host country or countries in the series. If
  region == TRUE the user can specify a COW region name and the function
  will try to match it to the region column in the data. The default is
  NA.

- branch:

  Logical. Should the function return a single vector containing total
  troop values or multiple vectors containing total values and values
  for individual branches? Default is FALSE.

- startyear:

  The first year for the series. The default is set to 1950.

- endyear:

  The last year for the series. The default is the maximum year in the
  currently published data.

- quarters:

  Logical. Should the function return quarterly data? Default is FALSE.

- guard_reserve:

  Logical. Should the function return values for the National Guard and
  Reserve? Default is FALSE.

- civilians:

  Logical. Should the function return values for civilian DoD personnel?
  Default is FALSE.

- state_data:

  Logical. Should the function return disaggregated data on US States?
  Default is FALSE.

- reports:

  Logical. Should the function return reports for the specified
  countries and years? Default is FALSE.

## Value

`get_troopdata()` returns a data frame containing country-year
observations for U.S. troop deployments.

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
