library(reshape2)
library(RColorBrewer)
library(plyr)
library(rMaps)
library(rCharts)



#import CSV
EIAraw <- read.csv("Data/distributed gwh by state-csv.csv",stringsAsFactors=FALSE, header=TRUE)


#transpose 
EIAtrans <- melt(EIAraw, 'State', variable.name = 'Month', value.name='GWh')


# setting category breaks and color scheme
cat.breaks <- c(-1,0.5,2,5,10,20,50,100,1000)
cat.labels <- c('<1','1-2','3-5','6-10','11-20','21-50','51-100','>100')
fills <- setNames(
  c(brewer.pal(8,'YlGnBu')),
  cat.labels
)

# categorizing months
months <- names(EIAraw[2:length(names(EIAraw))])


# cleaning
EIAclean <- transform(EIAtrans,
                     #   using default state.abb and state.name to change text to abbrev
                     State = state.abb[match(as.character(State), state.name)],  
                     #   categorizes into quantiles.
                     #   CUT says to break up crime across a number of breaks
                     #   quantile says where the breaks are
                     #   labels says what to call the categories
                     fillKey = cut(GWh, cat.breaks, labels = cat.labels),
                     #   takes just the year from the date
                     Month = match(Month,months)
  )


# Month = paste(formatC(match(substr(Month,1,3),month.abb), width=2, flag="0"),"/",substr(Month,5,7)," (",month.name[match(substr(Month,1,3),month.abb)],")",sep="")


# transforming to list and sending to json
EIAlist <- dlply(na.omit(EIAclean), "Month", function(x){
  y = toJSONArray2(x, json = F)
  names(y) = lapply(y, '[[', 'State')
  return(y)
})


# creating flat map
options(rcharts.cdn = TRUE)
pvmap <- Datamaps$new()
pvmap$set(
  dom = 'chart_1',
  scope = 'usa',
  fills = fills,
  data = EIAlist[[1]],
  legend = TRUE,
  labels = TRUE
)

#adding angular js
pvmap$set(
  bodyattrs = "ng-app ng-controller='rChartsCtrl'"
)
pvmap$addAssets(
  jshead = "http://cdnjs.cloudflare.com/ajax/libs/angular.js/1.2.1/angular.min.js"
)


# making interactive
pvmap$setTemplate(chartDiv = "
        <div class='container'>
          <input id='slider' type='range' min=1 max=24 ng-model='month' width=200>
          Month <span ng-bind='month'></span> (Timeframe: January 2014 - October 2015)
          <div id='{{chartId}}' class='rChart datamaps'></div>  
        </div>
        <script>
          function rChartsCtrl($scope){
            $scope.month = 1;
            $scope.$watch('month', function(newMonth){
              map{{chartId}}.updateChoropleth(chartParams.newData[newMonth]);
            })
          }
       </script>"
)
pvmap$set(newData = EIAlist)

pvmap

pvmap$save('distgenbymonth.html', cdn=TRUE)


