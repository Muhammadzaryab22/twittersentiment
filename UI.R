




ui <- navbarPage(
  title = "Twitter Sentiment App",
  collapsible = TRUE,
  inverse = TRUE,
  theme = shinytheme("paper"),
  
  shiny::tabPanel(
    title = "Sentiment Tracker",
    sidebarLayout(
      sidebarPanel(
        shiny::textInput(inputId = "query", label = "Topic/Hashtag", value = "#Bitcoin"),
        sliderInput(
          inputId = "n_tweets",
          label = "Number of tweets:",
          min = 1,
          max = 1500,
          value = 100),
        shiny::actionButton(inputId = "submit", "Submit", class = "btn-primary")
        ),
      
      # Show a plot
      
      mainPanel(
        div(
          classs = "row",
          div(
            class = "col-sm-8 panel",
            div(class = "panel-heading", h5("Sentiment Polarity")),
            div(class = "panel-body", plotlyOutput(outputId = "plotly", height = "250px"))
                
                
              ) ,
          div(
            class = "col-sm-8 panel",
            div(class = "panel-heading", h5("Word Cloud")),
            div(class = "panel-body", plotOutput(outputId = "wordcloud", height = "250px"))
            
            
          )
          
          
        )
      ),
      
      
      
      
      
    )
    
  )

)  

