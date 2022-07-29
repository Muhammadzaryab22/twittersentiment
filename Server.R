library(shiny)
library(shinythemes)
library(rtweet)
library(ggplot2)
library(dplyr)
library(ggwordcloud)
library(tidytext)
library(textdata)
library(tidyquant)
library(tidyr)
library(stringr)
library(plotly)

## Creating token

api_key <- "TfurwtZmw4k4V61YIbwtQPHTQ"
api_secret_key <- "3hYjDw16hZ3g02gpgMPNkmADCRnjf0hfks0GHLp1lCqs2dnZfk"
access_token <- "1538193864531619841-zvGVROL1xOttZQ3ThLvDudN4NSSBxG"
access_secret <- "WKnhcMeDaaOHQAtNrlceID2bb8GHON5kiVwWjMCbwtCXD"

token <- create_token(
  app = "geoanalysis22",
  consumer_key = api_key,
  consumer_secret = api_secret_key,
  access_token =access_token,
  access_secret = access_secret
  
)


# Server -------------

server <- function(session, input, output) {
  
  ## setting up reactive values
  
  rv <- reactiveValues()
  
  observeEvent(input$submit, {
    
    rv$data <- search_tweets(
      q = input$query,
      n = input$n_tweets,
      include_rts = FALSE,
      lang = "en",
      token = token
    )
    
    rv$tweet_sentiment <- rv$data %>%
      select(text) %>%
      tibble::rowid_to_column() %>%
      unnest_tokens(word, text) %>%    ##double check
      inner_join(get_sentiments("bing"))
  }, ignoreNULL = FALSE)
  

  ## plotly
  
  output$plotly <- renderPlotly({
    req(rv$tweet_sentiment, rv$data)
    
    sentiment_by_row_id_tbl <- rv$tweet_sentiment %>%
      select(rowid, sentiment) %>% ##double check
      count(rowid, sentiment) %>%
      pivot_wider(names_from = sentiment, values_from = n, values_fill = list(n=0)) %>%
      mutate(sentiment = positive  - negative) %>%
      left_join(
        rv$data %>% select(screen_name, text, location) %>% tibble::rowid_to_column()
      )
    
    label_wrap <- label_wrap_gen(width = 60)
    
    data_formatted <- sentiment_by_row_id_tbl %>% 
      mutate(text_formatted = str_glue("Row ID: {rowid}
                                       Screen Name: {screen_name}
                                       Text:
                                       {label_wrap(text)}"))
    
    g <- data_formatted %>% 
      ggplot(aes(rowid, sentiment)) +
      geom_line(color = "#2c3e50", alpha = 0.5) +
      geom_point(aes(text = text_formatted), color = "#2c3e50") +
      geom_smooth(method = "loess", span = 0.25, se= FALSE, color= "blue") + 
      geom_hline(aes(yintercept = mean(sentiment)), color= "blue") +
      geom_hline(aes(yintercept = median(sentiment) + 1.96*IQR(sentiment)), color = "red") + 
      geom_hline(aes(yintercept = median(sentiment) - 1.96*IQR(sentiment)), color = "red") + 
      theme_tq() +
      labs(title = "Sentiment Polarity", x = "Twitter User", y= "Sentiment")
    
    ggplotly(g, tooltip = "text") %>% 
      layout(
        xaxis = list(
          rangeslider = list(type = "date")
        )
      )
    
  })
  
  ## Wordcloud ---
  
  output$wordcloud <- renderPlot({
    
    req(rv$data)
    
    tweets_tokenized_tbl <- rv$data %>%
      select(text) %>%
      tibble::rowid_to_column() %>%
      unnest_tokens(word, text)
    
    sentiment_bing_tbl <- tweets_tokenized_tbl %>%
      inner_join(get_sentiments("bing"))
    
    sentiment_by_word_tbl <- sentiment_bing_tbl %>% 
      count(word, sentiment, sort = TRUE)
    
    sentiment_by_word_tbl %>%
      slice(1:100) %>%
      mutate(sentiment = factor(sentiment, levels = c("positive", "negative"))) %>%
      ggplot(aes(label = word, color = sentiment, size = n)) +
      geom_text_wordcloud_area() +
      facet_wrap(~ sentiment, ncol = 2) +
      theme_tq(base_size = 30) +
      scale_color_tq() +
      scale_size_area(max_size = 16)
  })
    
    
}
