pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./WhiteListInterface.sol";

contract AlitheiaWhiteListToken is MintableToken {
  string public constant symbol = "ALITWLT";
  string public constant name = "AlitheiaWhiteListToken";
  uint public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 1.5 * 10**9;

  address whiteListAddress;

  constructor (address _whiteListAddress) public {
    whiteListAddress = _whiteListAddress;
    totalSupply_ = INITIAL_SUPPLY * (10 ** decimals);
    balances[msg.sender] = totalSupply_;
  }

  function whiteList() public view returns (WhiteListInterface) {
    return WhiteListInterface(whiteListAddress);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(checkTransferAllowed(_from, _to, _value) == 0);
    super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(checkTransferAllowed(msg.sender, _to, _value) == 0);
    super.transfer(_to, _value);
  }

  function checkTransferAllowed(address _from, address _to, uint256 _value) public view returns (uint) {
    return whiteList().checkTransferAllowed(_from, _to, _value);
  }

  function restrictionCodeToMessage (uint restrictionCode) public view returns (string message) {
    return whiteList().restrictionCodeToMessage(restrictionCode);   
  }


}