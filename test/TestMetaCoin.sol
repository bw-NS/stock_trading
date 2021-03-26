pragma solidity >=0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/orderBook.sol";

contract TestOrderBook {

  // function testInitialBalanceUsingDeployedContract() public {
  //   MetaCoin meta = MetaCoin(DeployedAddresses.MetaCoin());

  //   uint expected = 10000;

  //   Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  // }

  // function testInitialBalanceWithNewMetaCoin() public {
  //   MetaCoin meta = new MetaCoin();

  //   uint expected = 10000;

  //   Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  // }

}
