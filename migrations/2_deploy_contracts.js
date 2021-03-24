const order = artifacts.require("order");
const orderBook = artifacts.require("orderBook");

module.exports = function(deployer) {
  deployer.deploy(order);
  deployer.link(order, orderBook);
  deployer.deploy(orderBook);
};
