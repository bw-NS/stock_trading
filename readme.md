# Guide v0.0.1
---
## List of Content
* Function
    * issueStock
    * removeStock
    * addOrderToUser
    * removeOrderfromUser
    * addOrderToStock
    * removeOrderFromStock
    * removeOrder
* View
    * checkBestOrder
    * getNumStocks
    * checkStockInMarket
    * getStockArray
* Event
    * StockIssue
---
## Function
**issueStock**
*Add a Stock to the Market*   
Input:
* _stockName: *the code of the stock*
* volumn: *the amount to be issued*
* price: *unit price*

**removeStock**
*Remove a Stock from the Market*   
Input:
* _stockName: *the name of the stock*

**addOrderToUser**
*Create a User Order*   
Input:
* _addr: *user address*
* _typ: *type of the order*
    * *0: buy*
    * *1: sell*
    * *2: ask*
* _orderId_: *id of the order*

**RemoveOrderFromUser**
*Delete a User Order*   
Input:
* _addr: *user address*
* _typ: *type of the order*
    * *0: buy*
    * *1: sell*
    * *2: ask*
* _orderId_: *id of the order*

**addOrderToStock**
*Create a Stock Order*   
Input:
* stockName: *the code of the stock*
* _typ: *type of the order*
    * *0: buy*
    * *1: sell*
    * *2: ask*
* _orderId_: *id of the order*

**removeOrderFromStock**
*Delete a Stock Order*   
Input:
* stockName: *the code of the stock*
* _typ: *type of the order*
    * *0: buy*
    * *1: sell*
    * *2: ask*
* _orderId_: *id of the order*

**removeOrder**
*Delete an Order*   
Input:
* _orderId_: *id of the order*

---
## View
**checkBestOrder**
*get the best order of a stock*
input:
* stock: *the code of stock*

Output:
* price in the best order
* order id

**getNumStocks**
*get total amount of stocks in the market*
Output:
* total amount

**checkStockInMarket**
*check whether a sotck exists in the market*
Output:
* result
    * true
    * false
* stock id

**getStockArray**
*get all codes of the stocks in the market*
Output:
* list of stock codes

---
##Event
**StockIssue**
*Trigger when a new stock has been issued*
Output:
* info of issued stocks
