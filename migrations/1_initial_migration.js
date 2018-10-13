var Migrations = artifacts.require("./Migrations.sol");
var Property = artifacts.require("./Property.sol");
var PropertyToken = artifacts.require("./PropertyToken.sol");
var PropertyRegistry = artifacts.require("./PropertyRegistry.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(PropertyToken, "PropertyToken", "PPP").then(function(){
    return deployer.deploy(Property, "Property", "PPT").then(function(){
      return deployer.deploy(PropertyRegistry, Property.address, PropertyToken.address);
    })
  })
};
