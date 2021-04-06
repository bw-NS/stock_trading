pragma solidity >=0.5.0 <=0.8.3;
import "./OrderManager.sol";
import "./StockManager.sol";
contract PropertyManager{
    uint256 constant MAX_STOCK = 0xFFFFFFFF; //max number of stock that can be stored in this orderbook 
    uint256 constant MAX_ORDER = 0xFFFFFFFF; //max number of unfilled order ...
    uint256 constant PRICE_PER_TOKEN =1 ether;
    
    mapping(address=> uint256) propertyNum;
    mapping(address=>mapping(string=>uint256)) propertyTable;
    mapping(address=>uint256) CashTable;
    
    event Deposite(address addr, uint256 value, uint256 balance);
    function deposite(address addr, uint256 value) public  {
        //require(msg.value == numTokens * PRICE_PER_TOKEN);
        CashTable[addr] += value/PRICE_PER_TOKEN;
        emit Deposite(addr, value, CashTable[addr]); 
    }
    
    event Withdraw(uint256 value, uint256 balance);
    function withdraw(address addr, uint256 amount) external {
        CashTable[addr] -= amount;
        amount = amount*PRICE_PER_TOKEN;
        emit Withdraw(amount, CashTable[addr]);
    }
    
    function getBalance(address user) public view returns(uint256){
        return CashTable[user];
    }

    function getProperty(address user, StockManager stock_mng) public view returns( uint256, string[] memory, uint256[] memory ){
        uint256 num_stock = stock_mng.getStockNum();
        uint256 num = 0;
        for(uint256 i=0; i< num_stock; i++){
            if(propertyTable[user][stock_mng.getStock(i)]>0){
                num++;
            }
        }    
        string[] memory _s = new string[](num); 
        uint256[] memory _v = new uint256[](num); 
        uint256 index = 0;
        for(uint256 i=0; i< num_stock; i++){
            if(propertyTable[user][stock_mng.getStock(i)]>0){
                _s[index] = stock_mng.getStock(i);
                _v[index] = propertyTable[user][stock_mng.getStock(i)];
                index ++;
            }
        }  
        
        return (num, _s, _v);
    }

    function addProperty(address addr, string memory stock_name,uint256 volumn) external {
        propertyTable[addr][stock_name] = volumn;
        propertyNum[addr]+=1; 
    }

    function transfer(address seller, address buyer, string memory stock, uint256 price, uint256 volumn) external returns(bool){
        uint256 fund = price*volumn;
        if(propertyTable[seller][stock]<volumn) return false; //should check earlier
        if(CashTable[buyer]<fund) return false;
        CashTable[buyer]-=fund;
        CashTable[seller]+=fund;
        propertyTable[seller][stock]-=volumn;
        propertyTable[buyer][stock]+=volumn;
        return true;
    }


}