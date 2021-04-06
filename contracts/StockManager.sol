pragma solidity >=0.5.0 <=0.8.3;
import "./UserManager.sol";
import "./PropertyManager.sol";
import "./OrderManager.sol";
import "./order.sol";

contract StockManager{
    uint256 constant MAX_STOCK = 0xFFFFFFFF;
    string[] stockTable;                   //store all the stocks
    
    function stockExist(string memory proposed) public view returns(bool, uint){
        for(uint i=0; i<stockTable.length; i++){
            if (keccak256(bytes(stockTable[i])) == keccak256(bytes(proposed))){
                return (true, i); 
            }
        }
        return (false,MAX_STOCK);
    }

    function addStocks(OrderManager order_mng, string memory _stockName) internal returns(bool){
        bool _exist; 
        uint256 _t;
        require(stockTable.length<MAX_STOCK, "Too many stocks");
        (_exist, _t) =  stockExist(_stockName);            
        require(!_exist, "stock already in market");         
        stockTable.push(_stockName);
        //TODO: set in ordermng
        order_mng.initBestOrders(_stockName);
        return true;
    } 

    function removeStock(string memory stockName) external{
        bool _exist;
        uint index;
        (_exist, index) = stockExist(stockName);
        if(_exist){
            stockTable[index] = stockTable[stockTable.length];
            delete stockTable[stockTable.length];
        }
    }

    event StockIssue(string _stockName, uint256 volumn, uint256 price);
    function issueStock(OrderManager order_mng, UserManager user_reg, PropertyManager property_mng, address addr, string memory _stockName, uint256 volumn, uint256 price) external{
        //require(inWhiteList(msg.sender));
        require(addStocks(order_mng, _stockName), "Add stock failed");
        require(user_reg.isCompany(addr), "Company only");
        property_mng.addProperty(addr,_stockName,volumn);
        Order.Data memory _order;
        _order.creator = addr;
        _order.typ = Order.Types.sell;
        _order.stock = _stockName;
        _order.volumn = volumn;
        _order.matchtype = Order.MatchTypes.lmt;
        _order.price = price;
        order_mng.saveOrder(property_mng, _order);
        emit StockIssue(_stockName, volumn, price);
    }
    function getStockNum() public view returns(uint256){
        return stockTable.length;
    }

    function getStockArray() public view returns(string[] memory){
        string[] memory a = new string[](stockTable.length);
        for(uint256 i=0; i<stockTable.length; i++){
            a[i] = stockTable[i];
        }
        return a;
    }

    function getStock(uint256 index) external view returns(string memory){
        return stockTable[index];
    }


}