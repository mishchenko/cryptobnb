pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract PropertyRegistry {
  ERC721Basic public property;
  ERC20 public propertyToken;

  mapping(uint256 => Data) public stayData;

  struct Request {
    uint256 checkIn;
    uint256 checkOut;
  }

  struct Data{
    uint256 price;
    uint256 stays;
    address[] occupants;
    address[] approved;
    address[] requested;
    mapping(address => Request) requests;
  }

  enum GuestType {REQUESTED, APPROVED, OCCUPIED}

  event Registered(uint256 indexed _tokenId);
  event Approved(uint256 indexed _tokenId);
  event Requested(uint256 indexed _tokenId);
  event CheckedIn(uint256 indexed _tokenId);
  event CheckedOut(uint256 indexed _tokenId);

  modifier onlyOwner(uint256 _tokenId){
    require(msg.sender == property.ownerOf(_tokenId));
    _;
  }

  constructor(address _property, address _propertyToken) public {
    property = ERC721Basic(_property);
    propertyToken = ERC20(_propertyToken);
  }

    function registerProperty(uint256 _tokenId, uint256 _price) public onlyOwner(_tokenId){
    stayData[_tokenId] = Data(_price, 0, new address[](0),  new address[](0),  new address[](0));
    emit Registered(_tokenId);
  }

  function request(uint256 _tokenId, uint256 _checkIn, uint256 _checkOut) external {
    //validate input parms
    require(_checkIn != 0, "check in date is not set");
    require(_checkOut != 0, "check out date is not set");
    require(_checkOut > _checkIn, "Check Out date should be after check In date");
    require(stayData[_tokenId].price > 0, "tokenId is invalid");

    //make sure request is approved only once
    //ADD: check CheckIn/CheckOut dates
    if (isInArray(stayData[_tokenId].approved, msg.sender))
      revert("Already approved");

    stayData[_tokenId].requested.push(msg.sender);
    stayData[_tokenId].requests[msg.sender] = Request(_checkIn, _checkOut);
    emit Requested(_tokenId);
  }

  function approveRequest(uint256 _tokenId, address guestAddress) external onlyOwner(_tokenId)
  {
    require(_tokenId != 0, "Token Id is not set");
    require(isInArray(stayData[_tokenId].requested, guestAddress), "no requests for this address");
    require(stayData[_tokenId].requests[guestAddress].checkIn > 0, "request already approved");

    stayData[_tokenId].approved.push(guestAddress);
    emit Approved(_tokenId);
  }

  function checkIn(uint256 _tokenId) public {
    require(stayData[_tokenId].price > 0, "tokenId is invalid");
    require(isInArray(stayData[_tokenId].approved, msg.sender), "is not an approved address");
    require(!isInArray(stayData[_tokenId].occupants, msg.sender), "is already checked in");

    //reserve funds
    require(propertyToken.transferFrom(msg.sender, this, stayData[_tokenId].price), "not enough tokens");

    //validate CheckIn time
    require(stayData[_tokenId].requests[msg.sender].checkIn < now, "too early to check in");
    require(stayData[_tokenId].requests[msg.sender].checkOut > now, "too late to check in");

    stayData[_tokenId].occupants.push(msg.sender);
    stayData[_tokenId].stays = stayData[_tokenId].stays + 1;
    emit CheckedIn(_tokenId);
  }

  function checkOut(uint256 _tokenId) public{
    require(stayData[_tokenId].price > 0, "tokenId is invalid");
    require(isInArray(stayData[_tokenId].occupants, msg.sender), "is not an approved address");

    //remove occupants record
    removeFromArray(GuestType.OCCUPIED, _tokenId, msg.sender);
    //remove approved record
    removeFromArray(GuestType.APPROVED, _tokenId, msg.sender);
    //remove requested record
    removeFromArray(GuestType.REQUESTED, _tokenId, msg.sender);

    //transfer funds to property owner
    require(propertyToken.transfer(property.ownerOf(_tokenId), stayData[_tokenId].price));

    //remove reservation struct
    delete stayData[_tokenId].requests[msg.sender]; //remove request struct;
    emit CheckedOut(_tokenId);
  }

  function getStayDataDetails(uint256 _tokenId, address _guestAddress) external view returns(uint256, uint256, uint256, address[], address[], address[]){
      return (stayData[_tokenId].price, stayData[_tokenId].requests[_guestAddress].checkIn, stayData[_tokenId].requests[_guestAddress].checkOut, stayData[_tokenId].requested, stayData[_tokenId].approved, stayData[_tokenId].occupants);
  }

  function getStayData(uint256 _tokenId) external view returns(uint256, address[], address[], address[], uint256){
      return (stayData[_tokenId].price, stayData[_tokenId].requested, stayData[_tokenId].approved, stayData[_tokenId].occupants, stayData[_tokenId].stays);
  }

  //helper functions
  //move to different file?
  function getArrayItem(GuestType guestType, uint256 tokenId, uint256 index) public view returns(address){
    if (guestType == GuestType.REQUESTED){
      if (index >= stayData[tokenId].requested.length)
        return 0x0;
      return stayData[tokenId].requested[index];
    }
    else if (guestType == GuestType.APPROVED) {
      if (index >= stayData[tokenId].approved.length)
        return 0x0;
      return stayData[tokenId].approved[index];
    }
    else if (guestType == GuestType.OCCUPIED){
      if (index >= stayData[tokenId].occupants.length)
        return 0x0;
      return stayData[tokenId].occupants[index];
    }
    else
      return 0x0;
  }

  function isInArray(address[] arr, address val) private pure returns(bool){
    bool exists;
    for (uint256 i = 0; i < arr.length; i++){
      if (arr[i] == val){
        exists = true;
        break;
      }
    }
    return exists;
  }

  function removeFromArray(GuestType guestType, uint256 tokenId, address val) private {
      uint256 index;
      bool exists;
      address[] storage arr;

      if (guestType == GuestType.REQUESTED)
        arr = stayData[tokenId].requested;
      else if (guestType == GuestType.APPROVED)
        arr = stayData[tokenId].approved;
      else if (guestType == GuestType.OCCUPIED)
        arr = stayData[tokenId].occupants;
      else
        return;

      for (uint256 i = 0; i < arr.length; i++){
        if (arr[i] == val){
          index = i;
          exists = true;
          break;
        }
      }

      if (!exists)
        return;

      for (i = index; i < arr.length - 1; i++){
        arr[i] =  arr[i+1];
      }
      delete arr[arr.length-1];
      arr.length--;
    }
}
