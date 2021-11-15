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
if(!require("dygraphs")){
    install.packages("dygraphs")
    library(dygraphs)
}

# Prepare Transaction Data

#load Rds (binary version of csv file) into dataframe
transactions <- read_rds('Data/transactionsv2.rds')

transactions <- transactions %>%
    mutate(datetime = as_datetime(timestamp)) %>%
    mutate(amountETH = amount*reservePriceETH)

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
    tabsetPanel(
        
        tabPanel("Transactions",
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
                                 choices = c("day", "week", "month", "quarter"),
                                 selected = "week",
                                 inline=TRUE),
                    selectInput("reserve",
                              "Reserve Name:",
                              choices = reserveTypes$reserve,
                              multiple = TRUE),
                    radioButtons("reserveGroups",
                                 "Reserve Grouping:",
                                 choices = c("Separate", "Grouped"),
                                 selected = "Grouped",
                                 inline = TRUE),
                    selectInput("transactionType",
                                "Transaction Type(s):",
                                choices = transactionTypes$type,
                                multiple = TRUE),
                    radioButtons("transactionGroups",
                                 "Transaction Grouping:",
                                 choices = c("Separate", "Grouped"),
                                 selected = "Grouped",
                                 inline = "TRUE"),
                    radioButtons("scaleBy",
                                 "Scale By: ",
                                 choices = c("Transaction Count", "Cumulative Transaction Value (USD)", "Cumulative Transaction Value (ETH)"),
                                 selected = "Transaction Count")
                    
                ),
        
                
                mainPanel(
                   plotOutput("reservePlot")
                )
            ) # end of sidebarLayout
        ), # end of tabPanel
        tabPanel("New Tab",
                 # Add your tab here
                 )
    ) # end of tabsetPanel
) # end of fluid_page

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$reservePlot <- renderPlot({
        # Set up the x-axis bounds based on the time range and time intervals
        # selected by the user, and filter the transactions by these dates.
        timeInterval <- interval(input$dateRange[1], input$dateRange[2])
        dateFilteredTransactions <- transactions %>%
            filter(datetime %within% timeInterval) %>%
            mutate(roundedTime = round_date(datetime, unit=input$bins))
        
        # Filter the transactions by the selected reserve types. If no reserve types are selected, 
        # select all reserves.
        ifelse(length(input$reserve) == 0, filteredReserves <- reserveTypes$reserve, filteredReserves <- input$reserve)
        reserveFilteredTransactions <- dateFilteredTransactions %>%
            filter(reserve %in% filteredReserves)
        
        # Filter the transactions by the selected transaction types. If no types
        # are selected, select all transaction types.
        ifelse(length(input$transactionType) == 0, filteredTransactionTypes <- transactionTypes$type, filteredTransactionTypes <- input$transactionType)
        typeFilteredTransactions <- reserveFilteredTransactions %>%
            filter(type %in% filteredTransactionTypes)
        
        
        # Setup the yScale column according to the chosen scale, and set up the
        # proper prefix for the y-axis label
        if(input$scaleBy == "Transaction Count"){
            filteredTransactions <- typeFilteredTransactions %>%
                group_by(reserve, roundedTime) %>%
                count(type) %>%
                mutate(yScale = n)
            yLabPrefix <- "Number of "
        }else if(input$scaleBy == "Cumulative Transaction Value (USD)"){
            filteredTransactions <- typeFilteredTransactions %>%
                group_by(reserve, roundedTime) %>%
                mutate(yScale = cumsum(amountUSD))
            yLabPrefix <- "USD Value of "
        }else if(input$scaleBy == "Cumulative Transaction Value (ETH)"){
            filteredTransactions <- typeFilteredTransactions %>%
                group_by(reserve, roundedTime) %>%
                mutate(yScale = cumsum(amountETH))
            yLabPrefix <- "ETH Value of "
        }
        
        
        ifelse(length(filteredReserves) > 3, reserveString <- "Selected Reserves ", reserveString <- paste(filteredReserves, collapse=', '))
        ifelse(length(filteredTransactionTypes) > 3, typeString <- "Transactions ", typeString <- str_c(paste(filteredTransactionTypes, collapse='s, '), "s ", sep=''))
        ifelse(input$reserveGroups=="Separate", plotAES <- aes(filteredTransactions$roundedTime, filteredTransactions$yScale, fill=filteredTransactions$reserve),
               plotAES <- aes(filteredTransactions$roundedTime, filteredTransactions$yScale))
        title <- str_c(yLabPrefix, typeString, "for ", reserveString, sep='')
        
        plot <- ggplot(filteredTransactions, plotAES) + geom_col() +
            xlab(str_to_title(input$bins)) +
            ylab(str_c(yLabPrefix, typeString, sep=""))+
            ggtitle(title)
        
        if(input$transactionGroups=="Separate") plot <- plot + facet_wrap(~ filteredTransactions$type)
        plot + theme_gray()
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
