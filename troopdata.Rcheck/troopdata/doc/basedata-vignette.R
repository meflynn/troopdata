## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(ggplot2)
library(ggtext)

## ----setup--------------------------------------------------------------------
library(troopdata)

## -----------------------------------------------------------------------------

baseexample <- get_basedata(host = NA, country_count = FALSE)

head(baseexample)


## -----------------------------------------------------------------------------

hostlist <- c(20, 200, 255, 645)

baseexample <- get_basedata(host = hostlist, country_count = FALSE)

head(baseexample)


## -----------------------------------------------------------------------------

hostlist.char <- c("CAN", "GBR", "PRI")

baseexample <- get_basedata(host = hostlist.char, country_count = FALSE)


## -----------------------------------------------------------------------------

hostlist <- c(20, 200, 255, 645)

baseexample <- get_basedata(host = hostlist, country_count = TRUE, groupvar = "ccode")

head(baseexample)


## ---- echo = TRUE, warning = FALSE, message=FALSE, dpi = 400------------------

library(ggplot2)

map <- ggplot2::map_data("world")
basepoints <- get_basedata(host = NA)


basemap <- ggplot() +
  geom_polygon(data = map, aes(x = long, y = lat, group = group), fill = "gray80", color = "white", size = 0.1) +
  geom_point(data = basepoints, aes(x = lon, y = lat), color = "purple", alpha = 0.6) +
  coord_equal(ratio = 1.3) +
  theme_void() +
  theme(plot.title = element_markdown(face = "bold", size = 15)) +
  labs(title = "Locations of U.S. military facilities, 1950-2018")


basemap


