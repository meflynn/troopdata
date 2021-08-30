pkgname <- "troopdata"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
options(pager = "console")
library('troopdata')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("get_basedata")
### * get_basedata

flush(stderr()); flush(stdout())

### Name: get_basedata
### Title: Function to retrieve customized U.S. basing data
### Aliases: get_basedata

### ** Examples


## Not run: 
##D library(tidyverse)
##D library(troopdata)
##D 
##D example <- get_basedata(host = NA)
##D 
##D head(example)
##D 
## End(Not run)




cleanEx()
nameEx("get_troopdata")
### * get_troopdata

flush(stderr()); flush(stdout())

### Name: get_troopdata
### Title: Function to retrieve customized U.S. troop deployment data
### Aliases: get_troopdata

### ** Examples


## Not run: 
##D library(tidyverse)
##D library(troopdata)
##D 
##D example <- get_troopdata(host = NA, branch = TRUE, startyear = 1980, endyear = 2015)
##D 
##D head(example)
##D 
## End(Not run)




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
