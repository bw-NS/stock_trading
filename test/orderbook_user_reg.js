const orderBook = artifacts.require("orderBook");

contract('orderBook', (accounts) => {
  it('should register User1', async () => {
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister("User1", {from: accounts[1]});
    const exist = await orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist[0].valueOf(), true, "User1 register not successful!");
  });
  it('should register User1 and Remove it', async () => {
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister("User1", {from: accounts[1]});
    var exist = await orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist[0].valueOf(), true, "User1 register not successful!");
    await orderBookInstance.removeUser(accounts[1], {from: accounts[0]});
    exist = await orderBookInstance.checkUserExist.call(accounts[1]);
    console.log(exist);
    assert.equal(exist[0].valueOf(), false, "User1 removal not successful!");
  });
  it('should get all users', async()=>{
    const orderBookInstance = await orderBook.deployed();
    var dummy = await orderBookInstance.userRegister("User1", {from: accounts[1]});
    var exist = await orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist[0].valueOf(), true, "User1 register not successful!");

    dummy = await orderBookInstance.userRegister("User2", {from: accounts[2]});
    exist = await orderBookInstance.checkUserExist.call(accounts[2]);
    assert.equal(exist[0].valueOf(), true, "User2 register not successful!");

    dummy = await orderBookInstance.userRegister("User3", {from: accounts[3]});
    exist = await orderBookInstance.checkUserExist.call(accounts[3]);
    assert.equal(exist[0].valueOf(), true, "User3 register not successful!");

    const list = {"0": [accounts[1],accounts[2],accounts[3]], "1": ["User1","User2", "User3"]};
    const Users = await orderBookInstance.getUsers.call();
    console.log(Users);
    assert.deepEqual(Users.valueOf(), list, "getUsers failed");
  });

});
