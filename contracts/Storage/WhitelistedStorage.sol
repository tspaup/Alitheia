pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BaseStorage.sol";

contract WhitelistedStorage is BaseStorage, Ownable {

  mapping(address => bool) public _whitelistedSenders;
  bool publicStorageEnabled;

  constructor () public {
    publicStorageEnabled = true;
  }

  function senderIsValid() private view returns (bool) {
    if(!publicStorageEnabled)
      return _whitelistedSenders[msg.sender];
    return true;
  }

  function enablePublicStorage() public onlyOwner {
    publicStorageEnabled = true;
  }

  function disablePublicStorage() public onlyOwner {
    publicStorageEnabled = false;
  }

  function addSender(address sender) public onlyOwner {
    _whitelistedSenders[sender] = true;
  }

  function removeSender(address sender) public onlyOwner {
    delete _whitelistedSenders[sender];
  }

  function scopedKey(bytes32 key) internal view returns(bytes32) {
    return keccak256(abi.encodePacked(msg.sender, key));
  }
}