pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract PropertyToken is DetailedERC20, MintableToken {
  mapping(address => bool) public freeTokens;

  constructor(string _name, string _symbol) DetailedERC20(_name, _symbol, 2) public {
    mint(msg.sender, 1000000);
  }

  function bonusTokens(address _guest) public {
    require(!freeTokens[_guest], 'already got bonus tokens');
    freeTokens[_guest] = true;

    mint(_guest, 2000);
  }
}
