# Function to retrieve customized multilateral military exercise data

`get_exercises()` generates a customized data frame containing
exercise-country-year observations of multilateral military exercises.
Users can subset the data by participating country, year, exercise
duration, geographic location, exercise name, the domain(s) of the
exercise (e.g., air, land, sea), the mission focus (warfighting,
humanitarian, peacekeeping), and the number of participating countries.

## Usage

``` r
get_exercises(
  country = NULL,
  startyear = NULL,
  endyear = NULL,
  min_duration = NULL,
  max_duration = NULL,
  location = NULL,
  exercise_name = NULL,
  domain = NULL,
  focus = NULL,
  min_participants = NULL,
  max_participants = NULL
)
```

## Arguments

- country:

  The Gleditsch and Ward (G&W) numeric country code or country name for
  the participating country or countries to include. Numeric input is
  matched exactly against the `gwcode` column. Character input is
  matched against the `country` column using a case-insensitive `grepl`
  fuzzy match, so partial names are accepted (e.g., "korea" returns both
  Koreas). Multiple values can be supplied as a vector. The default is
  NULL, which returns all participating countries.

- startyear:

  The first year for the series. The default is set to the minimum year
  in the currently published data.

- endyear:

  The last year for the series. The default is the maximum year in the
  currently published data.

- min_duration:

  Numeric. Minimum exercise duration in days (inclusive). Default is
  NULL (no minimum filter).

- max_duration:

  Numeric. Maximum exercise duration in days (inclusive). Default is
  NULL (no maximum filter).

- location:

  Character. A string or vector of strings used to subset exercises by
  geographic location. Matched against the `Location` column with a
  case-insensitive `grepl` fuzzy match. Default is NULL.

- exercise_name:

  Character. A string or vector of strings used to subset exercises by
  name. Matched against both the `Ex_Name` and `Series_Name` columns
  with a case-insensitive `grepl` fuzzy match (e.g., "cobra" matches
  "Cobra Gold"). Default is NULL.

- domain:

  Character. A string or vector of strings indicating one or more
  exercise domains (warfighting environments) to include. Accepted
  values are `"air"`, `"land"`, `"sea"`, `"amphibious"`, and `"cyber"`.
  Matching is case-insensitive. An exercise is returned if it is flagged
  for any of the supplied domains (logical OR). Default is NULL, which
  returns all domains.

- focus:

  Character. A string or vector of strings indicating one or more
  mission focuses to include. Accepted values are `"warfighting"`,
  `"humanitarian"`, and `"peacekeeping"`. Matching is case-insensitive.
  An exercise is returned if it is flagged for any of the supplied
  focuses (logical OR). Default is NULL, which returns all mission
  focuses.

- min_participants:

  Numeric. Minimum number of participating countries in the exercise
  (inclusive). Default is NULL (no minimum filter).

- max_participants:

  Numeric. Maximum number of participating countries in the exercise
  (inclusive). Default is NULL (no maximum filter).

## Value

`get_exercises()` returns a data frame containing exercise-country-year
observations of multilateral military exercises that match the specified
filter criteria.

## References

D'Orazio, Vito; Galambos, Kevin, 2021, "Multinational Military
Exercises, 1980-2010", https://doi.org/10.7910/DVN/KHFODX, Harvard
Dataverse, V1.

Gleditsch, Kristian S., and Michael D. Ward. 1999. "Interstate System
Membership: A Revised List of the Independent States since 1816."
*International Interactions* 25(4): 393-413.

## Author

Michael E. Flynn

## Examples

``` r
if (FALSE) { # \dontrun{
library(tidyverse)
library(troopdata)

# Pull all exercises that include South Korea between 2000 and 2015.
korea_exercises <- get_exercises(country = "korea",
                                 startyear = 2000,
                                 endyear = 2015)

# Pull all naval and amphibious exercises lasting at least 5 days.
sea_exercises <- get_exercises(domain = c("sea", "amphibious"),
                               min_duration = 5)

# Pull all "Cobra Gold" exercises in Thailand.
cobra_gold <- get_exercises(exercise_name = "cobra gold",
                            location = "thailand")

# Pull large-scale humanitarian exercises (10 or more participants).
large_hadr <- get_exercises(focus = "humanitarian",
                            min_participants = 10)
} # }
```
