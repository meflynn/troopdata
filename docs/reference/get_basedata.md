# Function to retrieve customized U.S. basing data

`get_basedata()` generates a customized data frame containing data
obtained from David Vine's U.S. basing data.

## Usage

``` r
get_basedata(host = NA, country_count = FALSE, groupvar = NULL)
```

## Arguments

- host:

  The Correlates of War (COW) numeric country code or ISO3C code for the
  host country or countries in the series

- country_count:

  Logical. Should the function return a country-level count of the total
  number of bases or the country-site data

- groupvar:

  A character string indicating how country count totals should be
  generated. Accepted values are 'countryname', 'ccode', or 'iso3c'. Can
  take on Required when using country_count argument.

## Value

`get_basedata()` returns a data frame containing information on U.S.
military bases present within selected host countries. This can be
customized to include country-base observations or country-count
observations.

## Details

Our research team updated these data through 2018.

## References

David Vine. 2015. Base Nation. Metropolitan Books. New York, NY.

## Author

Michael E. Flynn

## Examples

``` r
if (FALSE) { # \dontrun{
library(tidyverse)
library(troopdata)

example <- get_basedata(host = NA)

head(example)

} # }
```
