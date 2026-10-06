# U.S. Military overseas construction spending data (superseded)

`builddata` is the original geocoded construction spending data,
compiled from operations and maintenance records rather than the
Comptroller Annual Report C-1 exhibits. It is retained for
reproducibility of earlier analyses.
[`get_builddata()`](https://meflynn.github.io/troopdata/reference/get_builddata.md)
reads `build_data_20260918` instead.

## Usage

``` r
builddata
```

## Format

A data frame with location-year observations including the following
variables:

- `countryname`:

  A character vector of country names.

- `ccode`:

  A numeric vector of Correlates of War country codes.

- `year`:

  Year of observed country-year spending.

- `iso3c`:

  A character vector of ISO three character country codes.

- `location`:

  Name of the facility where spending occurred, or host country where
  detailed facility information is unavailable.

- `spend_construction`:

  Total obligational authority associated with the observed
  location-year in thousands of current US dollars.

- `lat`:

  The facility's latitude.

- `lon`:

  The facility's longitude.

## Value

Returns a data frame containing location-year observations of U.S.
military construction spending data from 2008-2019.
