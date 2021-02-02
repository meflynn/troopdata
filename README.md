Michael Flynn

-   [`troopdata`: A package for analyzing cross-national military
    deployment and basing
    data](#troopdata-a-package-for-analyzing-cross-national-military-deployment-and-basing-data)
    -   [Installation](#installation)
    -   [Useage](#useage)
    -   [Example](#example)
        -   [`get_troopdata`](#get_troopdata)
        -   [`get_basedata`](#get_basedata)
    -   [Applications](#applications)
    -   [How to cite this package and
        data?](#how-to-cite-this-package-and-data)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# `troopdata`: A package for analyzing cross-national military deployment and basing data

<!-- badges: start -->
<!-- badges: end -->

<img src="man/figures/logo.png" alt="troopdata hex logo" align="right" width="200" style="padding: 0 15px; float: right;"/>

The goal of troopdata is to facilitate the distribution of military
deployment and basing data for use in social science research and
journalism. The troop deployment data were initially compiled by Tim
Kane using data from the U.S. Department of Defense’s Defense Manpower
Data Center. The original data ended in 2005 and we have updated it to
run through 2020. Similarly, the basing data were initially compiled by
David Vine, and we have updated the original data using open source
information from the U.S. military and press reports through 2018. We
have also assembled this R package to allow users to more easily access
the data and use it in their own research.

The package will be updated with additional features in the future, but
for now please let me know if you find any errors.

Please refer to the bottom of this page for citation information.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("meflynn/troopdata")
```

## Useage

This package currently has two functions:

`get_troopdata()`: Returns a data frame containing country-year U.S.
military deployment values. Depending on the arguments specified, either
total troop deployments, or total deployments plus service
branch-specific deployment values, are returned.

`get_basedata()`: Returns a data frame containing information on U.S.
military bases around the globe from the Cold War forward. Depending on
the arguments specified the function will return the entire data set or
data for a particular country. Observations can be site-specific or can
be aggregated to generate country counts.

## Example

### `get_troopdata`

The first function of this package is the `get_troopdata` function. At
its most basic this function returns a data frame of country-year troop
deployment values for the selected time period, using the `startdate`
and `enddate` parameters.

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

### `get_basedata`

The second function, `get_basedata` returns a data frame containing
information on the United States’ overseas military bases going back to
the beginning of the Cold War. At it’s most basic the function will
return a data frame containing country-base observations, along with the
facility’s longitude and latitude (if available), and a series of binary
variables indicating whether or not the facility is a full military
base, a smaller lilypad, and if it is a currently funded site.

``` r
baseexample <- get_basedata(host = NA, country_count = FALSE)

head(baseexample)
#> # A tibble: 6 x 8
#>   country     ccode basename            lat   lon  base lilypad fundedsite
#>   <chr>       <dbl> <chr>             <dbl> <dbl> <dbl>   <dbl>      <dbl>
#> 1 Afghanistan   700 Bagram AB          34.9  69.3     1       0          0
#> 2 Afghanistan   700 Kandahar Airfield  31.5  65.8     1       0          0
#> 3 Afghanistan   700 Mazar-e-Sharif     36.7  67.2     1       0          0
#> 4 Afghanistan   700 Gardez             33.6  69.2     1       0          0
#> 5 Afghanistan   700 Kabul              34.5  69.2     1       0          0
#> 6 Afghanistan   700 Herat              34.3  62.2     1       0          0
```

As with the `get_troopdata` function, users can specify particular
countries using the Correlates of War (COW) country code values. These
can be single numeric values of a vector of values.

``` r
hostvector <- c(20, 200, 255, 645)

baseexample <- get_basedata(host = hostvector, country_count = FALSE)
#> Warning in if (!is.numeric(host) & !is.na(host)) {: the condition has length > 1
#> and only the first element will be used
#> Warning in if (is.na(host)) {: the condition has length > 1 and only the first
#> element will be used

head(baseexample)
#> # A tibble: 6 x 8
#>   country            ccode basename          lat    lon  base lilypad fundedsite
#>   <chr>              <dbl> <chr>           <dbl>  <dbl> <dbl>   <dbl>      <dbl>
#> 1 Ascension Island     200 Ascension Isla~ -7.95  -14.4     1       0          0
#> 2 BR Indian Ocean T~   200 Diego Garcia    -7.32   72.4     1       0          0
#> 3 Canada                20 <NA>            56.1  -106.      0       1          0
#> 4 Canada                20 Argentia, Newf~ 47.3   -54.0     1       0          0
#> 5 Germany              255 Amberg          49.4    11.9     1       0          0
#> 6 Germany              255 USAG Ansbach    49.3    10.6     1       0          0
```

Finally, users can also generate country-level counts of the number of
U.S. military bases by changing the `country_count` argument to `TRUE`.

``` r
baseexample <- get_basedata(host = hostvector, country_count = TRUE)
#> Warning in if (!is.numeric(host) & !is.na(host)) {: the condition has length > 1
#> and only the first element will be used
#> Warning in if (is.na(host)) {: the condition has length > 1 and only the first
#> element will be used
```

## Applications

So what can you do with these super useful and cool data? Lots of
things! The study of basing and military deployments has been picking up
over the last few years and there are lots of cool studies you should
check out. With these data you can do cool things like this!

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

## How to cite this package and data?

When using the updated troop deployment data and/or the `troopdata`
package please cite the following:

-   Allen, Michael A., Michael E. Flynn, Carla Martinez Machain, and
    Andrew Stravers. 2021. “Global U.S. military deployment data:
    1950-2020.” *Working Paper*

Kane’s original troop deployment data collected from 1950-2005:

-   Kane, Tim. 2005. “Global U.S. troop deployment, 1950-2003.”
    Technical Report. Heritage Foundation, Washington, D.C.

Vine’s original basing data:

-   Vine, David. 2015. “Base nation: How U.S. military bases abroad harm
    America and the World.” Metropolitan Books, Washington, D.C.
