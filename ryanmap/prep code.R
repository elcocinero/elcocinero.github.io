#libaries and data input
library(leaflet)
library(rgdal)
library(maps)
library(htmlwidgets)

#  %>%  pipe operator: cmd-shft-m
# comments: cmd-shfit-c

gpx <- 'data/pacific-crest-trail.gpx'
pct <- readOGR(gpx, layer = "tracks")

#getting picture info
# photo.names <- read.csv("photo_directory.csv",stringsAsFactors=FALSE, header=TRUE)
photo.names <- list.files(path="photos")
photo.df=data.frame(photo.names)

exif_time <- function(path) {
  exif_cmd <- 'exiftool -T -r -DateTimeOriginal '  
  cmd <- paste(exif_cmd, '"', path, '"', sep='')
  time_inner <- system(cmd, intern = TRUE) # execute exiftool-command
  time_inner
}

exif_lat <- function(path) {
  exif_cmd <- 'exiftool -T -r -n -GPSLatitude '  
  cmd <- paste(exif_cmd, '"', path, '"', sep='')
  lat_inner <- system(cmd, intern = TRUE) # execute exiftool-command
  lat_inner
}

exif_long <- function(path) {
  exif_cmd <- 'exiftool -T -r -n -GPSLongitude '  
  cmd <- paste(exif_cmd, '"', path, '"', sep='')
  long_inner <- system(cmd, intern = TRUE) # execute exiftool-command
  long_inner
}

for (i in 1:length(photo.df$photo.names)) {
  photo.df$time[i] <- exif_time(paste("photos/",photo.df$photo.names[i], sep=""))
  photo.df$lat[i] <- as.numeric(exif_lat(paste("photos/",photo.df$photo.names[i], sep="")))
  photo.df$long[i] <- as.numeric(exif_long(paste("photos/",photo.df$photo.names[i], sep="")))
}

photo.df


# creating icon
photoIcon <- makeIcon(
  iconAnchorX = 12, iconAnchorY = 12, # center middle of icon on track,
  # instead of top corner  
  iconUrl = "https://www.mapbox.com/maki/renders/camera-12@2x.png"
)


#creating map
mapStates <- map("state", fill=TRUE,
                 plot=FALSE,
                 region=c("California","Oregon","Washington"))

map <- leaflet(pct) %>%
  addProviderTiles("MapBox.ryancook.o8im6llh", group = "Roads") %>%
  addProviderTiles("OpenTopoMap", group = "Topo") %>%
  addProviderTiles("MapQuestOpen.Aerial", group = "Aerial") %>%
  addPolylines (color="red", popup="PCT") %>%
  addMarkers(-116.4697, 32.60758, popup = "Campo", group="Terminals") %>%
  addMarkers(-120.7816, 49.06465, popup = "Manning Park, Canada", group="Terminals") %>%
  addPolygons(data=mapStates, stroke=FALSE, fillColor="#373737") %>%
  addLegend(position="topright",colors="red", labels="PCT", opacity=0.2, title="Trail Map") %>%
  
#   for (i in 1:length(photo.df$photo.names)) {
#       addMarkers(photo.df$long[i], photo.df$lat[i], icon=photoIcon, group='Photos', popup=photo.df$time[i]) %>%
#   }

  hideGroup("Terminals") %>%
  
  addLayersControl(
    baseGroups = c("Roads","Topo","Aerial"),
    overlayGroups=c("Terminals","Photos"),
    options = layersControlOptions(collapsed=FALSE)
  )

  for (i in 1:length(photo.df$photo.names)) {
      map <- addMarkers(map, lng=photo.df$long[i], lat=photo.df$lat[i], icon=photoIcon, group='Photos', popup=
                          paste(
                            "<div><a target='_blank' href='photos/",
                            photo.df$photo.names[i],
                            "'><img width=300, height=100% src='photos/",
                            photo.df$photo.names[i],
                            "' /></a></div><div>Caption text to be inserted here</div>",
                            sep=""))
  }

# 
# paste(
#   "<div><img width=300px, height=100% src='photos/",
#   photo.df$photo.names[i],
#   "' /></a></div>",
#   sep=""))


# paste(
#   "<div><a target='_blank' href='photos/",
#   photo.df$photo.names[i],
#   "'><img width=100%, height=100% src='photos/",
#   photo.df$photo.names[i],
#   "' /></a></div><div>Caption text to be inserted here</div>",
#   sep=""))




map

#exporting to html
saveWidget(widget = map, file="index.html", selfcontained = FALSE)

