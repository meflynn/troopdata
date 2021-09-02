# troopdata 0.1.4

* Introduces get_builddata() function which returns a data frame containing location-year U.S. military construction spending in thousands of current US dollars.
* Adds option to generate regional sums of military personnel by setting host = "region" when calling get_troopdata() function.
* Fixed multiple errors with get_troopdata():
  * 2014 UK values were missing from data.

  * Fixes error with get_troopdata() Kuwait 2006 troop values showing up as 0. Replaced with estimate derived from supplementary sources. See notes below.

  * Provides updated estimated for Iraq (2006, 2007), Kuwait (2006, 2007), and Syria (2018, 2019, 2020)

  * Iraq, Afghanistan, and Syria data for 2018-2020 were estimated from reports and we continue to update those numbers based on information we can get. Just Security has engaged in a legal process and sued the DOD to get precise counts of troops in Iraq, Afghanistan, and Syria, but the DOD has obfuscated the total counts by classifying the majority of deployments as temporary. Read through the whole saga here: https://www.justsecurity.org/75124/just-security-obtains-overseas-troop-counts-that-the-pentagon-concealed-from-the-public/. Thanks to Thomas Campbell at Boise State for pointing out this data. To reflect new public data, we have updated the estimates as follows:

  * Changes:
 
     * Afghanistan 2020: Updated to 8600 from 4500.
    
     * Afghanistan 2019: Updated to 13000 from 14500
    
     * Syria 2018: Updated to 1700 from 2000
    
     * Syria 2019: Updated to 1000 from 400
    
     * Syria 2020: Updated to 900 from 600

     * Kuwait 2006 and 2007 numbers didn’t make sense as it goes from 42600 troops in 2005 to 0 for two years and then back up to 42285 in 2008. For 2006 and 2007, these numbers were rolled into a total “Operation Iraqi Freedom” count that included all nearby countries. We have reverse-engineered this a bit and have new numbers for Kuwait. Kuwait 2006 updated to 44,400 from 0. We got this number from 185,500 total OIF and subtracting the average from 2006 reported in the above document. Kuwait 2007 updated to 48500 from 0.

     * Iraq 2006: Updated to 141100 from 185500, using 2006 average from here: https://fas.org/sgp/crs/natsec/R40682.pdf

     * Iraq 2007: Updated to 170000 from 218500, source for the first number is: https://www.reuters.com/article/us-iraq-usa-pullout/timeline-invasion-surge-withdrawal-u-s-forces-in-iraq-idUSTRE7BE0EL20111215

     * Iraq 2006 and 2007: Individual force counts changed to NA.

These numbers continue to be estimates in a few cases, so we will continue to update these numbers as we get more reliable figures.


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
