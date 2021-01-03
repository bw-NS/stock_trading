pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./order.sol";

contract orderBook {
    uint256 constant MAX_STOCK = 99999;
    uint256 constant MAX_ORDER = 99999;
    uint256[][2] id_array;
    mapping(uint256 => Order.Data) private orders; // array of orders
    mapping(string => uint256) completeData;
    string[MAX_STOCK] stockTable;
    uint256 num_stock = 0;
    mapping(address => uint256[][2]) creatorTable; //index 0:buy 1:sell
    mapping(string => uint256[][2]) stockOrder;
    mapping(string => uint256[2]) bestOrders;
    //mapping(address => bytes32[2][]) testTable;
    uint256[] Idvacancy;
    uint256 nextAvl = 0; 

    function addStocks(string memory _stockName) public returns(bool){
        bool _exist; 
        uint256 _t;
        (_exist, _t) =  checkStockInMarket(_stockName);
        require(!_exist, "stock already in market");
        stockTable[num_stock] = _stockName;
        num_stock++;
        bestOrders[_stockName] = [MAX_ORDER,MAX_ORDER];
        return true;
    } 
    function checkBestOrders(string memory stock) public view returns(uint256, uint256){
        return (bestOrders[stock][0],bestOrders[stock][1]);
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

    function getStockArray() public view returns(string[] memory){
        string[] memory a = new string[](num_stock);
        for(uint256 i=0; i<num_stock; i++){
            a[i] = stockTable[i];
        }
        return a;
    }

    function userOrderNum(address _addr) public view returns(uint256, uint256){
        return (creatorTable[_addr][0].length,creatorTable[_addr][1].length) ;
    }

    function addOrderToUser(address _addr, Order.Types _typ, uint256 _orderId) public returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int <2, "Ask not store");
        creatorTable[_addr][_typ_int].push(_orderId);
        return true;
    }
    function findOrderinUser(address _addr, Order.Types _typ, uint256 _orderId) public view returns(bool, uint){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int <2, "Ask not store");
        for(uint i = 0; i< creatorTable[_addr][_typ_int].length; i++){
            if(creatorTable[_addr][_typ_int][i] == _orderId){
                return (true, i);
            }
        }
        return (false, MAX_ORDER);
    }

    function removeOrderFromUser(address _addr,Order.Types _typ,  uint256 _orderId) public returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int <2, "Ask not store");
        bool _exist;
        uint index;
        (_exist, index) = findOrderinUser(_addr, _typ, _orderId);
        if(_exist){
            creatorTable[_addr][_typ_int][index] = creatorTable[_addr][_typ_int][creatorTable[_addr][_typ_int].length-1];
            creatorTable[_addr][_typ_int].pop();
            //creatorTable[_addr].length--;
        return true;
        }
    }

    function addOrderToStock(string memory stockName,Order.Types _typ, uint256 _orderId) public returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        bool _exist;
        uint256 _t;
        (_exist, _t) = checkStockInMarket(stockName);
        require(_exist, "Stock not in market");
        stockOrder[stockName][_typ_int].push(_orderId);
        return true;
    }

    function checkStockHaveOrder(string memory stockName,Order.Types _typ, uint256 _orderId) public view returns(bool, uint256){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        for(uint256 i =0; i<stockOrder[stockName][_typ_int].length;i++){
            if (stockOrder[stockName][_typ_int][i] == _orderId){
                return (true, i);
            }    
        }
        return (false,MAX_ORDER);
    }

    function removeOrderFromStock(string memory stockName,Order.Types _typ, uint256 _orderId) public returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        bool _exist;
        uint256 index;
        (_exist, index) = checkStockHaveOrder(stockName, _typ,_orderId);
        if(_exist){
            stockOrder[stockName][_typ_int][index] = stockOrder[stockName][_typ_int][stockOrder[stockName][_typ_int].length-1];
            stockOrder[stockName][_typ_int].pop();
            return true;
        }
        return false;
    }
    function getStockOrderNum(string memory stockName) public view returns(uint256, uint256){
        return (stockOrder[stockName][0].length,stockOrder[stockName][1].length);
    }
    // some look up functions
    function getOrderData(uint256 _orderId) public view returns( Order.Data memory){
        return orders[_orderId];
    }
    function getOrderId( address creator,Order.Types typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price, uint createtime) public view returns(bytes32){
        return sha256(abi.encodePacked(creator, typ, stock, volumn, matchtype, price,createtime));
    }

    function assignOrderId() public returns (uint256){
        if(Idvacancy.length>0){
            uint256 id = Idvacancy[Idvacancy.length-1];
            Idvacancy.pop();
            return id;
        }
        else{
            nextAvl++;
            return nextAvl-1;
        }
    }
    event savedOrderInfo(uint256 _orderId, string stockName, uint256 price);
    //function insertOrderToList(Order.Data _order){}
    event message(string msg);
    event b_w(uint256 better, uint256 worse);
    function saveOrder(address creator,Order.Types  typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price) public returns(bool){
        //uint256 _orderId  = getOrderId(creator, typ, stock, volumn, matchtype, price, now);
        uint256 _typ = uint256(typ);
        if (_typ<2){          
            uint256 better;
            uint256 worse;
            (better, worse) = getBetterOrder( stock, typ, price);
            emit b_w(better, worse);
            uint256 _orderId = assignOrderId();
            Order.Data storage _order = orders[_orderId];
            _order.id = _orderId;
            _order.creator = creator;
            _order.typ = typ;
            _order.stock = stock;
            _order.volumn = volumn;
            _order.matchtype = matchtype;
            _order.price = price;
            
            if(better==MAX_ORDER ){
                if(bestOrders[stock][_typ] == MAX_ORDER){
                    emit message("initial brunch");
                    bestOrders[stock][_typ] = _orderId;
                    _order.betterOrder=MAX_ORDER;
                    _order.worseOrder=MAX_ORDER;
                }
                else{
                    emit message("insert head");
                    uint256 cur_best = bestOrders[stock][_typ];
                    bestOrders[stock][_typ] = _orderId;
                    _order.betterOrder=MAX_ORDER;
                    _order.worseOrder=cur_best;
                    orders[cur_best].betterOrder=_orderId;
                }
            }
            else{
                _order.betterOrder = better;
                _order.worseOrder = worse;
                if(worse!=MAX_ORDER){
                    emit message("insert middle");
                    orders[better].worseOrder = _orderId;
                    orders[worse].betterOrder = _orderId;
                }
                else{
                    emit message("insert tail");
                    orders[better].worseOrder = _orderId;
                }
            }

            id_array[_typ].push(_orderId);
            addOrderToUser(creator, typ, _orderId);
            addOrderToStock(stock, typ,  _orderId);
            emit savedOrderInfo( _orderId, stock, price);
            return true;
        }
        else{
            require(fillAskOrder(), "fill ask failed");
            return true;
        }
    }

    function breakLink(uint256 _orderId,  uint256 _typ) public returns(bool){
        Order.Data memory _data= getOrderData(_orderId);
        uint256 better = _data.betterOrder;
        uint256 worse = _data.worseOrder;
        require(_typ < 2, "_typ out of bound");
        emit b_w(better, worse);
        if(better == MAX_ORDER){
            emit message("delete best");
            require(bestOrders[_data.stock][_typ] == _orderId, "Order has no better but is not best in book!");
            bestOrders[_data.stock][_typ] = worse;
            if(worse != MAX_ORDER){
                orders[worse].betterOrder = MAX_ORDER;
            }
        }
        else{
            emit message("delete middle");
            orders[better].worseOrder = worse;
            if(worse != MAX_ORDER){
                orders[worse].betterOrder =better;
            }
        }
        return true;
    }

    event removedOrderInfo(uint256 orderId, address creator, string stockName, Order.Types typ, uint256 price);
    
    function removeOrder(uint256 _orderId) public returns(bool){
        require(removeFromIdArray(_orderId), "Order not exist");
        Order.Data memory _data= getOrderData(_orderId);
        uint256 _typ = uint256(_data.typ);
        require(removeOrderFromStock(_data.stock,_data.typ, _orderId), "Order not registered to stock");
        require(removeOrderFromUser(_data.creator,_data.typ, _orderId), "Order not registered to User");
        require(breakLink(_orderId, _typ),"Link break fail");
        delete orders[_orderId];
        Idvacancy.push(_orderId);
        emit removedOrderInfo(_orderId, _data.creator, _data.stock, _data.typ, _data.price );
        return true;
    }

    function checkOrderExist(uint256 _orderId) public view returns(bool, uint256){
        Order.Data memory _data = getOrderData(_orderId);
        uint256 _typ = uint256(_data.typ);
        require(_typ != 2, "ask order is not stored");
        for(uint256 i=0; i<id_array[_typ].length;i++){
            if (id_array[_typ][i]==_orderId){
                return (true, i );
            }
        }
        return (false, MAX_ORDER);
    }
    function removeFromIdArray(uint256 _orderId) public returns(bool){
        bool _exist;
        uint256 index;
        Order.Data memory _data = getOrderData(_orderId);
        uint256 _typ = uint256(_data.typ);
        require(_typ != 2, "ask order is not stored");
        (_exist, index) = checkOrderExist(_orderId);
        if(_exist){
            id_array[_typ][index] = id_array[_typ][id_array[_typ].length-1];
            id_array[_typ].pop();
            return true;
        }
        return false;
    }
    function getArraylength() public view returns(uint, uint){
        return (id_array[0].length, id_array[1].length);
    }

    function getBetterOrder(string memory stockName, Order.Types typ,  uint256 price) public view returns(uint256, uint256){

        bool exist;
        uint256 _t; 
        (exist,_t) = checkStockInMarket(stockName);
        require(exist, "stock not exist");
        //first order
        if(bestOrders[stockName][uint256(typ)]==MAX_ORDER){
            return (MAX_ORDER,MAX_ORDER);
        }

        uint256 _type = uint256(typ);
                                       //greater is better for buy; less is better for sell
        
        uint256 cur_id = bestOrders[stockName][_type];
        uint256 prev_id = cur_id;
        Order.Data memory _data = getOrderData(cur_id);
        if(_type ==0){
            while(price<=_data.price){
                prev_id = cur_id;
                cur_id = _data.worseOrder;
                if( cur_id==MAX_ORDER){
                    return (prev_id, cur_id);
                }
                _data = getOrderData(cur_id);
            }
            if(prev_id == cur_id){
                return (MAX_ORDER, cur_id);
            }
            return (prev_id, cur_id);
        }
        else{
            while(price>=_data.price){
                    prev_id = cur_id;
                    cur_id = _data.worseOrder;
                    if( cur_id==MAX_ORDER){
                        return (prev_id, cur_id);
                    }
                    _data = getOrderData(cur_id);
                }
                if(prev_id == cur_id){
                    return (MAX_ORDER, cur_id);
                }
                return (prev_id, cur_id);
        }
    }


    function fillOrder() public returns(bool){
        

    }
    function fillAskOrder() public returns(bool){
    
    }

    //function completeOrder();
    

}