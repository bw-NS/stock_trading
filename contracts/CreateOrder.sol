pragma solidity >=0.5.0 <0.7.0;

import "order.sol"

contract CreateOrder{
    function publicCreateOrder(Order.MatchTypes _Mtype, Order.Types _type, string _stockName, uint256 _price, uint256 _volume) external payable returns (bytes32) {
        bytes32 _result = this.createOrder(msg.sender, _type, _attoshares, _displayPrice, _market, _outcome, _betterOrderId, _worseOrderId, _tradeGroupId);
        return _result;
    }

    function createOrder(address _creator, Order.MatchTypes _Mtype, Order.Types _type, string _stockName, uint256 _price, uint256 _volume) external returns (bytes32) {
        Order.Data memory _orderData = Order.create(_creator, _Mtype, _type,_stockName, _price, _volume);
        Order.escrowFunds(_orderData);
        require(_orderData.orders.getAmount(_orderData.getOrderId()) == 0);
        return Order.saveOrder(_orderData, _tradeGroupId);
    }

}