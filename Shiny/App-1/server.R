# server.R

shinyServer(function(input, output) {
  
  output$text1 <- renderText({ 
    paste("You have selected", input$var, "from", input$range[1], "to", input$range[2])
  })
  
}
)