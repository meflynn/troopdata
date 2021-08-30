## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(ggplot2)

## ----setup--------------------------------------------------------------------
library(troopdata)

## ----example, warning=FALSE, echo = FALSE, message=FALSE----------------------
library(troopdata)
## basic example code

# This example uses the basic function to gather total troop figure
example <- get_troopdata(startyear = 1990, endyear = 2020)


## -----------------------------------------------------------------------------

# Let's make the host selection more specific
hostlist <- c(200, 220)

example <- get_troopdata(host = hostlist, startyear = 1990, endyear = 2020)

head(example)


## -----------------------------------------------------------------------------

hostlist.char <- c("CAN", "GBR")

example.char <- get_troopdata(host = hostlist.char, startyear = 1970, endyear = 2020)

head(example.char)


## -----------------------------------------------------------------------------

hostlist <- c(20, 200, 220)

example <- get_troopdata(host = hostlist, branch = TRUE, startyear = 2006, endyear = 2020)

head(example)


## -----------------------------------------------------------------------------

regional.sum <- get_troopdata(host = "region", startyear = 1990, endyear = 2020) 

ggplot(regional.sum, aes(x = year, y = troops, color = region)) + 
  geom_line() +
  viridis::scale_color_viridis(discrete = TRUE) +
  labs(x = "Year",
       y = "Count",
       title = "Troop deployments by region",
       color = "Region")
  


