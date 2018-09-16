pragma solidity ^0.4.24;

import "./ERC223_ContractReceiver.sol";

contract Arbiter is ERC223_ContractReceiver {

  mapping(address => bool) arbiters;

  event ArbiterChange(address indexed Arbiter, string eventType);

  modifier onlyArbiter() {
    require(isArbiter(msg.sender));
    _;
  }

  modifier onlyArbOrOwner() {
    require(msg.sender == owner || isArbiter(msg.sender));
    _;
  }

  function isArbiter(address addr) public view returns (bool) {
    return arbiters[addr];
  }

  function setArbiter(address addr) public onlyOwner {
    arbiters[addr] = true;
    emit ArbiterChange(addr, "add");
  }

  function removeArbiter(address addr) public onlyOwner {
    arbiters[addr] = false;
    emit ArbiterChange(addr, "remove");
  }
}