library(ggvis)
library(shiny)
library(shinydashboard)

header <- dashboardHeader(title = "Buckeye Power")

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("LMPs: DA/RT", tabName = "lmp-dart", icon = icon("usd"))
  )
)

frow1 <- fluidRow(
  box(
    title = "Day-ahead vs. Real-time LMPs",
    status = "primary",
    solidHeader = TRUE,
    collapsible = FALSE,
    width = 9
  ),
  box(
    title = "Chart options",
    status = "primary",
    solidHeader = FALSE,
    collapsible = TRUE,
    width = 3
  )
)

body <- dashboardBody(frow1)

ui <- dashboardPage(title = "Buckeye Power Dashboard", header, sidebar, body)
