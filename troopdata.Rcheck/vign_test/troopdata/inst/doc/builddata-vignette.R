## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(ggplot2)
library(ggtext)

## ----setup--------------------------------------------------------------------
library(troopdata)

## ----build example------------------------------------------------------------

hostlist <- c(200, 255, 211)

buildexample <- get_builddata(host = hostlist, startyear = 2008, endyear = 2019)

head(buildexample)



## ----buildmap, echo = TRUE, warning = FALSE, message=FALSE, dpi = 400---------

library(ggplot2)

map <- ggplot2::map_data("world")
basepoints <- get_builddata(host = NA, startyear = 2009, endyear = 2019)


buildmap <- ggplot() +
  geom_polygon(data = map, aes(x = long, y = lat, group = group), fill = "gray80", color = "white", size = 0.1) +
  geom_point(data = basepoints, aes(x = lon, y = lat), color = "purple", alpha = 0.4) +
  coord_equal(ratio = 1.3) +
  theme_void() +
  theme(plot.title = element_markdown(face = "bold", size = 15)) +
  labs(title = "Locations of U.S. military construction spending, 2009-2019")


buildmap


