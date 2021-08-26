# troopdata 0.1.4

* Introduces `get_builddata()` which returns a data frame containing location-year U.S. military construction spending at select overseas locations.
* Fixed multiple errors with `get_troopdata()`:
  * 2014 UK values were missing from data.
  * Fixes error with  `get_troopdata()` Kuwait 2006 troop values showing up as 0. Replaced with estimate derived from supplementary sources.
  * Provides updated estimated for Iraq (2006, 2007), Kuwait (2006, 2007), and Syria (2018, 2019, 2020)

# troopdata 0.1.3

* Fixed error where Kane data classifies troops as being present in Vietnam during the Vietnam War but COW recognizes South Vietnam as a separate country.
* Fixed error where `get_troopdata()` function was always returning branch data.

# troopdata 0.1.2

* Modified version number down to better adhere to R package best practices.
* Improved documentation for package and functions.

# troopdata 1.1.0

# troopdata 1.0.0

* troopdata version 1.0.0 release!
* New package providing access to US military deployment and overseas basing data.
* `get_troopdata()` returns a data frame of country-year observations with options to return total troop deployment values or service branch-specific deployment values.
* `get_basedata()` returns a data frame containing David Vine's US basing data with options to return site-specific data or country-level base count data.
* Minor bug fixes.

# troopdata 0.0.0.9000

* Added a `NEWS.md` file to track changes to the package.
