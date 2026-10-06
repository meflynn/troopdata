## SUPERSEDED -- do not run.
#
# This script built the old `builddata` object from the 2021 operations and
# maintenance extract (data-spend-geocoded-20210428.csv in the Minerva folder).
#
# The construction spending data now comes from the DoD Comptroller Annual Report
# C-1 exhibits. data-raw/build_data_20260603.R reads every sheet of those
# workbooks, geocodes them, writes data-raw/build_data_20260604.csv, and calls
# usethis::use_data() itself to write data/build_data_20260918.rda. There is no
# separate packaging step: run build_data_20260603.R and the packaged dataset is
# produced with it.
#
# get_builddata() reads troopdata::build_data_20260918. data/builddata.rda is
# retained only for reproducibility of earlier analyses and is not read by any
# function in the package.
