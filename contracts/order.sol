pragma solidity >=0.5.0 <0.7.0;

import "./SponsorWhitelistControl.sol";

library Order {
    enum MatchTypes{
        imme, lmt
    }
    enum Types{
        buy, sell,ask
    }

    struct Data{

        uint256 id;
        address creator;
        Order.Types  typ; //buy sell ask
        string  stock; //  string
        uint256  volumn; //  int
        Order.MatchTypes matchtype; // type include {immediate, limited}
        uint256 price;
        uint256 betterOrder;
        uint256 worseOrder;

    }
    /*function getOrderId(Order.Data _data) internal view returns (bytes32){
        return _data.id;
    }*/
 
    //function submit()
    //function cancel()

   
}