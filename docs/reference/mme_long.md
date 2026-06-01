# Multilateral Military Exercises (MME) data, long format

`mme_long` returns a data frame containing exercise-country-year
observations of multilateral military exercises. Built from the MME
version 7 data (<https://doi.org/10.7910/DVN/KHFODX>) and reshaped so
each row represents a single participating country in a single year of a
single exercise. This is the data object underlying
[`get_exercises()`](https://meflynn.github.io/troopdata/reference/get_exercises.md).

## Usage

``` r
mme_long
```

## Format

A data frame with exercise-country-year observations including the
following variables:

- `MMEID`:

  Unique exercise identifier from the MME source data.

- `Ex_Name`:

  The name of the individual exercise (e.g., "Cobra Gold 23").

- `Series_Name`:

  The name of the broader exercise series the exercise belongs to (e.g.,
  "Cobra Gold").

- `gwcode`:

  Numeric Gleditsch and Ward country code for the participating country.
  Looked up from `country` via the `countrycode` package; `NA` for
  non-country participants such as "NATO" or regional groupings.

- `country`:

  Character vector of participating country names as recorded in the MME
  source data.

- `year`:

  The year of the observation. Exercises spanning multiple years are
  expanded so that each year between `s.year` and `e.year` produces its
  own row.

- `Location`:

  The geographic location where the exercise was held (free-text from
  the source data).

- `lat`:

  Latitude of the exercise location.

- `lon`:

  Longitude of the exercise location.

- `StartDate`:

  Original start-date string from the source data.

- `s.year`:

  Numeric year the exercise began.

- `s.month`:

  Numeric month the exercise began.

- `s.day`:

  Numeric day the exercise began (may be `"xx"` when unknown).

- `EndDate`:

  Original end-date string from the source data.

- `e.year`:

  Numeric year the exercise ended.

- `e.month`:

  Numeric month the exercise ended.

- `e.day`:

  Numeric day the exercise ended (may be `"xx"` when unknown).

- `CPX`:

  Binary indicator: command post exercise.

- `Air`:

  Binary indicator: air domain.

- `Land`:

  Binary indicator: land domain.

- `Sea`:

  Binary indicator: sea domain.

- `Amphibious`:

  Binary indicator: amphibious domain.

- `Cyber`:

  Binary indicator: cyber domain.

- `Warfighting`:

  Binary indicator: warfighting focus.

- `Peacekeeping`:

  Binary indicator: peacekeeping focus.

- `Humanitarian`:

  Binary indicator: humanitarian focus.

- `FocusDescription`:

  Free-text description of the exercise's focus from the source data.

- `AdditionalParticipantInfo`:

  Free-text notes about participants from the source data.

- `participant_count`:

  Total number of participating countries in the exercise. The same
  value is repeated across all rows that share an MMEID. Used by the
  `min_participants` and `max_participants` arguments of
  [`get_exercises()`](https://meflynn.github.io/troopdata/reference/get_exercises.md).

## Source

D'Orazio, Vito; Galambos, Kevin, 2021, "Multinational Military
Exercises, 1980-2010",
[doi:10.7910/DVN/KHFODX](https://doi.org/10.7910/DVN/KHFODX) , Harvard
Dataverse, V1.

## Value

Returns the full data frame of exercise-country-year observations of
multilateral military exercises from 1980 forward.
