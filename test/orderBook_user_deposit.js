const orderBook = artifacts.require("orderBook");
const web3 = require("web3");
contract('orderBook', (accounts) => {
  it('should deposite 10 CFX to book', async () => {
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister("User1", {from: accounts[1]});
    const exist = await orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist[0].valueOf(), true, "User1 register not successful!");
    await orderBookInstance.deposite({
        from: accounts[1],
        value: web3.utils.toWei("10", "ether"),
    });
    const balance = await orderBookInstance.getBalance.call(accounts[1]);
    console.log(balance);
    assert.equal(balance.valueOf(), 10, "User deposite fail!");
  });
  it('should withdraw 8CFX', async () => {
    const orderBookInstance = await orderBook.deployed();
    var balance = await orderBookInstance.getBalance.call(accounts[1]);
    console.log(balance);
    assert.equal(balance.valueOf(), 10, "User deposite fail!");
    await orderBookInstance.withdraw(8,{from: accounts[1]});
    balance = await orderBookInstance.getBalance.call(accounts[1]);
    console.log(balance);
    assert.equal(balance.valueOf(), 2, "User withdraw fail!");

  });
//   it('should get all users', async()=>{
//     const orderBookInstance = await orderBook.deployed();
//     var dummy = await orderBookInstance.userRegister("User1", {from: accounts[1]});
//     var exist = await orderBookInstance.checkUserExist.call(accounts[1]);
//     assert.equal(exist[0].valueOf(), true, "User1 register not successful!");

//     dummy = await orderBookInstance.userRegister("User2", {from: accounts[2]});
//     exist = await orderBookInstance.checkUserExist.call(accounts[2]);
//     assert.equal(exist[0].valueOf(), true, "User2 register not successful!");

//     dummy = await orderBookInstance.userRegister("User3", {from: accounts[3]});
//     exist = await orderBookInstance.checkUserExist.call(accounts[3]);
//     assert.equal(exist[0].valueOf(), true, "User3 register not successful!");

//     const list = {"0": [accounts[1],accounts[2],accounts[3]], "1": ["User1","User2", "User3"]};
//     const Users = await orderBookInstance.getUsers.call();
//     console.log(Users);
//     assert.deepEqual(Users.valueOf(), list, "getUsers failed");
//   });

});
