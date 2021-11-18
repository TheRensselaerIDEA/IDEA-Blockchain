# To use the function(s) in this file, write `source("survfunc.R")` at the top of your file

if (!require(dplyr)) {
  install.packages("dplyr")
  library("dplyr")
}
if (!require(readr)) {
  install.packages("readr")
  library("readr")
}
if (!require(ggplot2)) {
  install.packages("ggplot2")
  library("ggplot2")
}
if (!require(survival)) {
  install.packages("survival")
  library("survival")
}
if (!require(survminer)) {
  install.packages("survminer")
  library("survminer")
}

# General function for generating a survival dataset that you can then plot
# 'from' and 'to' variables should be dataframes that contain, at minimum, timestamp columns, and a foreign key column that acts as the 'by' for the left_join.

survivalDataset <- function(from,to,groupBy) {
  data <- left_join(from,to,by=groupBy) %>%
    dplyr::mutate(fromTime=timestamp.x) %>%
    dplyr::mutate(toTime=timestamp.y) %>%
    dplyr::group_by(groupBy) %>%
    dplyr::summarise(timeDiff=case_when(min(fromTime)-min(toTime)>0 ~ abs((min(fromTime)-min(toTime))/86400),
                                        TRUE ~ as.double(max(from$timestamp)/86400))) %>%
    dplyr::mutate(status=case_when(timeDiff==max(from$timestamp)/86400 ~ 0,
                                   TRUE ~ 1))
  return(data)
}

survivalPlot <- function(data,conf.int=FALSE,xlim=c(0,max(data$timeDiff)),ylim=c(0,1),break.time.by=100) {
  km <- with(data,Surv(timeDiff,status))
  km_fit <- survfit(Surv(timeDiff,status) ~ 1, data=data)
  plot <- ggsurvplot(km_fit,conf.int=conf.int,xlim=xlim,ylim=ylim,break.time.by=break.time.by)
  return(plot)
}

df <- read_rds("Data/transactionsv2.rds")

borrows <- df %>%
  dplyr::filter(type=="borrow") %>%
  dplyr::select(onBehalfOf,timestamp) %>%
  dplyr::rename(user=onBehalfOf)

liquidations <- df %>%
  dplyr::filter(type=="liquidation") %>%
  dplyr::select(user,timestamp)

surv <- survivalDataset(borrows,liquidations,"user")
