pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./order.sol";

//TODO: clean up data structure
// array(for get data) + mapping(exist) + mapping(function)
contract orderBook {
    uint256 constant MAX_STOCK = 99999; //max number of stock that can be stored in this orderbook 
    uint256 constant MAX_ORDER = 99999; //max number of unfilled order ...
    address[] UserList;
    mapping(address => string) Alias; 
    address admin; 
    uint256[][2] id_array;                      //store all the unfilled orderIds 
                                                //split to index 0:buy 1:sell

    mapping(uint256 => Order.Data) private orders; // array of orders storing data 

    mapping(string => uint256) completeData;        //for future use record order have been filled

    string[MAX_STOCK] stockTable;                   //store all the stocks
    uint256 num_stock = 0;                          // stock index tracker 
    mapping(address => uint256[][2]) creatorTable;  //mapping user to orderIDs // for accessing data frontend
    mapping(string => uint256[][2]) stockOrder;     //mapping stock to orderIDs // for accessing data frontend
    mapping(string => uint256[2]) bestOrders;       //tracking the best buy/sell order for each stock

    uint256[] Idvacancy;                            // tracker for assigning orderIds          
    uint256 nextAvl = 0; 
    mapping(address=> uint256) propertyNum;
    mapping(address=>mapping(string=>uint256)) propertyTable;
    mapping(address=>uint256) CashTable;

    constructor() {
        admin = msg.sender;
    }


    function getProperty(address user) public view returns( uint256, string[] memory, uint256[] memory ){
        bool _e;
        uint256 _t; 
        (_e,_t) = checkUserExist(user);
        require(_e, "user Not registered");
        require(num_stock>0, "no stock in market");
        uint256 num = 0;
        for(uint256 i=0; i< num_stock; i++){
            if(propertyTable[user][stockTable[i]]>0){
                num++;
            }
        }    
        string[] memory _s = new string[](num); 
        uint256[] memory _v = new uint256[](num); 
        uint256 index = 0;
        for(uint256 i=0; i< num_stock; i++){
            if(propertyTable[user][stockTable[i]]>0){
                _s[index] = stockTable[i];
                _v[index] = propertyTable[user][stockTable[i]];
                index ++;
            }
        }  
        
        return (num, _s, _v);
    }
    event reg_message(address addr , string Alias);
    function userRegister(string memory ali) public{
        address addr = msg.sender;
        require(addr != admin, "Admin address");
        bool _e;
        uint256 index; 
        (_e, index) = checkUserExist(addr); 
        if(!_e){
            UserList.push(addr);
            CashTable[addr] = addr.balance;  
            Alias[addr] = ali;
            emit reg_message(addr, Alias[addr]);
        }
    }

    function checkUserExist(address addr) internal view returns(bool, uint256){
        for(uint256 i =0 ; i<UserList.length; i++){
            if (addr == UserList[i]){
                return (true, i);
            }
        }
        return (false, MAX_ORDER);
    }

    function removeUser(address addr) public{
        require(msg.sender == admin,"Caller must be admin");
        bool _e;
        uint256 index; 
        (_e, index) = checkUserExist(addr);
        require(_e, "addr not exist");
        //delete propertyTable[addr];
        delete CashTable[addr];
        
        for(uint256 i = 0; i<=1; i++){
            while(creatorTable[addr][i].length>0){
                removeOrder(creatorTable[addr][i][0]);
            }
        }
        UserList[index] = UserList[UserList.length-1];
        UserList.pop();
    }

    function getUsers() public view returns(address[] memory, string[] memory){
        string[] memory Ali = new string[](UserList.length);
        for(uint256 i = 0 ; i<UserList.length; i++){
            Ali[i] = Alias[UserList[i]];
        }
        return (UserList, Ali);
    }
    /*This section for issue and remove stocks*/
    /***
    TO DO: only verified company can issue stocks (whitelist)
    ***/
    function addStocks(string memory _stockName) internal returns(bool){
        bool _exist; 
        uint256 _t;
        require(num_stock<MAX_STOCK, "Too many stocks");
        (_exist, _t) =  checkStockInMarket(_stockName);            
        require(!_exist, "stock already in market");          //check if name repeat
        stockTable[num_stock] = _stockName;
        num_stock++;
        bestOrders[_stockName] = [MAX_ORDER,MAX_ORDER];
        return true;
    } 
    
    //can move to a sub contract
    event StockIssue(string _stockName, uint256 volumn, uint256 price);
    function issueStock(string memory _stockName, uint256 volumn, uint256 price)public returns(bool){
        //require(inWhiteList(msg.sender));
        require( addStocks(_stockName), "Add stock failed");
        propertyTable[msg.sender][_stockName] = volumn;
        propertyNum[msg.sender]+=1; 
        saveOrder(Order.Types.sell, _stockName,volumn, Order.MatchTypes.lmt,  price);
        emit StockIssue(_stockName, volumn, price);
        return true;
    }

    //function reteatStock(string memory )

    //check the best buy/sell order for stock 
    function checkBestOrders(string memory stock) public view returns(uint256, uint256){   
        return (bestOrders[stock][0],bestOrders[stock][1]);
    }
    //for debugging can remove
    function getNumStocks() internal view returns(uint256){
        return num_stock;
    }
    //check if stock exist, can be internal 
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
    //print the stock array
    function getStockArray() public view returns(string[] memory){
        string[] memory a = new string[](num_stock);
        for(uint256 i=0; i<num_stock; i++){
            a[i] = stockTable[i];
        }
        return a;
    }

    /*This section store orderId to user*/

    function userOrders(address _addr) public view returns(uint256[] memory, uint256[] memory){
        return (creatorTable[_addr][0],creatorTable[_addr][1]) ;
    }

    function addOrderToUser(address _addr, Order.Types _typ, uint256 _orderId) internal returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        creatorTable[_addr][_typ_int].push(_orderId);
        return true;
    }
    function findOrderinUser(address _addr, Order.Types _typ, uint256 _orderId) internal view returns(bool, uint){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int <2, "Ask not store");
        for(uint i = 0; i< creatorTable[_addr][_typ_int].length; i++){
            if(creatorTable[_addr][_typ_int][i] == _orderId){
                return (true, i);
            }
        }
        return (false, MAX_ORDER);
    }

    function removeOrderFromUser(address _addr,Order.Types _typ,  uint256 _orderId) internal returns(bool){
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

    /*This section assign orderID to Stock*/

    function addOrderToStock(string memory stockName,Order.Types _typ, uint256 _orderId) internal returns(bool){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        bool _exist;
        uint256 _t;
        (_exist, _t) = checkStockInMarket(stockName);
        require(_exist, "Stock not in market");
        stockOrder[stockName][_typ_int].push(_orderId);
        return true;
    }

    function checkStockHaveOrder(string memory stockName,Order.Types _typ, uint256 _orderId) internal view returns(bool, uint256){
        uint256 _typ_int = uint256(_typ);
        require(_typ_int<2, "Ask not store");
        for(uint256 i =0; i<stockOrder[stockName][_typ_int].length;i++){
            if (stockOrder[stockName][_typ_int][i] == _orderId){
                return (true, i);
            }    
        }
        return (false,MAX_ORDER);
    }

    function removeOrderFromStock(string memory stockName,Order.Types _typ, uint256 _orderId) internal returns(bool){
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
    function getStockOrders(string memory stockName) public view returns(uint256[] memory, uint256[] memory){
        return (stockOrder[stockName][0],stockOrder[stockName][1]);
    }

    
    /*some look up functions*/ 
    function getOrderData(uint256 _orderId) public view returns(Order.Data memory){
        return orders[_orderId];
    }
    
    function getOrderCreator(uint256 _orderId) internal view returns(address){
        return getOrderData(_orderId).creator;
    }
    function getOrderStock(uint256 _orderId) internal view returns(string memory){
        return getOrderData(_orderId).stock;
    }
    function getOrderPrice(uint256 _orderId) internal view returns(uint256){
        return getOrderData(_orderId).price;
    }
    function getOrderVolume(uint256 _orderId) internal view returns(uint256){
        return getOrderData(_orderId).volumn;
    }
    function getOrderMatchType(uint256 _orderId) internal view returns(uint256){
        return uint256(getOrderData(_orderId).matchtype);
    }
    
    //abandoned orderId method should remove
    function getOrderId( address creator,Order.Types typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price, uint createtime) internal view returns(bytes32){
        return sha256(abi.encodePacked(creator, typ, stock, volumn, matchtype, price,createtime));
    }

    //for assigning unique orderId to each new buy/sell order
    function assignOrderId() internal returns (uint256){
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

    //some events print out for logging 
    event savedOrderInfo(uint256 _orderId, string stockName, Order.Types Types,  uint256 price, Order.MatchTypes matchtype);
    event message(string msg);
    event b_w(uint256 better, uint256 worse);

    //orders form a linked list by _order.better _order.worse
    //create order globally
    /*
    function getBalance(address user) public view returns(uint256 , string[] memory, uint256[] memory){
        Property _p= propertyTable[user];
        string[] memory _s;
        uint256[] memory _v; 
        (_s, _v) = _p.printProperty();
        return (CashTable[user], _s, _v);
    
    }
    */
    function ModifyStockBalance(address user,  Order.Types typ, uint256 OrderId) public{
        if(typ == Order.Types.sell){
            require(propertyTable[user][getOrderStock(OrderId)]>= getOrderVolume(OrderId), "Not enough stock to sell");
            propertyTable[user][getOrderStock(OrderId)]-=getOrderVolume(OrderId);
        }
        if(typ == Order.Types.buy){
            require(CashTable[user]>getOrderVolume(OrderId)*getOrderPrice(OrderId), "Not enough stock to buy");
            CashTable[user]-=getOrderVolume(OrderId)*getOrderPrice(OrderId);
        }
    }

    function saveOrder(Order.Types  typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price) public returns(bool){
        //uint256 _orderId  = getOrderId(creator, typ, stock, volumn, matchtype, price, now);
        bool _e; 
        uint256 _i;
        (_e,_i) = checkUserExist( msg.sender);
        require(_e, "User not registered"); 
        uint256 _typ = uint256(typ);
        if (_typ<2){      //save if buy/sell, fill if ask   
            //check condition commented out for debugging convinience
            //if(_typ==0){require(msg.sender.balance>fund, "buyer don't have enough fund"); }
            //if(_typ==1){require(propertyTable[msg.sender][stock]>=volumn, "seller don't have enough stock to sell");} 
            uint256 better;
            uint256 worse;
            (better, worse) = getBetterOrder( stock, typ, price);
            emit b_w(better, worse);
            uint256 _orderId = assignOrderId();
            Order.Data storage _order = orders[_orderId];
            _order.id = _orderId;
            _order.creator = msg.sender;
            _order.typ = typ;
            _order.stock = stock;
            _order.volumn = volumn;
            _order.matchtype = matchtype;
            _order.price = price;
            
            //link list manipulation
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
            addOrderToUser(msg.sender, typ, _orderId);
            addOrderToStock(stock, typ,  _orderId);
            emit savedOrderInfo( _orderId, stock,typ, price, matchtype);
            return true;
        }
        else{
            require(fillAskOrder(stock), "fill ask failed");
            return true;
        }
    }
    
    //helper for remove order from link list
    function breakLink(uint256 _orderId,  uint256 _typ) internal returns(bool){
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
    
    //remove order globally
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
    //TODO: remove ID_array 
    function checkOrderExist(uint256 _orderId) internal view returns(bool, uint256){
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
    //remove helper
    function removeFromIdArray(uint256 _orderId) internal returns(bool){
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
    function getArraylength() internal view returns(uint, uint){
        return (id_array[0].length, id_array[1].length);
    }

    //find the position in linklist of the order
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
    
    event fillOrderInfo(uint256 ordreId, bool complete);
    //not finished 
    /*
    function transfer(address payable seller, address buyer, string memory stock, uint256 price, uint256 volumn) public payable returns(bool){
        uint256 fund = price*volumn;
        require(propertyTable[seller][stock]>volumn, "seller don't have enough stock to sell"); //should check earlier
        require(buyer.balance>fund, "buyer don't have enough fund");
        seller.transfer(fund); // critical how to make buyer send the money?????????
        propertyTable[seller][stock]+=volumn;
        return true;
    }

    //not finished

    function fillOrder() public returns(bool){
        for(uint256 i =0; i< num_stock; i++){
            string memory stockName = stockTable[i];
            uint256 bestbuy = bestOrders[stockName][0];
            uint256 bestsell = bestOrders[stockName][1];
            while(getOrderPrice(bestbuy)>=getOrderPrice(bestsell)){
                if(getOrderVolume(bestbuy)<getOrderVolume(bestsell)){
                    uint256 remaindar = getOrderVolume(bestsell) - getOrderVolume(bestbuy);
                    orders[bestsell].volumn = remaindar;
                    removeOrder(bestbuy);
                    emit fillOrderInfo(bestbuy, true);
                    emit fillOrderInfo(bestsell, false);
                }
                else{
                    if(getOrderVolume(bestbuy)==getOrderVolume(bestsell)){
                    removeOrder(bestbuy);
                    removeOrder(bestsell);
                    emit fillOrderInfo(bestbuy, true);
                    emit fillOrderInfo(bestsell, true);
                    }
                    else{
                        uint256 remaindar = getOrderVolume(bestbuy) - getOrderVolume(bestsell);
                        orders[bestbuy].volumn = remaindar;
                        removeOrder(bestbuy);
                        emit fillOrderInfo(bestbuy, false);
                        emit fillOrderInfo(bestsell, true);
                        
                    }
                    
                }
            bestbuy = bestOrders[stockName][0];
            bestsell = bestOrders[stockName][1];
            }
        
        }

    }
    */
    //fill ask Order
    event askOrderRes(string stock , uint256 p_b,uint256 v_b,uint256 p_s,uint256 v_s  );
    function fillAskOrder(string memory stock) public returns(bool){//, uint256 volumn
        bool _e;
        uint256 _t;
        (_e, _t) = checkStockInMarket(stock);
        require(_e,"stock not in market");
        uint256 bestbuy = bestOrders[stock][0];
        uint256 bestsell = bestOrders[stock][1];
        uint256[4] memory data;
        if(bestbuy == MAX_ORDER){
            data[0] = MAX_ORDER;
            data[1] = MAX_ORDER;
        }
        if(bestsell == MAX_ORDER){
            data[2] = MAX_ORDER;
            data[3] = MAX_ORDER;
        }
        data[1] = getOrderData(bestbuy).volumn;
        data[3] = getOrderData(bestsell).volumn;
        data[0] = getOrderData(bestbuy).price;
        data[2] = getOrderData(bestsell).price;
        emit askOrderRes(stock,data[0],data[1],data[2],data[3] );
        return true;
    }

    //function completeOrder();
    

}