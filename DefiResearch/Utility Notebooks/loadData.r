library(readr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(here)

dataPath = "./Data Collection/Data/"
transactionsFile = "transactions.csv"
reserveInfoFile = "reserveInfo.csv"
reserveParamsHistoryFile = "reserveParamsHistory.csv"

df<-read_csv(paste(dataPath, transactionsFile, sep=""))
reserveInfo <- read_csv(paste(dataPath, reserveInfoFile, sep=""))
reserveParamsHistory <- read_csv(paste(dataPath, reserveParamsHistoryFile, sep=""))

## Helper functions
not_all_na <- function(x) any(!is.na(x))

activeCollateral <- function(usr, ts, collaterals) {
  userCollateral <- collaterals %>%
    filter(user == usr, timestamp <= ts) %>%
    group_by(reserve) %>%
    slice_max(timestamp) %>%
    mutate(enabledForCollateral = toState) %>%
    select(user, enabledForCollateral) %>%
    filter(enabledForCollateral == TRUE)
  return(userCollateral)
}

## Create the basic dataframes for each transaction type:
borrows <- df %>%
  filter(type=="borrow") %>%
  select(where(not_all_na))

repays <- df %>%
  filter(type == "repay") %>%
  select(where(not_all_na))

deposits <- df %>%
  filter(type == "deposit") %>%
  select(where(not_all_na))

redeems <- df %>%
  filter(type == "redeem") %>%
  select(where(not_all_na))

swaps <- df %>%
  filter(type == "swap") %>%
  select(where(not_all_na))

collaterals <- df %>%
  filter(type == "collateral") %>%
  select(where(not_all_na))

liquidations <- df %>%
  filter(type == "liquidation") %>%
  select(where(not_all_na))

## Create some helpful, smaller dataframes that can easily be queried to find some useful info
stableCoins <- reserveInfo %>%
  filter(stable == TRUE) %>%
  select(symbol) %>%
  rename(reserve = symbol)

nonStableCoins <- reserveInfo %>%
  filter(stable == FALSE) %>%
  select(symbol) %>%
  rename(reserve = symbol)

reserveTypes <- reserveInfo %>%
  select(symbol, stable) %>%
  mutate(reserveType = if_else(stable == TRUE, "Stable", "Non-Stable")) %>%
  select(symbol, reserveType) %>%
  drop_na() %>%
  rename(reserve = symbol)

# Compute aggregate liquidations

df2 <- left_join(df, reserveTypes, by="reserve") %>%
  distinct()

numLiqPerUser <- liquidations %>%
  group_by(user) %>%
  dplyr::summarise(numLiquidations = n())


aggregateLiquidations <- df2 %>%
  filter(user %in% numLiqPerUser$user) %>% # First, let's filter out all users who have never been liquidated.
  group_by(user) %>%                       # The next set of logic is to sort users' transactions by timestamp and pull out all liquidations that are
  arrange(timestamp) %>%                   # part of a consecutive set of liquidations.
  mutate(nextTransaction = lead(type)) %>%
  mutate(prevTransaction = lag(type)) %>%
  filter(type == "liquidation" & (nextTransaction == "liquidation" | prevTransaction == "liquidation"))  %>%
  mutate(liquidationDay = floor_date(as_datetime(timestamp), unit = "day")) %>% # Then we want to use some approximation for the timeframe of this liquidation event, so we naively group consecutive liquidations by the day on which they took place.
  group_by(user,liquidationDay) %>% # Doing this means that we can group by user and liquidationDay, which is functionally grouping by "liquidation event"
  mutate(liquidationDuration = max(timestamp) - min(timestamp)) %>% # Now we can compute some basic stats about the event.
  mutate(liquidationStart = min(timestamp), liquidationEnd = max(timestamp)) %>%
  mutate(liquidationStartDatetime = as_datetime(liquidationStart), liquidationEndDatetime = as_datetime(liquidationEnd)) %>%
  mutate(reserve = collateralReserve) %>%
  left_join(reserveTypes, by = "reserve") %>%
  dplyr::rename(collateralType = reserveType.y) %>%
  mutate(reserve = principalReserve) %>%
  left_join(reserveTypes, by = "reserve") %>%
  dplyr::rename(principalType = reserveType) %>%
  mutate(totalCollateralUSD = sum(amountUSDCollateral), totalPrincipalUSD = sum(amountUSDPrincipal))%>%
  dplyr::mutate(numLiquidations = n()) %>%
  dplyr::summarise(userAlias, numLiquidations, liquidationDuration, liquidationStart, liquidationEnd, liquidationStartDatetime, liquidationEndDatetime,
            collateralReserves = str_flatten(str_sort(unique(collateralReserve)), collapse = ","), 
            collateralTypes = str_flatten(str_sort(unique(collateralType)), collapse= ","),
            principalReserves = str_flatten(str_sort(unique(principalReserve)), collapse = ","),
            principalTypes = str_flatten(str_sort(unique(principalType)), collapse = ","),
            totalCollateralUSD, totalPrincipalUSD, liquidationType = str_c(principalTypes, collateralTypes, sep = ":")) %>%
  distinct()

rm(df2)
