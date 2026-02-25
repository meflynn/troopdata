# Function to retrieve customized U.S. construction spending data.

`get_builddata()` generates a customized data frame containing
location-project-year observations of U.S. military construction and
housing spending in thousands of current dollars.

## Usage

``` r
get_builddata(host = NA, startyear, endyear)
```

## Arguments

- host:

  The Correlates of War (COW) numeric country code or ISO3C code for the
  host country or countries in the series

- startyear:

  The first year for the series

- endyear:

  The last year for the series

## Value

`get_builddata()` returns a data frame containing location-project-year
observations of U.S. military construction and housing spending in
thousands of current dollars.

## References

Michael A. Allen, Michael E. Flynn, and Carla Martinez Machain. 2020.
"Outside the wire: US military deployments and public opinion in host
states." American Political Science Review. 114(2): 326-341.

## Author

Michael E. Flynn

## Examples

``` r
if (FALSE) { # \dontrun{
library(tidyverse)
library(troopdata)

example <- get_builddata(host = NA, startyear = 2008, endyear = 2019)

head(example)

} # }


```
