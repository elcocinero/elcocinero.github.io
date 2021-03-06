install.packages(c('rgdal', 'leaflet', 'sp', 'lubridate', 'ggplot2'))

library(leaflet)  # for generating interactive Javascript maps
library(rgdal)    # GDAL bindings for loading GPX-data
library(sp)       # spatial operations library
library(lubridate)# datetime-operatings, here to convert from strings
library(ggplot2)  # general plotting library

# GPX_file <- 'GPX/20140220-141528-Ride.gpx'
GPX_file <- 'GPX/20140816-131608-Ride.gpx'
wp <- readOGR(GPX_file, layer = "track_points")
head(wp[,c('ele', 'time')])

hike.dists <- spDists(wp, segments=TRUE)
sum(hike.dists) # in km

wp$time <- ymd_hms(wp$time)   # convert timestamps to datetime-objects


p <- ggplot(as.data.frame(wp), # convert to regular dataframe
            aes(x=time, y=ele)) 
p + geom_point() + labs(x='Hiking time', y='Elevations (meters)') #elevation by time map

#adding to leaflet
track <- readOGR(GPX_file, layer = "tracks", verbose = FALSE)
# leaflet() %>% addTiles() %>% addPolylines(data=track)


m <- leaflet() %>%
  
  # Add tiles
  addProviderTiles("MapBox.ryancook.o8im6llh", group = "Roads") %>%
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
  
  addLegend(position = 'bottomright',opacity = 0.4, 
            colors = 'blue', 
            labels = 'Gimillan-Grausson',
            title = 'Hikes Italy, region Aosta') %>%
  
  # Layers control
  addLayersControl(position = 'bottomright',
                   baseGroups = c( "Roads", "Satellite"),
                   overlayGroups = c("Hiking routes", "Photo markers"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  
  addPolylines(data=track, color='blue', group='Hiking routes') 

m

# TO DO:
#   add hike.dists and elevation change to wp dataframe, to calculated speed and elevation change
#     graph the elevation!
#     convert km to miles
