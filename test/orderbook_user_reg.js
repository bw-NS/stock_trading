const orderBook = artifacts.require("orderBook");

contract('orderBook', (accounts) => {
  it('should register User1', async () => {
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister.call("User1", {from: accounts[1]});
    const [exist, index] = checkUserExist(accounts[1]);
    assert.equal(exist.valueOf(), true, "User1 register not successful!");
  });
  it('should register User1 and Remove it', async () => {
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister.call("User1", {from: accounts[1]});
    const [exist, index] = orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist.valueOf(), true, "User1 register not successful!");
    await orderBookInstance.removeUser.call(accounts[1])
    const [exist, index] = orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist.valueOf(), false, "User1 removal not successful!");
  });
  it('should get all users', async()=>{
    const orderBookInstance = await orderBook.deployed();
    const dummy = await orderBookInstance.userRegister.call("User1", {from: accounts[1]});
    const [exist, index] = orderBookInstance.checkUserExist.call(accounts[1]);
    assert.equal(exist.valueOf(), true, "User1 register not successful!");

    const dummy = await orderBookInstance.userRegister.call("User2", {from: accounts[2]});
    const [exist, index] = orderBookInstance.checkUserExist.call(accounts[2]);
    assert.equal(exist.valueOf(), true, "User2 register not successful!");

    const dummy = await orderBookInstance.userRegister.call("User3", {from: accounts[3]});
    const [exist, index] = orderBookInstance.checkUserExist.call(accounts[3]);
    assert.equal(exist.valueOf(), true, "User3 register not successful!");

    const list = [[accounts[1],accounts[2],accounts[3]], ["User1","User2", "User3"]];
    const Users = await orderBookInstance.getUsers.call();
    assert.deepEqual(Users.valueOf(), list, "getUsers failed");
  });

});
