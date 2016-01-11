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
map$set(
  bodyattrs = "ng-app ng-controller='rChartsCtrl'"
)
map$addAssets(
  jshead = "http://cdnjs.cloudflare.com/ajax/libs/angular.js/1.2.1/angular.min.js"
)



#Slider
map_slider = map$copy()
map_slider = map$copy()
map_slider$setTemplate(chartDiv = "
        <div class='container'>
          <input id='slider' type='range' min=1960 max=2010 ng-model='year' width=200>
          <span ng-bind='year'></span>
          <div id='{{chartId}}' class='rChart datamaps'></div>  
        </div>
        <script>
          function rChartsCtrl($scope){
            $scope.year = 1960;
            $scope.$watch('year', function(newYear){
              map{{chartId}}.updateChoropleth(chartParams.newData[newYear]);
            })
          }
       </script>"
)
map_slider$set(newData = dat2)
map_slider


#Dropdown
map_dropdown = map$copy()
map_dropdown$setTemplate(chartDiv = "
        <div class='container'>
          <div class='col-md-2'>
            <select ng-model='year' class='form-control'
               ng-options='year for year in [1960, 1980, 2000]'>
              {{ year }}
            </select>
          </div>
          <div id='{{chartId}}' class='rChart datamaps'></div>  
        </div>
        <script>
          function rChartsCtrl($scope){
            $scope.year = 1960;
            $scope.$watch('year', function(newYear){
              map{{chartId}}.updateChoropleth(chartParams.newData[newYear]);
            })
          }
       </script>"
)
map_dropdown$set(newData = dat2)
map_dropdown


#Buttons
map_buttons = map$copy()
map_buttons = map$copy()
map_buttons$setTemplate(chartDiv = "
        <div class='container'>
          <div class='btn-group'>
            <button ng-repeat=\"value in years\" ng-click='updateYear(value)'
              class=\"btn btn-default\" type=\"button\"
              ng-model=\"value\" btn-radio=\"value\">
              {{ value }}
            </button>
          </div>
          <div id='{{chartId}}' class='rChart datamaps'></div>  
        </div>
        <script>
          function rChartsCtrl($scope){
            $scope.years = [1960, 1980, 2000]
            $scope.year = $scope.years[0]
            $scope.updateYear = function(x){
              $scope.year = x
            }
            $scope.$watch('year', function(newYear){
              mapchart_1.updateChoropleth(chartParams.newData[newYear]);
            })
          }
       </script>"
)
map_buttons$set(newData = dat2)
map_buttons



map_slider$save('slider.html', cdn=TRUE)
map_dropdown$save('dropdown.html', cdn=TRUE)
map_buttons$save('buttons.html', cdn=TRUE)
