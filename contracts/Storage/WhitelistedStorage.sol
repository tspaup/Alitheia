pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BaseStorage.sol";

contract WhitelistedStorage is BaseStorage, Ownable {
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
}