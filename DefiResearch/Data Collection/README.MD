# Data Collection:
getRawData.rmd has blocks of code to pull AAVEv2 Mainnet data directly from TheGraph (https://thegraph.com/hosted-service/subgraph/aave/protocol-v2?version=current). Each block of code in the file will download and save raw transaction data for one transaction type (e.g. there is a block of code that gets Borrow data, a different block of code to get Deposit data, etc.). In addition to transaction data, the ReserveParamsHistoryItem table is queried to get more relevant information for each transaction that's taken place in AAVEv2 Mainnet. Since this is raw data, any reference to another table just gets the ID variable, and thus we also pull data from Reserves to help expand the raw data later. All data collected by this code is stored in "./Data/raw/".

# Data Cleaning / Processing:
processRawData.rmd takes the raw transaction data created and stored from getRawData.rmd and processes it into a single transactions table, stored simply in "./Data/".
