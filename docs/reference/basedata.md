# Vine's U.S. basing data

`basedata` returns a data frame containing David Vine's US basing data.

## Usage

``` r
basedata
```

## Format

A data frame with country-base observations including the following
variables:

- `countryname`:

  A character vector of country names.

- `ccode`:

  A numeric vector of Correlates of War country codes.

- `iso3c`:

  A character vector of ISO three character country codes.

- `basename`:

  Name of the facility.

- `lat`:

  The facility's latitude.

- `lon`:

  The facility's longitude.

- `base`:

  Binary indicator identifying the facility as a major base or not.

- `lilypad`:

  A binary indicator identifying the facility as a lilypad or not. Vine
  codes lilypads as less than 200 personnel or "other site" designation
  in Pentagon reports.

- `fundedsite`:

  A binary variable indicating whether or not the facility is a
  host-state base funded by the US.

## Source

<https://aura.american.edu/articles/online_resource/Lists_of_U_S_Military_Bases_Abroad_1776-2020/23856486>

## Value

Returns the full data frame containing country observations of US
military bases from the Cold War period through 2018.
