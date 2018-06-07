library(jsonlite)
library(httr)
library(ggvis)
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(reshape2)
library(stringr)

server <- function(input, output, session){
  # datatable options
  DT_OPTIONS <- list(pageLength = 24,
                     lengthMenu = c(24),
                     searching = FALSE)
  
  # ===== INITIAL DATA PULL AND RENDER =====
  # Call day-ahead API --- date format: 2018-06-05T00:00:00
  dateMinusSevenFormatted <- paste0(as.character(Sys.Date()-7), "T00:00:00")
  daReq <- paste0("https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",dateMinusSevenFormatted,"&pnode_id=40243873")
  daResp <- GET(daReq,
           add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                    "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
  daText <- content(daResp, "text")
  daData <- fromJSON(daText, flatten = TRUE)
  
  # Call real-time API
  rtReq <- paste0("https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",dateMinusSevenFormatted,"&pnode_id=40243873")
  rtResp <- GET(rtReq,
               add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                        "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
  rtText <- content(rtResp, "text")
  rtData <- fromJSON(rtText, flatten = TRUE)
  
  # Merge data sets
  mergedData <- data.frame(timestamp = daData$datetime_beginning_ept,
                           dayahead = daData$total_lmp_da,
                           realtime = rtData$total_lmp_rt)
  
  # Melt
  meltedData <- reshape2::melt(mergedData, id = "timestamp")
  
  # Re-name datetime label
  #meltedData$timestamp <- as.POSIXlt(meltedData$timestamp, format = "%Y-%m-%dT%H:%M:%S")
  
  # Output
  output$dartPlot <- renderPlotly({
    #plot_ly(daData, x = ~datetime_beginning_ept, y = ~total_lmp_da)
    plot_ly(source="source") %>%
      add_lines(data = meltedData, x = ~timestamp, y = ~value, color = ~variable) %>%
      layout(title = "Day-ahead vs. Real-time LMP Prices")
  })
  
  output$dataTable1 <- DT::renderDataTable({
    dt <- mergedData %>%
      mutate(timestamp = str_replace(timestamp, "T", " ")) %>%
      DT::datatable(options = DT_OPTIONS)
    dt
  })
  
  
  
  # ===== ON CLICK UPDATE BUTTON =====
  observeEvent(input$update, {
    # Map dropdown options to the correct id
    convertID <- c("Cardinal2"="40243873",
                   "Cardinal3"="40243869",
                   "Greenville1"="40243881",
                   "Greenville2"="40243883",
                   "Greenville3"="40243885",
                   "Greenville4"="40243887",
                   "Mone1"="32419345",
                   "Mone2"="32419347",
                   "Mone3"="32419349")
    
    # Call day-ahead API
    date0Formatted <- paste0(as.character(input$start_date), "T00:00:00")
    daReq <- paste0("https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",date0Formatted,"&pnode_id=",convertID[[input$loc]])
    daResp <- GET(daReq,
                  add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                           "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
    daText <- content(daResp, "text")
    daData <- fromJSON(daText, flatten = TRUE)
    
    # Call real-time API
    rtReq <- paste0("https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",date0Formatted,"&pnode_id=",convertID[[input$loc]])
    rtResp <- GET(rtReq,
                  add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                           "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
    rtText <- content(rtResp, "text")
    rtData <- fromJSON(rtText, flatten = TRUE)
    
    # Merge data sets
    mergedData <- data.frame(timestamp = daData$datetime_beginning_ept,
                             dayahead = daData$total_lmp_da,
                             realtime = rtData$total_lmp_rt)
    
    # Melt
    meltedData <- reshape2::melt(mergedData, id = "timestamp")
    
    # Re-name datetime label
    #meltedData$timestamp <- as.POSIXlt(meltedData$timestamp, format = "%Y-%m-%dT%H:%M:%S")
    
    # Output
    output$dartPlot <- renderPlotly({
      #plot_ly(daData, x = ~datetime_beginning_ept, y = ~total_lmp_da)
      plot_ly(source="source") %>%
        add_lines(data = meltedData, x = ~timestamp, y = ~value, color = ~variable) %>%
        layout(title = "Day-ahead vs. Real-time LMP Prices")
    })
    
    output$dataTable1 <- DT::renderDataTable({
      dt <- mergedData %>%
        mutate(timestamp = str_replace(timestamp, "T", " ")) %>%
        DT::datatable(options = DT_OPTIONS)
      dt
    })
  })
}
