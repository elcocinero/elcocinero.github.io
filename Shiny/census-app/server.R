# server.R
library(maps)
library(mapproj)
source("helpers.R")
counties <- readRDS("data/counties.rds")

shinyServer(
  function(input, output) {
    
    output$map <- renderPlot({
      data <- switch(input$var, 
                     "Percent White" = counties$white,
                     "Percent Black" = counties$black,
                     "Percent Hispanic" = counties$hispanic,
                     "Percent Asian" = counties$asian)
      color <- switch(input$var, 
                      "Percent White" = "darkgreen",
                      "Percent Black" = "black",
                      "Percent Hispanic" = "darkorange",
                      "Percent Asian" = "darkviolet")
      percent_map(var=data, color=color,
                  input$var,
                  min=input$range[1],
                  max=input$range[2]
                  )
    })
    
  }
    )