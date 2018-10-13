pragma solidity ^0.4.24;

//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract Property is ERC721Token { //Ownable
  using SafeMath for uint256;

  //address public owner;
  constructor(string _name, string _symbol) ERC721Token(_name, _symbol) public{
  }

  modifier onlyOwner(uint _tokenId){
    require(msg.sender == tokenOwner[_tokenId]);
    _;
  }

  function createProperty() public {
    _mint(msg.sender, allTokens.length + 1);
  }

  function setURI(uint256 _tokenId, string _uri) external onlyOwner(_tokenId){
    _setTokenURI(_tokenId, _uri);
  }

  function getURI(uint256 _tokenId) external view returns(string){
    return tokenURIs[_tokenId];
  }

  function getProperties() external view returns(uint256[]){
    return ownedTokens[msg.sender];
  }

  function getAllProperties() external view returns(uint256[]){
    return allTokens;
  }

  function withdrawEther(uint256 _tokenId) onlyOwner(_tokenId) external {
    msg.sender.transfer(address(this).balance);//transfer all eth to owner
  }
}
