library(jsonlite)
library(httr)
library(ggvis)
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(reshape2)
library(stringr)
library(pracma)
library(dplyr)

server <- function(input, output, session){
  
  # ==========================================================================================================================================================================
  # DA/RT Hourly LMPs Dashboard
  # ==========================================================================================================================================================================
  # datatable options
  DT_OPTIONS <- list(pageLength = 24,
                     lengthMenu = c(24, 48, 72),
                     searching = TRUE)
  
  hdrs <- c("Content-Type" = "application/x-www-form-urlencoded",
            "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")
  
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
  
  convertID2 <- c("Cardinal2"="TIDD_AEP",
                  "Cardinal3"="TIDD_AEP",
                  "Greenville1"="09GRNVIL",
                  "Greenville2"="09GRNVIL",
                  "Greenville3"="09GRNVIL",
                  "Greenville4"="09GRNVIL",
                  "Mone1"="RPMONE",
                  "Mone2"="RPMONE",
                  "Mone3"="RPMONE")
  
  # ===== INITIAL DATA PULL AND RENDER =====
  # Call day-ahead API --- date format: 2018-06-05T00:00:00
  dateMinusSevenFormatted <- paste0(as.character(Sys.Date()-3), "T00:00:00")
  daReq <- paste0("https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",dateMinusSevenFormatted,"&pnode_id=40243873")
  daResp <- GET(daReq,
           add_headers(.headers = hdrs))
  daText <- content(daResp, "text")
  daData <- fromJSON(daText, flatten = TRUE)

  # Call real-time API
  rtReq <- paste0("https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",dateMinusSevenFormatted,"&pnode_id=40243873")
  rtResp <- GET(rtReq,
               add_headers(.headers = hdrs))
  rtText <- content(rtResp, "text")
  rtData <- fromJSON(rtText, flatten = TRUE)

  # Merge data sets
  mergedData <- data.frame(timestamp = daData$datetime_beginning_ept,
                           plant = "CD2",
                           dayahead = daData$total_lmp_da,
                           realtime = rtData$total_lmp_rt)

  # Melt
  meltedData <- reshape2::melt(mergedData, id = c("timestamp", "plant"))

  # Re-name datetime label
  #meltedData$timestamp <- as.POSIXlt(meltedData$timestamp, format = "%Y-%m-%dT%H:%M:%S")

  # Output
  output$dartPlot <- renderPlotly({
    plot_ly(source="source") %>%
      add_lines(data = meltedData, x = ~timestamp, y = ~value, color = ~variable) %>%
      add_markers(data = meltedData, x = ~timestamp, y = ~value, color = ~variable, symbol = ~plant) %>%
      layout(title = "Day-ahead vs. Real-time LMP Prices")
  })

  output$dataTable1 <- DT::renderDataTable({
    dt <- mergedData %>%
      mutate(timestamp = str_replace(timestamp, "T", " ")) %>%
      DT::datatable(options = DT_OPTIONS)
    dt
  })
  
  # ===== ON CLICK UPDATE BUTTON =====
  # Call day-ahead API (loop over every day until end date [rbind together])
  observeEvent(input$update, {
    date0Formatted <- paste0(as.character(input$start_date), "T00:00:00")
    date_vec <- c(as.Date(input$start_date):as.Date(input$end_date))
    plant_vec <- input$loc
    iter <- 1
    iters <- length(plant_vec) * length(date_vec) * 2
    
    withProgress(message = "Pulling data from PJM", value = 0, {
      
      for(plant in plant_vec){
        for(date in date_vec){
          
          incProgress(1/iters, detail = paste(plant, as.character(as.Date(date, origin="1970-01-01")), sep = " "))
          
          date0Formatted <- paste0(as.character(as.Date(date, origin="1970-01-01")), "T00:00:00")
          daReq <- paste0("https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",date0Formatted,"&pnode_id=",convertID[[plant]])
          daResp <- GET(daReq,
                        add_headers(.headers = hdrs))
          daText <- content(daResp, "text")
          if(iter==1){
            daData <- fromJSON(daText, flatten = TRUE)
          }else{
            daData <- rbind(daData, fromJSON(daText, flatten = TRUE))
          }
          iter <- iter + 1
        }
      }
      
      # Call real-time API (loop over every day until end date [rbind together])
      iter <- 1
      for(plant in plant_vec){
        for(date in date_vec){
          
          incProgress(1/iters, detail = paste(plant, as.character(as.Date(date, origin="1970-01-01")), sep = " "))
          
          date0Formatted <- paste0(as.character(as.Date(date, origin="1970-01-01")), "T00:00:00")
          rtReq <- paste0("https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",date0Formatted,"&pnode_id=",convertID[[plant]])
          rtResp <- GET(rtReq,
                        add_headers(.headers = hdrs))
          rtText <- content(rtResp, "text")
          if(iter==1){
            rtData <- fromJSON(rtText, flatten = TRUE) 
          }else{
            rtData <- rbind(rtData, fromJSON(rtText, flatten = TRUE))
          }
          iter <- iter + 1
        }
      }
      
    })
    
    # Merge data sets
    mergedData <- data.frame(timestamp = daData$datetime_beginning_ept,
                             plant = daData$pnode_name,
                             dayahead = daData$total_lmp_da,
                             realtime = rtData$total_lmp_rt)
    
    # Melt
    meltedData <- reshape2::melt(mergedData, id = c("timestamp", "plant"))
    
    # Re-name datetime label
    #meltedData$timestamp <- as.POSIXlt(meltedData$timestamp, format = "%Y-%m-%dT%H:%M:%S")
    
    # Calculate moving average FOR EACH PLANT FOR DA vs RT
    movavgs <- data.frame(timestamp = c(1), plant = c(1), dart = c(1), value = c(1))
    
    sma_convert <- c("7-Period"=7,
                     "10-Period"=10,
                     "14-Period"=14)
    
    if(input$mab != "None"){
    
      movavg_interval = sma_convert[[input$mab]]
      
      for(p in plant_vec){
        for(type in c("dayahead","realtime")){
          meltedData$plant <- as.character(meltedData$plant)
          meltedData$variable <- as.character(meltedData$variable)
          
          temp <- meltedData %>%
            dplyr::filter(plant == convertID2[[p]]) %>%
            dplyr::filter(variable == type)
          
          avgs <- pracma::movavg(temp$value, movavg_interval, type = "s")
          movavgs <- rbind(movavgs, data.frame(timestamp = temp$timestamp, plant = p, dart = type, value = avgs))
         }
      }
      movavgs <- movavgs[c(2:nrow(movavgs)), ] # Remove dummy row
    
      # Output
      output$dartPlot <- renderPlotly({
        plot_ly(source="source") %>%
          add_lines(data = meltedData, x = ~timestamp, y = ~value, color = ~variable) %>%
          add_markers(data = meltedData, x = ~timestamp, y = ~value, color = ~variable, symbol = ~plant) %>%
          add_lines(data = movavgs, x = ~timestamp, y = ~value, color = ~dart, line = list(dash="dot")) %>%
          layout(title = "Day-ahead vs. Real-time LMPs")
      })
    }else{
      output$dartPlot <- renderPlotly({
        plot_ly(source="source") %>%
          add_lines(data = meltedData, x = ~timestamp, y = ~value, color = ~variable) %>%
          add_markers(data = meltedData, x = ~timestamp, y = ~value, color = ~variable, symbol = ~plant) %>%
          layout(title = "Day-ahead vs. Real-time LMPs")
      })
    }
    
    output$dataTable1 <- DT::renderDataTable({
      dt <- mergedData %>%
        mutate(timestamp = str_replace(timestamp, "T", " ")) %>%
        DT::datatable(options = DT_OPTIONS)
      dt
    })
  })
  
  
  
  # ==========================================================================================================================================================================
  # DA/RT Daily LMPs Dashboard
  # ==========================================================================================================================================================================
  
  
}
