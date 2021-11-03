# Feature Explanations

## Deposits
*User deposits currency in to a lending pool to accure interest*

- **type**: type of transaction ("redeem" for redeems)

- **user**: id of user who initiated the transaction 

- **onBehalfOf**: id of user who will redeem the tokens *in most cases, user = onBehalfOf*

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool from which currency is redeemed

- **reserve**: symbol of currency used in transaction

- **reservePriceETH**: price of currency at time of transaction, in Ether

- **reservePriceUSD**: price of currency at time of transaction, in USD

- **amount**: number of currency tokens redeemed

- **amountUSD**: amount being borrowed, in USD *reservePriceUSD X amount*


## Redeems
*User removes deposit from lending pool*

- **type**: type of transaction ("redeem" for redeems)

- **user**: id of user who initiated the transaction 

- **onBehalfOf**: id of user who will redeem the tokens *in most cases, user = onBehalfOf*

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool from which currency is redeemed

- **reserve**: symbol of currency used in transaction

- **reservePriceETH**: price of currency at time of transaction, in Ether

- **reservePriceUSD**: price of currency at time of transaction, in USD

- **amount**: number of currency tokens redeemed

- **amountUSD**: amount being borrowed, in USD *reservePriceUSD X amount*

## Borrows
*User borrows a currency from a lending pool, which can be repaid at any time (if the user has the required collateral)*

- **type**: type of transaction ("borrow" for borrows)

- **user**: id of user who initiated the transaction 

- **onBehalfOf**: id of user who will incur the debt *in most cases, user = onBehalfOf*

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool from which currency is borrowed

- **reserve**: symbol of currency used in transaction

- **reservePriceETH**: price of currency at time of transaction, in Ether

- **reservePriceUSD**: price of currency at time of transaction, in USD

- **amount**: number of currency tokens borrowed

- **amountUSD**: amount being borrowed, in USD *reservePriceUSD X amount*

- **borrowRate**: interest rate of loan (APR)

- **borrowRateMode**: whether the loan has a variable or stable interest rate

## Repays
*User repays money borrowed to a lending pool*

- **type**: type of transaction ("borrow" for borrows)

- **user**: id of user who initiated the transaction

- **onBehalfOf**: id of user whose borrow will be repaid *in most cases, user = onBehalfOf*

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool for which currency is being repaid

- **reserve**: symbol of currency used in transaction

- **reservePriceETH**: price of currency at time of transaction, in Ether

- **reservePriceUSD**: price of currency at time of transaction, in USD

- **amount**: number of currency tokens repaid

- **amountUSD**: amount being repaid, in USD *reservePriceUSD X amount*

## Liquidations
*User's loan is forcibly repaid when they no longer have the required collateral to maintain the loan*

- **type**: type of transaction ("liquidation" for liquidations)

- **user**: id of user who received liquidation

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool from which loan is being liquidated

- **collateralReserve**: symbol of currency used as collateral in loan (what is being repaid)

- **principalReserve**: symbol of currency which has been borrowed

- **reservePriceETHCollateral**: price of collateral currency at time of transaction, in Ether

- **reservePriceUSDCollateral**: price of collateral currency at time of transaction, in USD

- **reservePriceETHPrincipal**: price of principal currencyat time of transaction, in Ether

- **reservePriceUSDPrincipal**: price of principal currency at time of transaction, in USD

- **collateralAmount**: number of currency tokens repaid

- **principalAmount**: number of currency tokens borrowed for loan

- **amountUSDPrincipal**: amount of principal being borrowed, in USD *reservePriceUSDPrincipal X principalAmount*

- **amountUSDCollateral**: amount being of collateral being repaid, in USD *reservePriceUSDCollateral X collateralAmount*

## Swaps
*User changes deposit from one type of interest rate to another*

- **type**: type of transaction ("swap" for swaps)

- **user**: id of user who initiated the transaction

- **timestamp**: Unix Timestamp of transaction

- **pool**: id of lending pool from which borrowed currency is being swapped

- **reserve**: symbol of currency used in transaction

- **borrowRateModeFrom**: interest rade mode swapping from 

- **borrowRateModeTo**: interest rate mode swapping to

- **stableBorrowRate**: the stabe interest rate for the deposit

- **variableBorrowRate**: the variable floating rate for the deposit

