# install.packages(c('rgdal', 'leaflet', 'sp', 'lubridate', 'ggplot2'))
# 
# library(leaflet)  # for generating interactive Javascript maps
# library(rgdal)    # GDAL bindings for loading GPX-data
# library(sp)       # spatial operations library
# library(lubridate)# datetime-operatings, here to convert from strings
# library(ggplot2)  # general plotting library

GPX_file1 <- 'GPX/20140220-141528-Ride.gpx'
GPX_file2 <- 'GPX/20140816-131608-Ride.gpx'
wp1 <- readOGR(GPX_file1, layer = "track_points")
wp2 <- readOGR(GPX_file2, layer = "track_points")

#adding to leaflet
track1 <- readOGR(GPX_file1, layer = "tracks", verbose = FALSE)
track2 <- readOGR(GPX_file2, layer = "tracks", verbose = FALSE)

m <- leaflet() %>%
  
  # Add tiles
  addProviderTiles("MapBox.ryancook.o8im6llh", group = "Roads") %>%
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
  
  addLegend(position = 'bottomright',opacity = 0.4, 
            colors = c('blue', 'red'),
            labels = c('Gimillan-Grausson', 'test'),
            title = 'Hikes Italy, region Aosta') %>%
  
  # Layers control
  addLayersControl(position = 'bottomright',
                   baseGroups = c( "Roads", "Satellite"),
#                    overlayGroups = c("Hiking routes", "Photo markers"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  
  addPolylines(data=track1, color='blue', group='Hiking routes')  %>%
  addPolylines(data=track2, color='red', group='Hiking routes') 

m
