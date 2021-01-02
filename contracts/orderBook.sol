pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./order.sol";

contract orderBook {
    uint256 constant MAX_STOCK = 99999;
    uint256 constant MAX_ORDER = 99999;
    bytes32[] id_array;
    mapping(bytes32 => Order.Data) private orders; // array of orders
    mapping(string => uint256) completeData;
    
    string[MAX_STOCK] stockTable;
    uint256 num_stock = 0;

    mapping(address => bytes32[]) creatorTable;

    mapping(string => bytes32[]) stockOrder;

    function addStocks(string memory _stockName) public returns(bool){
        stockTable[num_stock] = _stockName;
        num_stock++;
        return true;
    } 
    function getNumStocks() public view returns(uint256){
        return num_stock;
    }
    function checkStockInMarket(string memory proposed) public view returns(bool, uint){
        for(uint i=0; i<num_stock; i++){
            if (keccak256(bytes(stockTable[i])) == keccak256(bytes(proposed))){
                return (true, i); 
            }
        }
        return (false,MAX_STOCK);
    }
    function removeStock(string memory stockName) public returns(bool){
        bool _exist;
        uint index;
        (_exist, index) = checkStockInMarket(stockName);
        if(_exist){
            stockTable[index] = stockTable[num_stock];
            delete stockTable[num_stock];
            num_stock--;
            return true;
        }
        return false;
    }

    function userOrderNum(address _addr) public view returns(uint256){
        return creatorTable[_addr].length;
    }

    function addOrderToUser(address _addr, bytes32 _orderId) public returns(bool){
        creatorTable[_addr].push(_orderId);
        return true;
    }
    function findOrderinUser(address _addr, bytes32 _orderId) public view returns(bool, uint){
        for(uint i = 0; i< creatorTable[_addr].length; i++){
            if(creatorTable[_addr][i] == _orderId){
                return (true, i);
            }
        }
        return (false, MAX_ORDER);
    }

    function removeOrderFromUser(address _addr, bytes32 _orderId) public returns(bool){
        bool _exist;
        uint index;
        (_exist, index) = findOrderinUser(_addr, _orderId);
        if(_exist){
            creatorTable[_addr][index] = creatorTable[_addr][creatorTable[_addr].length-1];
            creatorTable[_addr].pop();
            //creatorTable[_addr].length--;
        return true;
        }
    }

    function addOrderToStock(string memory stockName, bytes32 _orderId) public returns(bool){
        bool _exist;
        uint256 _t;
        (_exist, _t) = checkStockInMarket(stockName);
        require(_exist, "Stock not in market");
        stockOrder[stockName].push(_orderId);
        return true;
    }

    function checkStockHaveOrder(string memory stockName, bytes32 _orderId) public view returns(bool, uint256){
        for(uint256 i =0; i<stockOrder[stockName].length;i++){
            if (stockOrder[stockName][i] == _orderId){
                return (true, i);
            }    
        }
        return (false,MAX_ORDER);
    }

    function removeOrderFromStock(string memory stockName, bytes32 _orderId) public returns(bool){
        bool _exist;
        uint256 index;
        (_exist, index) = checkStockHaveOrder(stockName, _orderId);
        if(_exist){
            stockOrder[stockName][index] = stockOrder[stockName][stockOrder[stockName].length-1];
            stockOrder[stockName].pop();
            return true;
        }
        return false;
    }
    function getStockOrderNum(string memory stockName) public view returns(uint256){
        return stockOrder[stockName].length;
    }
    // some look up functions
    function getOrderData(bytes32 _orderId) public view returns( Order.Data memory){
        return orders[_orderId];
    }
    function getOrderId( address creator,Order.Types typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price, uint createtime) public returns(bytes32){
        return sha256(abi.encodePacked(creator, typ, stock, volumn, matchtype, price,createtime));
    }
    event savedOrderId(bytes32 _orderId);
    //function insertOrderToList(Order.Data _order){}
    function saveOrder(address creator,Order.Types  typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price) public returns(bytes32){
        bytes32 _orderId  = getOrderId(creator, typ, stock, volumn, matchtype, price, now);
        Order.Data storage _order = orders[_orderId];
        _order.id = _orderId;
        _order.creator = creator;
        _order.typ = typ;
        _order.stock = stock;
        _order.volumn = volumn;
        _order.matchtype = matchtype;
        _order.price = price;
        id_array.push(_orderId);
        emit savedOrderId( _orderId);
        addOrderToUser(creator, _orderId);
        addOrderToStock(stock, _orderId );
    }
    function removeOrder(bytes32 _orderId) public returns(bool){
        require(removeFromIdArray(_orderId), "Order not exist");
        Order.Data memory _data= getOrderData(_orderId);
        require(removeOrderFromStock(_data.stock,_orderId), "Order not registered to stock");
        require(removeOrderFromUser(_data.creator,_orderId), "Order not registered to User");
        delete orders[_orderId];
        return true;
    }

    function checkOrderExist(bytes32 _orderId) public view returns(bool, uint256){
        for(uint256 i=0; i<id_array.length;i++){
            if (id_array[i]==_orderId){
                return (true, i );
            }
        }
        return (false, MAX_ORDER);
    }
    function removeFromIdArray(bytes32 _orderId) public returns(bool){
        bool _exist;
        uint256 index;
        (_exist, index) = checkOrderExist(_orderId);
        if(_exist){
            id_array[index] = id_array[id_array.length-1];
            id_array.pop();
            return true;
        }
        return false;
    }
    function getArraylength() public view returns(uint){
        return id_array.length;
    }

    function fillOrder() public returns(bool){
        

    }


    //function completeOrder();
    

}