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
    library(dplyr)
}
if (!require("RColorBrewer")) {
    install.packages("RColorBrewer")
    library(RColorBrewer)
}
if (!require("beeswarm")) {
    install.packages("beeswarm")
    library(beeswarm)
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
if (!require("tidyverse")) {
    install.packages("tidyverse")
    library(tidyverse)
}

# Prepare Transaction Data

#load Rds (binary version of csv file) into dataframe
transactions <- read_rds('Data/transactionsv2.rds')

transactions <- transactions %>%
    mutate(datetime = as_datetime(timestamp)) %>%
    mutate(amountETH = amount*reservePriceETH)
transactions$date <- as.Date(as.POSIXct(transactions$datetime, origin = "1970-01-01"))

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

# load interest rates data in dataframe
rates <- read_csv('Data/rates.csv')

# create column in rates with date
rates <- rates[order(rates$timestamp),]
rates$date <- as.Date(as.POSIXct(rates$timestamp, origin = "1970-01-01"))

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
                     plotlyOutput("reservePlot")
                 )
             ) # end of sidebarLayout
        ), # end of tabPanel
        tabPanel("Coins",
             tabPanel("Transactions",
                  # Application title
                  titlePanel("Coin Analysis"),
                  
                  # Sidebar with a slider input for number of bins 
                  sidebarLayout(
                      sidebarPanel(
                          selectInput("coin",
                                      "Reserve Name:",
                                      choices = reserveTypes$reserve,
                                      multiple = FALSE),
                          dateRangeInput("coinDateRange",
                                         "Filter by date range:",
                                         start = floor_date(minDate$time, unit = "day"),
                                         end = ceiling_date(maxDate$time, unit = "day"))
                      ),
                      mainPanel(
                          dygraphOutput("ratesPlot"),
                          tableOutput("ratesTable"),
                          dygraphOutput("borrowRepayPlot"),
                          dygraphOutput("depositRedeemPlot")
                      )
                  ) # end of sidebarLayout
             )
        ),
        tabPanel("New Tab",
                 # Add your tab here
        )
    ) # end of tabsetPanel
) # end of fluid_page

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$reservePlot <- renderPlotly({
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
                mutate(yScale = cumsum(amountUSD)/1e6)
            yLabPrefix <- "USD Value (in millions) of "
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
        ggplotly(plot)
        
        
    })
    
    output$ratesPlot <- renderDygraph({
        # subset rates dataframe into median stable and borrow rates for chosen coin by day
        coin_rates <- rates %>%
            filter(reserve == as.character(input$coin)) %>%
            select(date, stableBorrowRate, variableBorrowRate) %>%
            group_by(date) %>%
            summarize(stable = median(stableBorrowRate), 
                   variable = median(variableBorrowRate))
        
        # create time series class for dygraphs
        xts <- xts(x = cbind(coin_rates$stable, coin_rates$variable),
                   order.by = coin_rates$date)
        
        date_range <- c(input$coinDateRange[1], input$coinDateRange[2])
        
        # create dygraph for stable and variable borrow rates
        dygraph(xts, main = paste(input$coin, "Stable vs. Variable APR", sep = " ")) %>%
            dySeries("V1", label = "Stable") %>%
            dySeries("V2", label = "Variable") %>%
            dyOptions(labelsUTC = TRUE, fillGraph = TRUE, fillAlpha = 0.1, drawGrid = FALSE,
                      colors = "#D8AE5A") %>%
            dyRangeSelector(dateWindow = date_range) %>%
            dyCrosshair(direction = "vertical") %>%
            dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2,
                        hideOnMouseOut = FALSE)  %>%
            dyRoller(rollPeriod = 1) %>%
            # add % to axis label
            dyAxis("y", valueFormatter = "function(v){return v.toFixed(1) + '%'}",
                   axisLabelFormatter = "function(v){return v + '%'}")
    })
    
    output$ratesTable <- renderTable({
        # get coin borrow rate data between date ranges
        coin_rates <- rates %>%
            filter(reserve == as.character(input$coin) &
                   date >= input$coinDateRange[1] &
                   date <= input$coinDateRange[2]) %>%
            select(date, stableBorrowRate, variableBorrowRate)
        
        # create output dataframe with summary data
        coin_borrow_stats <- 
            data.frame(mean_stable = mean(coin_rates$stableBorrowRate), 
                       median_stable = median(coin_rates$stableBorrowRate), 
                       high_stable = max(coin_rates$stableBorrowRate), 
                       low_stable = min(coin_rates$stableBorrowRate),
                       mean_variable = mean(coin_rates$variableBorrowRate), 
                       median_variable = median(coin_rates$variableBorrowRate), 
                       high_variable = max(coin_rates$variableBorrowRate), 
                       low_variable = min(coin_rates$variableBorrowRate))
        
        # rename column names
        coin_borrow_stats <- coin_borrow_stats %>%
            rename("Mean Stable Rate" = mean_stable,
                   "Median Stable Rate" = median_stable,
                   "High Stable Rate" = high_stable,
                   "Low Stable Rate" = low_stable,
                   "Mean Variable Rate" = mean_variable,
                   "Median Variable Rate" = median_variable,
                   "High Variable Rate" = high_variable,
                   "Low Variable Rate" = low_variable)
        
        coin_borrow_stats
    })
    
    output$borrowRepayPlot <- renderDygraph({
        br_df <- transactions %>%
            filter(reserve == as.character(input$coin)) %>%
            group_by(date) %>%
            summarize(borrowed = sum(amountUSD[type == "borrow"]),
                      repayed = sum(amountUSD[type == "repay"]))
        
        # create time series class for dygraphs
        br_xts <- xts(x = cbind(br_df$borrowed, br_df$repayed), order.by = br_df$date)
        
        date_range <- c(input$coinDateRange[1], input$coinDateRange[2])
        
        # create dygraph for stable and variable borrow rates
        dygraph(br_xts, main = paste(input$coin, "(in USD) Borrowed vs. Repayed", sep = " ")) %>%
            dySeries("V1", label = "Borrowed") %>%
            dySeries("V2", label = "Repayed") %>%
            dyOptions(labelsUTC = TRUE, fillGraph = TRUE, fillAlpha = 0.1, drawGrid = FALSE,
                      colors = "#D8AE5A") %>%
            dyRangeSelector(dateWindow = date_range) %>%
            dyCrosshair(direction = "vertical") %>%
            dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2,
                        hideOnMouseOut = FALSE)  %>%
            dyRoller(rollPeriod = 1)
    })
    
    output$depositRedeemPlot <- renderDygraph({
        br_df <- transactions %>%
            filter(reserve == as.character(input$coin)) %>%
            group_by(date) %>%
            summarize(deposited = sum(amountUSD[type == "deposit"]),
                      redeemed = sum(amountUSD[type == "redeem"]))
        
        # create time series class for dygraphs
        br_xts <- xts(x = cbind(br_df$deposited, br_df$redeemed), order.by = br_df$date)
        
        date_range <- c(input$coinDateRange[1], input$coinDateRange[2])
        
        # create dygraph for stable and variable borrow rates
        dygraph(br_xts, main = paste(input$coin, "(in USD) Deposited vs. Redeemed", sep = " ")) %>%
            dySeries("V1", label = "Deposited") %>%
            dySeries("V2", label = "Redeemd") %>%
            dyOptions(labelsUTC = TRUE, fillGraph = TRUE, fillAlpha = 0.1, drawGrid = FALSE,
                      colors = "#D8AE5A") %>%
            dyRangeSelector(dateWindow = date_range) %>%
            dyCrosshair(direction = "vertical") %>%
            dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2,
                        hideOnMouseOut = FALSE)  %>%
            dyRoller(rollPeriod = 1)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
