# install.packages("Quandl")
# install.packages("reshape2")
# install.packages("RColorBrewer")
# install.packages("plyr")
# require(devtools)
# install_github('ramnathv/rCharts@dev')
# install_github('ramnathv/rMaps')

#rmaps still under development, must be installed from github

library(Quandl)
library(reshape2)
library(RColorBrewer)
library(plyr)
library(rMaps)
library(rCharts)

#import data 
vcData <- Quandl("FBI_UCR/USCRIME_TYPE_VIOLENTCRIMERATE")

#transpose data using melt()
datm <- melt(vcData, 'Year', variable.name = 'State', value.name='Crime')

#turning na to 0
datm$Crime[is.na(datm$Crime)] <- 0

# cleaning the data into usable columns
datm2 <- transform(datm,
#   using default state.abb and state.name to change text to abbrev
  State = state.abb[match(as.character(State), state.name)],  
#   categorizes into quantiles.
#   CUT says to break up crime across a number of breaks
#   quantile says where the breaks are
#   labels says what to call the categories
  fillKey = cut(Crime, quantile(Crime, seq(0,1,1/5)), labels = LETTERS[1:5]),
#   takes just the year from the date
  Year = as.numeric(substr(Year,1,4))  
)

#creating dataframe of colors to match to letters
fills <- setNames(
  c(brewer.pal(5,'YlOrRd'),'white'),
  c(LETTERS[1:5],'defaultFill')
  )


# does two things:
#   1: with dlply, converts dataframe to list by year
#   2: when recombining as a list, sends to a jsonarray
dat2 <- dlply(na.omit(datm2), "Year", function(x){
  y = toJSONArray2(x, json = F)
  names(y) = lapply(y, '[[', 'State')
  return(y)
})

# basic cloropleth
options(rcharts.cdn = TRUE)
map <- Datamaps$new()
map$set(
  dom = 'chart_1',
  scope = 'usa',
  fills = fills,
  data = dat2[[1]],
  legend = TRUE,
  labels = TRUE
)
map

#adding angular js
map2 <- map$copy()
map2 = map$copy()
map2$set(
  bodyattrs = "ng-app ng-controller='rChartsCtrl'"
)
map2$addAssets(
  jshead = "http://cdnjs.cloudflare.com/ajax/libs/angular.js/1.2.1/angular.min.js"
)

map2$setTemplate(chartDiv = "
  <div class='container'>
    <input id='slider' type='range' min=1960 max=2010 ng-model='year' width=200>
    <span ng-bind='year'></span>
    <div id='' class='rChart datamaps'></div>  
  </div>
  <script>
    function rChartsCtrl($scope){
      $scope.year = 1960;
      $scope.$watch('year', function(newYear){
        map.updateChoropleth(chartParams.newData[newYear]);
      })
    }
  </script>"
)

map2$set(newData = dat2)
map2

map$save('index.html', cdn=TRUE)
