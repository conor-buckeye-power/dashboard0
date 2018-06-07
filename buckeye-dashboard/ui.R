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
frow2 <- fluidRow(
  box(
    title = "Data viewer",
    status = "primary",
    solidHeader = TRUE,
    collapsible = TRUE,
    width = 12
  )
)

body <- dashboardBody(frow1, frow2)

ui <- dashboardPage(title = "Buckeye Power Dashboard", header, sidebar, body)
