#libaries and data input
library(leaflet)
library(rgdal)
library(maps)
library(htmlwidgets)

#  %>%  pipe operator: cmd-shft-m
# comments: cmd-shfit-c


# getting trip info
trips <- read.csv("Trips.csv",stringsAsFactors=FALSE, header=TRUE)
trip.markers <- trips[trips$Marker==1,c('City','Lat','Lng')]

unique.trips <- trips[trips$Marker==1,c('City','Lat','Lng')]
unique.trips <- unique(unique.trips)



# getting gpx info
# using: http://www.gpsvisualizer.com/convert_input?convert_format=gpx
trail.names <- list.files(path="gpx")


for (i in 1:length(trail.names)) {
  assign(paste("GPX",i,".gpx",sep=""), readOGR(paste("gpx/",trail.names[i],sep=""), layer = "tracks"))
}



#getting picture info
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

months <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

photo.df$month <- paste(months[as.numeric(substr(photo.df$time,6,7))],substr(photo.df$time,1,4),sep=" ")
photo.df$monthnum <- as.numeric(substr(photo.df$time,1,4)) + (as.numeric(substr(photo.df$time,6,7))/100)

unique.months <- photo.df$monthnum
unique.months <- unique(unique.months)
unique.months <- unique.months[order(unique.months)]
unique.months <- paste(months[as.numeric(substr(unique.months,6,7))],substr(unique.months,1,4),sep=" ")


# creating icon
photoIcon <- makeIcon(
  iconAnchorX = 12, iconAnchorY = 12, # center middle of icon on track,
  # instead of top corner  
  iconUrl = "https://www.mapbox.com/maki/renders/camera-12@2x.png"
)

cityIcon <- makeIcon(
  iconAnchorX = 12, iconAnchorY = 12, # center middle of icon on track,
  # instead of top corner  
  iconUrl = "http://www.capitolscientific.com/core/media/media.nl?id=453195&c=1250437&h=f177909298363d4e354b"
)

blanks="&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"

#creating map
# mapStates <- map("state", fill=TRUE,
#                  plot=FALSE,
#                  region=c("California","Oregon","Washington"))

map <- leaflet() %>%
  setView(lat = 39.50, lng = -98.35, zoom = 5) %>%
  addProviderTiles("MapBox.ryancook.o8im6llh") %>%
#   addPolylines (color="red", popup="PCT") %>%
#   addPolygons(data=mapStates, stroke=FALSE, fillColor="#373737") %>%
#   addLegend(position="topright",colors="red", labels="PCT", opacity=0.2, title="Trail Map") %>%
  
  
#   for (i in 1:length(photo.df$photo.names)) {
#       addMarkers(photo.df$long[i], photo.df$lat[i], icon=photoIcon, group='Photos', popup=photo.df$time[i]) %>%
#   }

  
  addLayersControl(
    overlayGroups=c("Cities","Photos","Plane","Car"),
    options = layersControlOptions(collapsed=FALSE)
  )

  map <- addPolylines(map,lng=trip.markers$Lng, lat=trip.markers$Lat, color="black", opacity=0.3, weight=2, group="Plane")

#   map <- addPolylines(map,data=trail, color="black", opacity=0.3, weight=2, group="Car")

for (i in 1:length(trail.names)) {
  map <- addPolylines(map,data=get(trail.names[i]), color="black", opacity=0.3, weight=2, group="Car")
}


for (i in 1:length(unique.trips$City)) {
  map <- addCircleMarkers(map, lng=unique.trips$Lng[i], lat=unique.trips$Lat[i], group="Cities", popup=unique.trips$City[i])
}


  for (i in 1:length(photo.df$photo.names)) {
      map <- addMarkers(map, lng=photo.df$long[i], lat=photo.df$lat[i], icon=photoIcon, group="Photos", popup=
                          paste(
                            "<div>",blanks,"</div><div width=300><a target = '_blank' href='photos/",
                            photo.df$photo.names[i],
                            "'><img width=100%, height=100% src='photos/",
                            photo.df$photo.names[i],
                              "' /></a></div><div>",blanks,"</div>",
                            sep=""))
  }



map

#exporting to html
saveWidget(widget = map, file="index.html", selfcontained = FALSE)

