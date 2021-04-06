pragma solidity >=0.5.0 <=0.8.3;
import "./OrderManager.sol";
import "./UserManager.sol";
import "./StockManager.sol";
import "./PropertyManager.sol";
import "./order.sol";

contract SmartBull {
    address admin;
    UserManager UserMng;
    PropertyManager PropertyMng;
    OrderManager OrderMng;
    StockManager StockMng;
    
    constructor(){
        admin = msg.sender;
        UserMng = new UserManager();
        PropertyMng =new PropertyManager();
        OrderMng = new OrderManager();
        StockMng = new StockManager();
    }

    function changeAdmin(address new_admin) public{
        require(msg.sender == admin, "Admin Only!");
        admin = new_admin;
    }

    event Register(address addr, string username, bool company);
    function userRegister(string memory username, bool company) public {
        UserMng.userRegister(msg.sender, username, company);
        emit Register(msg.sender, username, company);
    }
    
    function checkUserExist(address addr) public view returns(bool, uint256){
        return UserMng.checkUserExist(addr);
    }

    function removeUser(address addr) public{
        require(msg.sender == admin, "Admin Only!");
        UserMng.removeUser(addr);
    }
    function getUsers() public view returns(address[] memory, UserInfo[] memory){
        return UserMng.getUsers();
    }
    event Deposite(address addr, uint256 balance, uint256 ConfluxBalance);
    function deposite() public payable{
        require(msg.sender.balance>=msg.value, "Insufficient Fund");
        PropertyMng.deposite(msg.sender, msg.value);
        emit Deposite(msg.sender, PropertyMng.getBalance(msg.sender), msg.sender.balance/1 ether);
    }
    event Withdraw(address addr, uint256 balance, uint256 ConfluxBalance);
    function withdraw(uint256 amount) public {
        require(amount <= PropertyMng.getBalance(msg.sender), "not enough balance");
        PropertyMng.withdraw(msg.sender, amount);
        payable(msg.sender).call{value:amount* 1 ether}(""); //{value: amount}("");
        emit Withdraw(msg.sender, PropertyMng.getBalance(msg.sender), msg.sender.balance/1 ether);
    }

    function getBalance(address user) public view returns(uint256){
        return PropertyMng.getBalance(user);
    }

    function getProperty(address user) public view returns( uint256, string[] memory, uint256[] memory ){
        return PropertyMng.getProperty(user, StockMng);
    }

    function stockExist(string memory proposed) public view returns(bool, uint){
        return StockMng.stockExist(proposed);
    }

    function removeStock(string memory stockName) external{
        require(msg.sender == admin, "Admin Only!");
        StockMng.removeStock(stockName);
        //TODO:REMOVE ALL ORDERS
    }
    
    event StockIssue(string stockname, uint256 volumn, uint256 price);
    function issueStock(string memory _stockName, uint256 volumn, uint256 price) public {
        StockMng.issueStock(OrderMng, UserMng, PropertyMng, msg.sender, _stockName, volumn, price);
        emit StockIssue( _stockName,  volumn,  price);
    }
    
    function getStockArray() public view returns(string[] memory){
        return StockMng.getStockArray();
    }

    function checkBestOrders(string memory stock) public view returns(bytes32, bytes32){
        (bool exist, ) = StockMng.stockExist(stock);
        require(exist, "Stock doesn't exist");
        return OrderMng.checkBestOrders(stock);
    }

    function getOrderData(bytes32 _orderId) public view returns(Order.Data memory){
        return OrderMng.getOrderData(_orderId);
    }
    function getOrderId(address creator,Order.Types typ, string memory stock, uint256 volumn,Order.MatchTypes  matchtype, uint256 price) public view returns(bytes32){
        return OrderMng.getOrderId(creator, typ, stock, volumn, matchtype, price);
    }

    event SaveOrder(uint16 orderID, address creator, string stock, uint256 volumn, uint256 price);
    function saveOrder(Order.Types typ, string memory stock, uint256 volumn, Order.MatchTypes matchtype, uint256 price) public {
         Order.Data memory _order;
        _order.creator = msg.sender;
        _order.typ = typ;
        _order.stock = stock;
        _order.volumn = volumn;
        _order.matchtype = matchtype;
        _order.price = price;
        (bool s, uint16 orderID) = OrderMng.saveOrder(PropertyMng, _order);
        emit SaveOrder(orderID, msg.sender, stock, volumn, price);
    }

    function removeOrder(uint _orderId) public returns(bool){
        return OrderMng.removeOrder(bytes32(_orderId));
    }

    function getBetterOrder(string memory stockName, Order.Types typ,  uint256 price) public view returns(uint16, uint16){
        (bytes32 t1, bytes32 t2)=OrderMng.getBetterOrder(stockName, typ, price);
        return (uint16(uint(t1)), uint16(uint(t2)));
    }

    function fillOrder(Order.Data memory order) public returns(bool, uint256){
        return OrderMng.fillOrder(PropertyMng, order);
    }

    function fillAskOrder(string memory stock) public view returns(bool){
        return OrderMng.fillAskOrder(stock);
    }
    event Transfer(address seller, address buyer, string stock, uint256 seller_balance, uint256 buyer_balance);
    function transfer(address seller, address buyer, string memory stock, uint256 price, uint256 volumn) public returns(bool){
        bool r = PropertyMng.transfer(seller, buyer, stock, price, volumn);
        emit Transfer(seller, buyer, stock, PropertyMng.getBalance(seller), PropertyMng.getBalance(buyer));
        return r;
    }
}
