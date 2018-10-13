const Property = artifacts.require("./Property.sol");
const PropertyToken = artifacts.require("./PropertyToken.sol");
const PropertyRegistry = artifacts.require("./PropertyRegistry.sol")

contract('PropertyRegistry', async() => {

  let alice = web3.eth.accounts[1];
  let bob = web3.eth.accounts[2];
  let eve = web3.eth.accounts[3];
  let allocation = 1000;
  let price = 100;

  before(async() => {
    property = await Property.new("Property", "PPT");
    propertyToken = await PropertyToken.new("PropertyToken", "PPP");
    property_registry = await PropertyRegistry.new(property.address, propertyToken.address);
  })

  describe('Register', async() => {
    it ("should create new property, Owner", async() => {
      await property.createProperty({from: alice});
      tokenId = await property.tokenOfOwnerByIndex(alice, 0);
      assert.equal(tokenId, 1, 'property token is invalid')
    });

    it ("should register property, Owner", async() => {
      await property_registry.registerProperty(tokenId, 100, {from: alice});
      const data = await property_registry.stayData(tokenId);
      assert.equal(data[0], 100, "property was not registered");
    });

    it ("should NOT register property, Guest", async() => {
      try {
        await property_registry.registerProperty(tokenId, 100, {from: web3.eth.accounts[2]});
        assert(false, 'guest registered prop')
      }catch(e){
        assert(true)
      }
    });

    it('should allow Contract Owner to mint Property Token', async () => {
      const tx = await propertyToken.mint(bob, allocation);
      //get the balance of property tokens for bob
      const balance = await propertyToken.balanceOf.call(bob);
      assert(balance.toNumber() === allocation, 'balance is invalid');
    });

    it('should allow bob to approve the property registry to use his tokens', async () => {
      const tx = await propertyToken.approve(property_registry.address, price, { from: bob });
      assert(tx !== undefined, 'property registry has not been approved for token transfers');
    });

    it ("should allow to submit reservation request", async()=> {
      let unixDateStart = (new Date(2018,9,1,0,0,0,0)).getTime() / 1000; //Oct 1, 2018
      let unixDateEnd = (new Date(2018,9,20,0,0,0,0)).getTime() / 1000; //Oct 20, 2018

      //reserve
      await property_registry.request(tokenId, unixDateStart, unixDateEnd, {from: bob});
      let guestAddress = await property_registry.getArrayItem(0, tokenId, 0);
      assert.equal(guestAddress, bob, "is not reserved");
    });

    it ("should NOT allow to check in before Approval", async()=> {
      try {
        await property_registry.checkIn(tokenId, {from: bob });
        assert(false, "bob was able to check in")
      } catch(e){
        assert(true)
      }
    });

    it ("should approve request", async()=> {
      //approve request
      await property_registry.approveRequest(tokenId, bob, {from: alice});
      let approvedAddress = await property_registry.getArrayItem(1, tokenId, 0);
      assert.equal(approvedAddress, bob, "successfully approved");
    });

    it ("should NOT allow to check in an unauthorized guest", async()=> {
      try {
        await property_registry.checkIn(tokenId, {from: eve });
        assert(false, "eve was able to check in")
      } catch(e){
        assert(true)
      }
    });

    it ("should allow to check in", async()=> {
      //bob to check in
      await property_registry.checkIn(tokenId, {from: bob });
      let occupantAddress = await property_registry.getArrayItem(2, tokenId, 0);
      assert.equal(occupantAddress, bob, "could not checked in");
    });

    it ("should NOT allow double check in", async()=> {
      try {
        await property_registry.checkIn(tokenId, {from: bob });
        assert.equal(false, "checked in second time");
      }
      catch(e){
        assert(true);
      }
    });

    it ("should allow to check out", async()=> {
      //bob to check out
      await property_registry.checkOut(tokenId, {from: bob });
      occupantAddress = await property_registry.getArrayItem(2, tokenId, 0);
      approvedAddress = await property_registry.getArrayItem(1, tokenId, 0);

      assert.equal(occupantAddress, 0x0, "checked out failed"); //occuant is 0x0
      assert.equal(approvedAddress, 0x0, "checked out failed"); //approved is 0x0
    });

    it ("should allow another reservation request", async()=> {
      let unixDateStart = (new Date(2018,9,4,0,0,0,0)).getTime() / 1000; //Oct 1, 2018
      let unixDateEnd = (new Date(2018,9,15,0,0,0,0)).getTime() / 1000; //Oct 20, 2018

      await property_registry.request(tokenId, unixDateStart, unixDateEnd, {from: eve});
      guestAddress = await property_registry.getArrayItem(0, tokenId, 0);
      assert.equal(guestAddress, eve, "could not reserve");
    })

  });
});
