## Test environments
* local R installation, R 4.0.3
* ubuntu 16.04 (on travis-ci), R 4.0.3
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

R CMD check via `devtools::check()` often produces different results depending on whether I use the Build window or execute the command in the Console. Using the Build window regularly results in 1 error, 0 warnings, and 0 notes, with an install failure message of "* install options '--no-html'". When I run the check through the Console I get 0 errors, 0 warnings, and 0 notes. I've tried to find an explanation and remedy for this discrepancy but have had no luck resolving the issue. The package otherwise installs and functions as it should on my machine and for other users on other machines.

`devtools::spell_check()` indicates a few spelling errors. I have reviewed these and most of the hits pertain to proper nouns. One term `lilypad` is a variable name used to refer to a specific category of military bases. 
