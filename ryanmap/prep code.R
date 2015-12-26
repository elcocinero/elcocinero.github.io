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
  photo.df$date[i] <- substr(exif_time(paste("photos/",photo.df$photo.names[i], sep="")),1,10)
  photo.df$lat[i] <- as.numeric(exif_lat(paste("photos/",photo.df$photo.names[i], sep="")))
  photo.df$long[i] <- as.numeric(exif_long(paste("photos/",photo.df$photo.names[i], sep="")))
}

# correcting photo errors
PhotoEdits <- read.csv("PhotoEdits.csv",stringsAsFactors=FALSE, header=TRUE)
DateEdits <- PhotoEdits[PhotoEdits$Year != ".",c("ImageID","Year","Month","Day")]
CoordEdits <- PhotoEdits[PhotoEdits$Lat != ".",c("ImageID","Lat","Lng")]

photo.df

for (i in 1:length(DateEdits$ImageID)) {
  photo.df$date[photo.df$photo.names == DateEdits$ImageID[i]] <-paste(DateEdits$Year[i],DateEdits$Month[i],DateEdits$Day[i], sep=":")
}

for (i in 1:length(CoordEdits$ImageID)) {
  photo.df$lat[photo.df$photo.names == CoordEdits$ImageID[i]] <- CoordEdits$Lat[i]
  photo.df$long[photo.df$photo.names == CoordEdits$ImageID[i]] <- CoordEdits$Lng[i]
}


photo.df

# adding month of photo
# months <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
# photo.df$month <- paste(months[as.numeric(substr(photo.df$time,6,7))],substr(photo.df$time,1,4),sep=" ")
# photo.df$monthnum <- as.numeric(substr(photo.df$time,1,4)) + (as.numeric(substr(photo.df$time,6,7))/100)
# 
# unique.months <- photo.df$monthnum
# unique.months <- unique(unique.months)
# unique.months <- unique.months[order(unique.months)]
# unique.months <- paste(months[as.numeric(substr(unique.months,6,7))],substr(unique.months,1,4),sep=" ")


# creating photo icon
photoIcon <- makeIcon(
  iconAnchorX = 12, iconAnchorY = 12, # center middle of icon on track,
  # instead of top corner  
  iconUrl = "https://www.mapbox.com/maki/renders/camera-12@2x.png"
)

# blank text to fill line below photo
blanks="&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"

#creating base map
map <- leaflet() %>%
  setView(lat = 39.50, lng = -98.35, zoom = 5) %>%
  addProviderTiles("MapBox.ryancook.o8im6llh") %>%

# adding legend
#   addLegend(position="topright",colors="red", labels="PCT", opacity=0.2, title="Trail Map") %>%


# adding control box
  addLayersControl(
    overlayGroups=c("Cities","Photos","Plane","Car"),
    options = layersControlOptions(collapsed=FALSE)
  )

#adding plane trips
map <- addPolylines(map,lng=trip.markers$Lng, lat=trip.markers$Lat, color="black", opacity=0.3, weight=2, group="Plane")

#adding car rides
for (i in 1:length(trail.names)) {
  map <- addPolylines(map,data=get(trail.names[i]), color="black", opacity=0.3, weight=2, group="Car")
}

#adding city markers
for (i in 1:length(unique.trips$City)) {
  map <- addCircleMarkers(map, lng=unique.trips$Lng[i], lat=unique.trips$Lat[i], group="Cities", popup=unique.trips$City[i])
}

# adding photos
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

