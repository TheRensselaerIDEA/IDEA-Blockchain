#function description
#This function takes in the starting data set to the ending data set
#lets say a survival analysis from borrows to repays would be as follows
#the user who borrowed would have to start by borrowing so the start dataset is
#borrows and then the end data set is repays
#example of how to use
# borrows <- df %>%
#   filter(type=="borrow")
# 
# repays <- df %>%
#   filter(type=="repay")
# 
# generateSurvival(borrows, repays)


#add notebook explaining 

#add package dependencies (include if statements)

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
if (!require("devtools")) {
  install.packages("devtools")
  library(devtools)
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
if(!require("patchwork")){
  install.packages("patchwork")
  library(patchwork)
}

generateSurvival <- function(start, end)
{
  
  dataSet <- left_join(end,start,by="user") %>%
    dplyr::rename(endTime=timestamp.x) %>%
    dplyr::rename(startTime=timestamp.y) %>%
    group_by(user) %>%
    dplyr::summarise(timeDiff=case_when(min(startTime)-min(endTime)>0 ~   min(startTime)-min(endTime), TRUE ~ as.integer(21294796))) %>%
    mutate(status=case_when(timeDiff==as.integer(21294796) ~ 0, timeDiff<=0 ~ 0, timeDiff>0 ~ 1)) %>%
    select(user,timeDiff,status)
  
  km <- with(borrowRepay, Surv(timeDiff/86400, status))
  km_fit <- survfit(Surv(timeDiff/86400, status) ~ 1, data=borrowRepay)
  summary(km_fit, times = c(1,30,60,90*(1:10)))
  p1 <- autoplot(km_fit,xlab="time (days)",ylab="Survival Percent",title="Survival Analysis")
  return (p1)
  
  
}

```{r}
borrows <- df %>%
  filter(type=="borrow")

repays <- df %>%
  filter(type=="repay")

generateSurvival(borrows, repays)
```




