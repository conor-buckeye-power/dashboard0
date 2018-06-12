library(jsonlite)
library(httr)
library(ggvis)
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(reshape2)
library(stringr)

header <- dashboardHeader(title = "Buckeye Power")

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Hourly LMPs: DA/RT", tabName = "hourly-lmp-dart", icon = icon("usd")),
    menuItem("Daily LMPs: DA/RT", tabName = "daily-lmp-dart", icon = icon("usd"))
  )
)


# ==========================================================================================================================================================================
# DA/RT Hourly LMPs Dashboard
# ==========================================================================================================================================================================
frow1 <- fluidRow(
  box(
    title = "Day-ahead vs. Real-time LMPs",
    status = "primary",
    solidHeader = TRUE,
    collapsible = FALSE,
    width = 9,
    plotlyOutput("dartPlot")
  ),
  box(
    title = "Chart options",
    status = "primary",
    solidHeader = TRUE,
    collapsible = TRUE,
    width = 3,
    selectInput("loc",
                "Location",
                choices = c("Cardinal2","Cardinal3","Greenville1","Greenville2","Greenville3","Greenville4","Mone1","Mone2","Mone3"),
                selected = "Cardinal2",
                multiple = TRUE),
    dateInput("start_date",
              "Start date",
              value = as.character(Sys.Date()-7),
              min = "2010-01-01",
              max = Sys.Date()+10),
    dateInput("end_date",
             "End date",
             value = as.character(Sys.Date()+1),
             min = "2010-01-01",
             max = Sys.Date()+10),
    selectInput("mab",
                "Moving average bars",
                choices = c("None","7-Day","14-Day"),
                selected = "None",
                multiple = FALSE),
    actionButton("update",
                 "Update")
    
  )
)
frow2 <- fluidRow(
  box(
    title = "Data viewer",
    status = "primary",
    solidHeader = TRUE,
    collapsible = TRUE,
    width = 12,
    DT::dataTableOutput("dataTable1")
  )
)

# ==========================================================================================================================================================================
# DA/RT Daily LMPs Dashboard
# ==========================================================================================================================================================================

# ...

body <- dashboardBody(tabItems(
  tabItem(tabName="hourly-lmp-dart", frow1, frow2),
  tabItem(tabName="daily-lmp-dart")
))

ui <- dashboardPage(title = "Buckeye Power Dashboard", header, sidebar, body)
