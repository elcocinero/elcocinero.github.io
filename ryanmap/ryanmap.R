library(leaflet)
library(rgdal)
library(maps)
library(htmlwidgets)

# map <- leaflet() %>% addTiles()
# map

#  %>%  pipe operator: cmd-shft-m
# comments: cmd-shfit-c

gpx <- 'data/pacific-crest-trail.gpx'
pct <- readOGR(gpx, layer = "tracks")

mapStates <- map("state", fill=TRUE,
                plot=FALSE,
                region=c("California","Oregon","Washington"))

map <- leaflet(pct) %>%
  addProviderTiles("MapBox.ryancook.o8im6llh", group = "Roads") %>%
  addPolylines (color="red", popup="PCT") %>%
  addMarkers(-116.4697, 32.60758, popup = "Campo") %>%
  addMarkers(-120.7816, 49.06465, popup = "Manning Park, Canada") %>%
  addPolygons(data=mapStates, stroke=FALSE, fillColor="#373737") %>%
  addLegend(position="topright",colors="red", labels="PCT", opacity=0.2, title="Trail Map")
  
map

saveWidget(widget = map, file="index.html", selfcontained = FALSE)
