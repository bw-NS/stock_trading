pragma solidity >=0.5.0 <=0.8.3;

import "./order.sol";
import "./PropertyManager.sol";
import "./StockManager.sol";

contract OrderManager{
    uint256 constant MAX_STOCK = 0xFFFFFFFF; //max number of stock that can be stored in this orderbook 
    bytes32 constant MAX_ORDER = "MAX_ORDER"; //max number of unfilled order ...
    //mapping(address => uint256[][2]) creatorTable;  //mapping user to orderIDs // for accessing data frontend
    //mapping(string => uint256[][2]) stockOrder;     //mapping stock to orderIDs // for accessing data frontend
    mapping(string => bytes32[2]) bestOrders;       //tracking the best buy/sell order for each stock
    mapping(bytes32 => Order.Data) private orders;

    uint256[] Idvacancy;                            // tracker for assigning orderIds          
    uint256 nextAvl = 0; 

    event savedOrderInfo(bytes32 _orderId, string stockName, Order.Types Types,  uint256 price, Order.MatchTypes matchtype);
    event message(string msg);
    event b_w(bytes32 better, bytes32 worse);

    function checkBestOrders(string memory stock) public view returns(bytes32, bytes32){   
        return (bestOrders[stock][0],bestOrders[stock][1]);
    }
    function initBestOrders(string memory _stockName) external {
        bestOrders[_stockName] = [MAX_ORDER,MAX_ORDER];
    }

    function getOrderData(bytes32 _orderId) public view returns(Order.Data memory){
        return orders[_orderId];
    }

    function getOrderCreator(bytes32 _orderId) internal view returns(address){
        return getOrderData(_orderId).creator;
    }
    function getOrderStock(bytes32 _orderId) internal view returns(string memory){
        return getOrderData(_orderId).stock;
    }
    function getOrderPrice(bytes32 _orderId) internal view returns(uint256){
        return getOrderData(_orderId).price;
    }
    function getOrderVolume(bytes32 _orderId) internal view returns(uint256){
        return getOrderData(_orderId).volumn;
    }
    function getOrderMatchType(bytes32 _orderId) internal view returns(uint256){
        return uint256(getOrderData(_orderId).matchtype);
    }
    function breakLink(bytes32 _orderId,  uint256 _typ) internal returns(bool){
        Order.Data memory _data= getOrderData(_orderId);
        bytes32 better = _data.betterOrder;
        bytes32 worse = _data.worseOrder;
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

    function getOrderId( address creator,Order.Types typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price) public view returns(bytes32){
        return sha256(abi.encodePacked(creator, typ, stock, volumn, matchtype, price, block.timestamp));
    }

    // function assignOrderId() internal returns (uint256){
    //     if(Idvacancy.length>0){
    //         uint256 id = Idvacancy[Idvacancy.length-1];
    //         Idvacancy.pop();
    //         return id;
    //     }
    //     else{
    //         nextAvl++;
    //         return nextAvl-1;
    //     }
    // }
    event orderfilled(bytes32 orderID, address buyer, address seller, string stock, uint256 price, uint256 volumn);
    function fillOrder(PropertyManager property_mng, Order.Data memory order) public returns(bool, uint256){
        
        address owner = order.creator;
        string memory stock = order.stock;
        Order.Types typ = order.typ;
        Order.MatchTypes matchtype =order.matchtype; 
        uint256 price = order.price; 
        uint256 volumn = order.volumn;
        
        if(matchtype == Order.MatchTypes.imme){
            if(typ == Order.Types.buy){
                bool matchnext = true;
                while(matchnext){
                    bytes32 bestsell = bestOrders[stock][1];
                    if(bestsell == MAX_ORDER) return (false, volumn);
                    uint256 m_v= getOrderVolume(bestsell);
                    uint256 m_price = getOrderPrice(bestsell);
                    address seller = getOrderCreator(bestsell);
                    if(m_v<volumn){
                        volumn -= getOrderVolume(bestsell);
                        property_mng.transfer(seller, owner , stock, m_price, m_v);
                        removeOrder(bestsell);
                        emit orderfilled(bestsell, owner, seller, stock, m_price, m_v);
                    }
                    else{
                        matchnext = false; 
                        if(m_v == volumn){
                            property_mng.transfer(seller, owner , stock, m_price, volumn);
                            removeOrder(bestsell);
                            emit orderfilled(bestsell, owner, seller, stock, m_price, volumn);
                            return (true, 0);
                        }
                        else{
                            property_mng.transfer(seller, owner , stock, m_price, volumn);
                            orders[bestsell].volumn = m_v - volumn; 
                            emit orderfilled(bestsell, owner, seller, stock, m_price, volumn);
                            return (true, 0);
                        }
                    }
                }
                return (false, volumn);
            }
            if(typ == Order.Types.sell){
                bool matchnext = true;
                while(matchnext){
                    bytes32 bestbuy = bestOrders[stock][0];
                    if(bestbuy == MAX_ORDER) return (false, volumn);
                    uint256 m_v= getOrderVolume(bestbuy);
                    uint256 m_price = getOrderPrice(bestbuy);
                    address buyer = getOrderCreator(bestbuy);
                    if(m_v<volumn){
                        volumn -= getOrderVolume(bestbuy);
                        property_mng.transfer(owner, buyer, stock, m_price, m_v);
                        removeOrder(bestbuy);
                        emit orderfilled(bestbuy, buyer, owner, stock, m_price, m_v);
                    }
                    else{
                        matchnext = false; 
                        if(m_v == volumn){
                            property_mng.transfer(owner, buyer , stock, m_price, volumn);
                            removeOrder(bestbuy);
                            emit orderfilled(bestbuy, buyer, owner, stock, m_price, volumn);
                            return (true, 0);
                        }
                        else{
                            property_mng.transfer(owner, buyer , stock, m_price, volumn);
                            orders[bestbuy].volumn = m_v - volumn; 
                            emit orderfilled(bestbuy, buyer, owner, stock, m_price, volumn);
                            return (true, 0);
                        }
                    }
                
                }
                return(false, volumn);
            }
        }
        if(matchtype == Order.MatchTypes.lmt){ // lmt price
            if(typ == Order.Types.buy){
                bool matchnext = true;
                while(matchnext){
                    bytes32 bestsell = bestOrders[stock][1];
                    if(bestsell == MAX_ORDER) return (false, volumn);
                    uint256 m_v = getOrderVolume(bestsell);
                    uint256 m_price = getOrderPrice(bestsell);
                    address seller = getOrderCreator(bestsell);
                    if(m_price > price) return(false, volumn);
                    if(m_v<volumn){
                        volumn -= getOrderVolume(bestsell);
                        property_mng.transfer(seller, owner , stock, m_price, m_v);
                        removeOrder(bestsell);
                        emit orderfilled(bestsell, owner, seller, stock, m_price, m_v);
                    }
                    else{
                        matchnext = false; 
                        if(m_v == volumn ){
                            property_mng.transfer(seller, owner , stock, price, volumn);
                            removeOrder(bestsell);
                            emit orderfilled(bestsell, owner, seller, stock, price, volumn);
                            return (true, 0);
                        }
                        else{
                            property_mng.transfer(seller, owner , stock, price, volumn);
                            orders[bestsell].volumn = m_v - volumn; 
                            emit orderfilled(bestsell, owner, seller, stock, price, volumn);
                            return (true, 0);
                        }
                    }
                }
                return (false, volumn); 
            }
            
            if(typ == Order.Types.sell){
                bool matchnext = true;
                while(matchnext){
                    bytes32 bestbuy = bestOrders[stock][0];
                    if(bestbuy == MAX_ORDER) return (false, volumn);
                    uint256 m_v= getOrderVolume(bestbuy);
                    uint256 m_price = getOrderPrice(bestbuy);
                    address buyer = getOrderCreator(bestbuy);
                    if(m_price < price) return (false, volumn);
                    if(m_v<volumn){
                        volumn -= getOrderVolume(bestbuy);
                        
                        property_mng.transfer(owner, buyer, stock, price, m_v);
                        removeOrder(bestbuy);
                        emit orderfilled(bestbuy, buyer, owner, stock, price, m_v);
                    }
                    else{
                        matchnext = false; 
                        if(m_v == volumn){
                            property_mng.transfer(owner, buyer , stock, price, m_v);
                            removeOrder(bestbuy);
                            emit orderfilled(bestbuy, buyer, owner, stock, price, volumn);
                            return (true, 0);
                        }
                        else{
                            property_mng.transfer(owner, buyer , stock, price, volumn);
                            orders[bestbuy].volumn = m_v - volumn; 
                            emit orderfilled(bestbuy, buyer, owner, stock, price, volumn);
                            return (true, 0);
                        }
                    }
                }
                return (false, volumn);
            }
        }
    }

    //event savedOrderInfo(bytes32 _orderId, string stockName, Order.Types Types, uint256 price, uint256 volumn, Order.MatchTypes matchtype);
    function saveOrder(PropertyManager property_mng, Order.Data memory order_data) public returns(bool,uint16){
        bytes32 _orderId  = getOrderId(order_data.creator, order_data.typ, order_data.stock, order_data.volumn, order_data.matchtype, order_data.price);
        uint256 _typ = uint256(order_data.typ);
        if (_typ<2){      //save if buy/sell, fill if ask   
            bytes32 better;
            bytes32 worse;
            (better, worse) = getBetterOrder(order_data.stock, order_data.typ, order_data.price);
            //emit b_w(better, worse);
            //uint256 _orderId = assignOrderId();
            Order.Data storage _order = orders[_orderId];
            _order.id = _orderId;
            _order.creator = order_data.creator;
            _order.typ = order_data.typ;
            _order.stock = order_data.stock;
            _order.volumn = order_data.volumn;
            _order.matchtype = order_data.matchtype;
            _order.price = order_data.price;
            _order.time = block.timestamp;
            bool _e; 
            uint256 _i;
            (_e , _i) = fillOrder(property_mng, _order);
            if(_e){
                delete orders[_orderId];
                return (true, 0xFFFF);
            }
            _order.volumn = _i;
            //link list manipulation
            if(better==MAX_ORDER ){
                if(bestOrders[_order.stock][_typ] == MAX_ORDER){
                    emit message("initial brunch");
                    bestOrders[_order.stock][_typ] = _orderId;
                    _order.betterOrder=MAX_ORDER;
                    _order.worseOrder=MAX_ORDER;
                }
                else{
                    emit message("insert head");
                    bytes32 cur_best = bestOrders[_order.stock][_typ];
                    bestOrders[_order.stock][_typ] = _orderId;
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

            //addOrderToUser(msg.sender, typ, _orderId);
            //addOrderToStock(stock, typ,  _orderId);
            //emit savedOrderInfo(_orderId, stock, typ, price, _i, matchtype);
            return (true, uint16(uint(_orderId)));
        }
        else{
            require(fillAskOrder(order_data.stock), "fill ask failed");
            return (true, 0xFFFF);
        }
    }

    event removedOrderInfo(bytes32 orderId, address creator, string stockName, Order.Types typ, uint256 price);
    function removeOrder(bytes32 _orderId) public returns(bool){
        Order.Data memory _data= getOrderData(_orderId);
        uint256 _typ = uint256(_data.typ);
        //require(removeOrderFromStock(_data.stock,_data.typ, _orderId), "Order not registered to stock");
        //require(removeOrderFromUser(_data.creator,_data.typ, _orderId), "Order not registered to User");
        require(breakLink(_orderId, _typ),"Link break fail");
        delete orders[_orderId];
        //Idvacancy.push(_orderId);
        emit removedOrderInfo(_orderId, _data.creator, _data.stock, _data.typ, _data.price );
        return true;
    }

    function getBetterOrder(string memory stockName, Order.Types typ,  uint256 price) public view returns(bytes32, bytes32){
        // bool exist;
        // uint256 _t; 
        // (exist,_t) = checkStockInMarket(stockName);
        // require(exist, "stock not exist");
        //first order
        if(bestOrders[stockName][uint256(typ)]==MAX_ORDER){
            return (MAX_ORDER,MAX_ORDER);
        }
        uint256 _type = uint256(typ);        
        bytes32 cur_id = bestOrders[stockName][_type];
        bytes32 prev_id = cur_id;
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



    event askOrderRes(string stock , uint256 p_b,uint256 v_b,uint256 p_s,uint256 v_s  );
    function fillAskOrder( string memory stock) public view returns(bool){//, uint256 volumn
        bytes32 bestbuy = bestOrders[stock][0];
        bytes32 bestsell = bestOrders[stock][1];
        uint256[4] memory data;
        if(bestbuy == MAX_ORDER){
            data[0] = MAX_STOCK;
            data[1] = MAX_STOCK;
        }
        if(bestsell == MAX_ORDER){
            data[2] = MAX_STOCK;
            data[3] = MAX_STOCK;
        }
        data[1] = getOrderData(bestbuy).volumn;
        data[3] = getOrderData(bestsell).volumn;
        data[0] = getOrderData(bestbuy).price;
        data[2] = getOrderData(bestsell).price;
        //emit askOrderRes(stock,data[0],data[1],data[2],data[3] );
        return true;
    }

}