# Rebuild Notes

## A Note on version 1.0.0 and later

The bulk of the data included in `troopdata` versions under v1.0.0 were
drawn from the original Kane data, which was collected from 1950-2005.
The data were then updated through 2020 by Michael A. Allen, Michael E.
Flynn, and Carla Martinez Machain. The data were then further updated
through 2022 by Michael Flynn. Version 1.0.0 marked a total rebuild of
the `troopdata` package and so many values may not match up exactly with
the original Kane data. Here are a few key points to note regarding the
updates made since v1.0.0:

- The older DoD reports differentiate between forces ashore and forces
  afloat, but often have certain afloat forces assigned to a particular
  country. The data keep the two apart: the country figures
  (`troops_ad`, `navy_ad`, `marine_corps_ad`) are personnel ashore, and
  the afloat personnel a report assigns to a country are held beside
  them. The `afloat` argument of
  [`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
  decides what to do with them. `afloat = "exclude"`, the default,
  leaves them out of the country totals; `afloat = "include"` adds them
  in; and `afloat = "separate"` returns them in their own columns
  (`troops_afloat`, `navy_afloat` and `marine_corps_afloat`) next to the
  ashore figures. Omitting afloat forces attached to a particular
  country can severely underestimate the number of personnel present. In
  Greece in 1974, for example, we see 3,800 personnel ashore and a total
  of 5,437 reported by the DoD as assigned to Greece, including afloat:
  `"exclude"` returns the first figure and `"include"` the second. Note
  that for 1953 through 1967 the reports assign afloat personnel to the
  country of the nearest port, so `"include"` can place a fleet at sea
  in whichever country it was closest to on the day of the count (Greece
  reads 15,066 for 1960 with 1,976 ashore).

- The original reports also contain afloat personnel that are **not**
  assigned to particular countries, such as the “other afloat” category
  and, in more recent years, an afloat line for each region that is not
  disaggregated by country. These are not aggregated into any country
  totals. They are carried in a separate location named “Afloat”
  (country code 10200), which covers 1950 and 1953 through 2007. With
  `afloat = "exclude"` that location holds everyone afloat worldwide;
  with `"include"` or `"separate"` it holds only those not assigned to a
  country, so the worldwide total is the same either way. The one afloat
  line the reports give for the United States and its territories
  together is treated as the United States’ own. From September 2008 the
  DoD counts a ship’s crew at its home port, inside the country or state
  figure, and there is no separate afloat figure.

- For more recent years some discrepancies between versions might be the
  result of the fact that the DoD issued multiple reports with different
  figures, even for the same monthly release. For example, There are
  multiple reports issued for September 2008 with each reporting
  different country-specific values.

- From December 2015 through December 2017 the reports list a large
  number of personnel, nearly all of them Navy, inside the United States
  block but in no state: about 77,000 under “Unknown” in December 2015,
  and between 88,500 and 104,703 in each report from March 2016 to
  December 2017 under “Armed Forces Europe”, “Armed Forces Pacific” and
  “Armed Forces the Americas”. Because they cannot be traced to a state
  or a country they are not included in any of the figures, so the
  United States total and its Navy figure are lower in those quarters
  and return in March 2018. The data are left as the reports print them.

- There are also some smaller territorial units that appear in the DoD
  reports that did not appear in Kane’s original data or our package. We
  create ad hoc country codes to deal with them. Hong Kong, for example,
  is treated separately in rebuilt data. This can also factor into
  higher regional totals whre Kane’s data may have omitted some of these
  smaller territorial units.

- In general we try to assign country codes to deployments that
  correspond to their actual physical geographic location. For example,
  deployments to Greenland could be assigned to Denmark, but we assign
  them to Greenland with an ad hoc country code. Similarly, deployments
  to Puerto Rico are assigned to Puerto Rico rather than the United
  States. This is a change from the original Kane data, which assigned
  all deployments to the United States. These values may be aggregated
  by users for analysis if they wish to do so.

- In more recent years the DoD has issued multiple quarterly reports in
  a given year. When reporting annual values the
  [`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
  function will return the highest value from the quarterly reports for
  a given year where those are available. This should only affect more
  recent years, but it’s a different approach than Kane’s original
  method which involved just using the September reports. The next
  section goes through this rule and the others like it.

- In some cases the physical location of a deployment may remain
  constant but the polity associated with that deployment may change.
  For example, the force in Kosovo is counted under Yugoslavia from 1999
  through 2005, under Serbia in 2006 and 2007, and under Kosovo from
  2008.

- The DoD often lists China and Hong Kong as a single entity. Prior to
  1997 deployments to Hong Kong were usually listed separately, but
  following 1997 they are often grouped together. We adopt an ad hoc
  country code for Hong Kong and assign deployments to that code where
  they are listed as such in the DoD reports. After 1997 we treat any
  deployment references to Hong Kong as deployments to China.

## How values are handled

This section lays out the rules that turn the DoD reports into the
values that
[`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
returns. The help page for
[`get_troopdata()`](https://meflynn.github.io/troopdata/reference/get_troopdata.md)
has the same information in shorter form.

### Annual values are the highest value reported in the year

The data are stored by report period. There is one report per year
through 2012 (dated June for 1950 and 1953 through 1956, and September
from 1957), two for 2013 (September and December), and four per year
from 2014 (March, June, September and December). The most recent year
only has the reports published so far, so 2026 currently rests on the
March report alone.

When you ask for annual data, which is the default, each column holds
the **largest value reported for that location in that year**. A few
things follow from this:

- It is not an average of the quarters, and it is not the value from a
  fixed month like September.
- The largest value is found for each column separately. The total can
  come from one report and the Army or Navy figure from another. For
  Japan in 2019 the four reports show 56,134, 55,327, 55,245 and 57,094
  active duty personnel. The annual `troops_ad` value is 57,094, from
  December. But the annual `army_ad` value (2,671) is from June and the
  annual `navy_ad` value (20,846) is from March.
- Because of this, the branch columns in an annual row do not have to
  add up to `troops_ad`, and `troops_all` does not have to equal
  `troops_ad` plus the guard and reserve columns.
- If you want figures that all come from the same report, use
  `quarters = TRUE`. In the quarterly country data `troops_ad` always
  equals the sum of the branch columns for a row that comes from a
  report.

### Totals

`troops_ad` is active duty personnel. `troops_all` is `troops_ad` plus
the seven National Guard and Reserve columns, and you get it by setting
`guard_reserve = TRUE`. The reports only give guard and reserve figures
from 2008, so before that `troops_all` is the same as `troops_ad`.

The United States figure is the fifty states and the District of
Columbia. Puerto Rico, Guam, the US Virgin Islands and the other
territories are separate locations with their own codes and are not part
of the United States figure.

### Zeros and missing values

A country that a report does not list gets a 0 for that period. So a
zero can mean that the report shows zero, or that the country is not in
the report at all.

Territories and the other locations with our ad hoc codes work
differently, and so do a few small states in the years before their
independence. They only have a row for the periods in which a report
lists them. If you ask for Bermuda for 1995 through 2006, for example,
you get no rows back rather than a set of zeros.

`NA` means the reports do not give that kind of figure. That covers the
guard, reserve and civilian columns and the Coast Guard before 2008, the
Space Force before September 2023, the branch columns for 1951 and 1952,
and the afloat columns for the years and places where the reports do not
assign afloat personnel to a location. In the annual data a value is
only `NA` if it is missing in every report of that year.

### Values that do not come from a report

Most values are exactly what a report shows. These are the exceptions.
The `source` column in the `troopdata_rebuild_long` data frame
identifies most of them. The two it does not flag are the Army quarters
of 2022 and 2023, which carry the name of their report, and the Iraq
figure for 2018 through 2020, which has no source label.

- **1951 and 1952.** There are no reports for these two years. The total
  for each country moves in equal steps from the June 1950 figure to the
  June 1953 figure, and the branch columns are `NA`. Most territories,
  and the Afloat location, have no rows at all for these two years.
- **December 2022, March 2023 and June 2023.** The Army did not provide
  personnel data for these three quarters while it converted to a new
  personnel system. In the country data the Army’s active duty, National
  Guard and Reserve figures move in equal steps from the September 2022
  report to the September 2023 report, and the totals are those figures
  plus what the other services reported. Everything the other services
  reported is left as published. The data for US states and the report
  data (`reports = TRUE`) are not filled in, so the Army figures and the
  totals are `NA` for those quarters. (The United States row in the
  report data is the one exception. It is added up from the states and
  carries a fixed Army figure for those quarters.)
- **June 2023.** The June 2023 workbook has two blocks of its overseas
  list printed one row too low: the civilian columns from Montenegro to
  the end of the list, and five of the guard and reserve columns from
  Morocco to Wake Island. Qatar’s row shows Puerto Rico’s 2,201
  civilians, and Uruguay’s shows the United Kingdom’s 1,383. The
  neighboring reports and the report’s own totals confirm where the
  figures belong, so the country data read them from the row below the
  one they are printed on. The report data (`reports = TRUE`) keep the
  sheet as published.
- **War zones.** The reports do not show the personnel deployed to Iraq,
  Kuwait and Afghanistan for much of the 2000s, and from December 2017
  they leave out deployed personnel in Afghanistan, Iraq and Syria. For
  some of those years we use figures from Kane’s data or from public
  reporting: Afghanistan for 2001-2005 and 2018-2020, Iraq for 2003-2007
  and 2018-2021, Kuwait for 2003-2007, and Syria for 2018-2021. These
  are totals only, so the branch columns are zero for those rows. We do
  not have outside figures after those years. The values for Afghanistan
  from 2021 and for Iraq and Syria from 2022 are the small numbers the
  reports show, and they are well below the actual US presence. In the
  quarterly data the outside figures for Iraq in 2018-2021 and for Syria
  in 2021 are on the June row only. The other quarters of those years
  show what the report prints, which is zero or close to it, so use the
  annual data for these cases.
- **Rows dated June between 1957 and 2013.** The reports for those years
  are dated September (and December in 2013). If you pull quarterly data
  for those years you will also see some rows dated June. These hold
  figures from Kane’s data, or one of the estimates above, and they are
  kept only for a location and year where no report gives a figure, or
  where the report prints a zero in its place. Nearly all of them are
  zero.

### Where personnel are counted

- Personnel are counted in the location the report lists them under. We
  do not move them to a parent country, so Greenland is Greenland and
  not Denmark.
- Personnel that a report lists under no location are not in the data.
  The older reports have lines such as “Transients”, “Undistributed” and
  “Departmental Headquarters”, and the newer ones have “Unknown”. These
  can be large (about 207,000 people in 1968), so adding up every row in
  the data gives you less than the worldwide total printed in the
  report.
- When a report lists two places under what we treat as one country, the
  country figure is the sum. Japan and the Ryukyu Islands (Okinawa) are
  the main case, through 1973. Setting `reports = TRUE` shows each of
  those rows separately.
- For 1950 through 2007 the country figures are personnel ashore, and
  the `afloat` argument controls what happens to personnel afloat (see
  above). From September 2008 the reports count a ship’s crew at its
  home port.
- From December 2015 to December 2017 the reports list between 77,000
  and 105,000 personnel, nearly all Navy, in the United States block but
  in no state. They are not in any of the figures.

### Country codes

The numeric codes are Gleditsch and Ward codes, not Correlates of War
codes. The two lists mostly agree, but Germany is 260 here (the Federal
Republic, before and after 1990) and East Germany is 265. The two Congos
are 484, the Republic of the Congo (Brazzaville), and 490, the
Democratic Republic of the Congo (Kinshasa, formerly Zaire). The reports
of 1960 through 1962 have a single “Congo” line, which is the former
Belgian Congo and is counted under 490. Locations that the Gleditsch and
Ward list does not cover have ad hoc codes, for example 6 for Puerto
Rico, 1002 for Greenland, 1004 for Diego Garcia, 1008 for Guam and 10200
for personnel afloat. The construction data from
[`get_builddata()`](https://meflynn.github.io/troopdata/reference/get_builddata.md)
use the same codes for the same places. The basing data from
[`get_basedata()`](https://meflynn.github.io/troopdata/reference/get_basedata.md)
have not been rebuilt yet and still use the older codes, so Germany is
255 there.
