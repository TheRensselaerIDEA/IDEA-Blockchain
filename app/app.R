#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Set the default CRAN repository
local({r <- getOption("repos")
r["CRAN"] <- "http://cran.r-project.org" 
options(repos=r)
})

# Set code chunk defaults
knitr::opts_chunk$set(echo = TRUE)

# Load required packages; install if necessary
# CAUTION: DO NOT interrupt R as it installs packages!!
if (!require("ggplot2")) {
    install.packages("ggplot2")
    library(ggplot2)
}

if (!require("knitr")) {
    install.packages("knitr")
    library(knitr)
}

if (!require("dplyr")) {
    install.packages("dplyr")
    library(dp)
}

if (!require("RColorBrewer")) {
    install.packages("RColorBrewer")
    library(RColorBrewer)
}
if (!require("beeswarm")) {
    install.packages("beeswarm")
    library(beeswarm)
}
if (!require("tidyverse")) {
    install.packages("tidyverse")
    library(tidyverse)
}
if (!require("ggbeeswarm")) {
    install.packages("ggbeeswarm")
    library(ggbeeswarm)
}
if (!require("xts")) {
    install.packages("xts")
    library(xts)
}
if (!require("plotly")) {
    install.packages("plotly")
    library(plotly)
}
if(!require("lubridate")) {
    install.packages("lubridate")
    library(lubridate)
}
if(!require("survival")) {
    install.packages("survival")
    library(survival)
}
if(!require("survminer")) {
    install.packages('survminer')
    library(survminer)
}
if(!require("ranger")){
    install.packages("ranger")
    library(ranger)
}
if(!require("ggfortify")){
    install.packages("ggfortify")
    library(ggfortify)
}

# Prepare Transaction Data

#load Rds (binary version of csv file) into dataframe
transactions <- read_rds('Data/transactionsv2.rds')

reserveTypes <- transactions %>%
    distinct(reserve) %>%
    select(reserve)

transactionTypes <- transactions %>%
    distinct(type) %>%
    select(type)

minDate <- transactions %>%
    slice_min(timestamp) %>%
    distinct(timestamp) %>%
    select(timestamp) %>%
    transmute(time = as_datetime(timestamp))

maxDate <- transactions %>%
    slice_max(timestamp) %>%
    distinct(timestamp) %>%
    select(timestamp) %>%
    transmute(time = as_datetime(timestamp))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("AAVE Transactions Data Visualizer"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            dateRangeInput("dateRange",
                           "Filter by date range:",
                           start = floor_date(minDate$time, unit = "day"),
                           end = ceiling_date(maxDate$time, unit = "day")),
            radioButtons("bins",
                         "Group By:",
                         choices = c("hour", "day", "week", "month", "quarter"),
                         selected = "week"),
            selectInput("reserve",
                      "Reserve Name:",
                      choices = reserveTypes$reserve,
                      multiple = TRUE),
            #radioButtons("reserveGroups",
             #            "Reserve Grouping:",
              #           choices = c("Separate", "Grouped"),
               #          selected = "Grouped"),
            selectInput("transactionType",
                        "Transaction Type(s):",
                        choices = transactionTypes$type,
                        multiple = TRUE),
            radioButtons("transactionGroups",
                         "Transaction Grouping:",
                         choices = c("Separate", "Grouped"),
                         selected = "Grouped")
            
        ),

        
        mainPanel(
           plotOutput("reservePlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$reservePlot <- renderPlot({
        timeInterval <- interval(input$dateRange[1], input$dateRange[2])
        
        ifelse(length(input$reserve) == 0, filteredReserves <- reserveTypes$reserve, filteredReserves <- input$reserve)
        
        ifelse(length(input$transactionType) == 0, filteredTransactionTypes <- transactionTypes$type, filteredTransactionTypes <- input$transactionType)
        
        filteredTransactions <- transactions %>%
            filter(reserve %in% filteredReserves) %>%
            filter(type %in% filteredTransactionTypes) %>%
            mutate(datetime = as_datetime(timestamp)) %>%
            filter(datetime %within% timeInterval) %>%
            mutate(time = round_date(datetime, unit = input$bins)) %>%
            group_by(reserve,time) %>%
            count(type)
        
        ifelse(length(filteredReserves) > 3, reserveString <- "Selected Reserves ", reserveString <- paste(filteredReserves, collapse=', '))
        ifelse(length(filteredTransactionTypes) > 3, typeString <- "Transactions ", typeString <- str_c(paste(filteredTransactionTypes, collapse='s, '), "s ", sep=''))
        
        title <- str_c("Number of ", typeString, "for ", reserveString, sep='')
        
        plot <- ggplot(filteredTransactions, aes(time, n, fill=reserve)) + geom_col() +
            xlab(str_to_title(input$bins)) +
            ylab(str_c("Number of ", typeString, sep=""))+
            ggtitle(title)
        
        if(input$transactionGroups=="Separate") plot <- plot + facet_wrap(~ filteredTransactions$type)
        plot
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
