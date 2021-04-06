pragma solidity >=0.5.0;

library Order {
    enum MatchTypes{
        imme, lmt
    }
    enum Types{
        buy, sell, ask
    }
    struct Data{

        bytes32 id;
        address creator;
        Order.Types  typ; //buy sell ask
        string  stock; //  string
        uint256  volumn; //  int
        Order.MatchTypes matchtype; // type include {immediate, limited}
        uint256 price;
        bytes32 betterOrder;
        bytes32 worseOrder;
        uint time;
    }
    struct Property{
        string stock;
        uint256 volumn;
    }
   
}