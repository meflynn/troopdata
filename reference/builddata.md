# U.S. Military overseas construction spending data

`builddata` returns a data frame containing geocoded
location-project-year overseas military construction spending data.

## Usage

``` r
builddata
```

## Format

A data frame with country-base observations including the following
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

Returns the full data frame containing location-project-year
observations of U.S. military construction spending data from 2008-2019.
