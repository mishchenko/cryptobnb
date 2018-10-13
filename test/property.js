const Property = artifacts.require("./Property.sol");
//const PropertyRegistry = artifacts.require("./PropertyRegistry.sol")

contract('Property', async()=> {
  let alice = web3.eth.accounts[1];

  describe('Deploy', async() => {
      it ('should be deployed, Property', async() => {
          const instance = await Property.deployed();
          assert(instance !== undefined, 'Property was NOT deployed');
      })
    })

  before(async() => {
    property = await Property.new("PropertyToken", "PPT");
    await property.createProperty({from: alice});
  })

  describe("Create Property", async() => {
    it ("should create new property", async() => {
      tokenId = await property.tokenOfOwnerByIndex(alice, 0);
      assert.equal(tokenId, 1, 'tokenId created')

      let tokenOwner = await property.ownerOf(tokenId);
      assert.deepEqual(tokenOwner, alice, "invalid owner of the new token");
    })

    it ("should set URI, Owner", async() => {
      await property.setURI(tokenId, "google.com", {from: alice});
      var uri = await property.getURI(tokenId);
      assert.equal(uri, "google.com", "uri is not set");
    })

    it ("should NOT set URI, Guest", async() => {
      try {
        await property.setURI(tokenId, "google.com/fail");
        assert(false, 'guest was able to set uri')
      }catch(e){
        assert(true, 'owner can set URI')
      }
    })

  })
})
