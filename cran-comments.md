## Test environments
* local R installation, R 4.0.3
* ubuntu 16.04 (on travis-ci), R 4.0.3
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

R CMD check via `devtools::check()` produces no errors or warnings. 

Note that this is a re-submission, but I changed the version number from 1.1.0 to 0.1.2 after re-reading the version guidelines. I think this version change better reflects the best practices as I understand them as described here (https://r-pkgs.org/release.html).

`devtools::spell_check()` indicates a few spelling errors. I have reviewed these and most of the hits pertain to proper nouns. One term "lilypad" is a variable name used to refer to a specific category of military bases. Other terms, like "metropole" and "DMDC", are accurate.

I reference URLs for citation purposes in some places. This package does not use an API to access data.
