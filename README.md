
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `troopdata`: A package for analyzing cross-national military deployment data

<!-- badges: start -->
<!-- badges: end -->

<img src="man/figures/logo.png" alt="troopdata hex logo" align="right" width="200" style="padding: 0 15px; float: right;"/>

The goal of troopdata is to facilitate the distribution of military
deployment data for use in social science research and journalism. These
data were initially compiled by Tim Kane using data from the U.S.
Department of Defense’s Defense Manpower Data Center. The original data
ended in 2005 and we have updated it to run through 2020. We have also
assembled this R package to allow users to more easily access the data
and use it in their own research.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("meflynn/troopdata")
```

## Useage

This package currently only has a single function:

`get_troopdata()`: returns a data frame containing country-year U.S.
military deployment values. Depending on the arguments specified, either
total troop deployments, or total deployments plus service
branch-specific deployment values, are returned.

## Example

The core function of this package is the `get_troopdata` function. At
its most basic this function returns a data frame of country-year troop
deployment values for the selected time period, using the `startdate`
and `enddate` parameters.

    #> Loading required package: magrittr
    #> Loading required package: dplyr
    #> 
    #> Attaching package: 'dplyr'
    #> The following objects are masked from 'package:stats':
    #> 
    #>     filter, lag
    #> The following objects are masked from 'package:base':
    #> 
    #>     intersect, setdiff, setequal, union
    #> Loading required package: tibble
    #> Loading required package: countrycode
    #> Loading required package: tidyr
    #> 
    #> Attaching package: 'tidyr'
    #> The following object is masked from 'package:magrittr':
    #> 
    #>     extract
    #> Loading required package: stringr
    #> Loading required package: readstata13
    #> Loading required package: rlang
    #> 
    #> Attaching package: 'rlang'
    #> The following object is masked from 'package:magrittr':
    #> 
    #>     set_names

For users who want more refined data, the `host` argument and the
`branch` arguments allow users to specify the set of host countries for
which they would like data returned. This must be a single numerical
value equal to a Correlates of War (COW) Project country code, or a
vector of numerical COW country code values.

``` r
hostlist <- c(200, 220)

example <- get_troopdata(host = hostlist, startyear = 1990, endyear = 2020)
#> Warning in if (is.na(host)) {: the condition has length > 1 and only the first
#> element will be used

head(example)
#>   ccode year troops
#> 1   200 1990  25111
#> 2   200 1991  23442
#> 3   200 1992  20048
#> 4   200 1993  16100
#> 5   200 1994  13781
#> 6   200 1995  12131
```

Last, the `branch` argument mentioned above is a loglcal argument
(i.e. `TRUE` or `FALSE`) that allows users to view data disaggregated by
individual service branches. Note that these values are only available
for the 2006 and later time period. The default value is FALSE and the
function will automatically return the sum total of troop deployments to
a country.

``` r
example <- get_troopdata(host = hostlist, branch = TRUE, startyear = 2006, endyear = 2020)
#> Warning: Branch data only available for 2006 forward.
#> Warning in if (is.na(host)) {: the condition has length > 1 and only the first
#> element will be used

head(example)
#>   ccode year troops army navy air_force marine_corps
#> 1   200 2006  11331  397  584     10280           70
#> 2   200 2007  10425  355  443      9552           75
#> 3   200 2008   9042  315  489      8169           69
#> 4   200 2009   8933  324  396      8143           70
#> 5   200 2010   8764  333  364      8004           63
#> 6   200 2011   8673  328  316      7977           52
```

## Citations and Reference

When using the updated troop deployment data and/or the `troopdata`
package please cite the following:

Allen, Michael A., Michael E. Flynn, Carla Martinez Machain, and Andrew
Stravers. 2021. “Global U.S. Military Deployment Data: 1950-2020.”
*Working Paper*
