pragma solidity ^0.4.24;

import "../Storage/BaseStorage.sol";
import "../StorageConsumer/StorageConsumer.sol";
import "./OwnableKeyed.sol";
import "./BaseProxy.sol";

contract OwnableProxy is OwnableKeyed, BaseProxy {

  event Upgraded(address indexed implementation_);

  constructor(BaseStorage storage_, address implementation_)
    public
    OwnableKeyed(storage_)
  {
    setImplementation(implementation_);
  }

  function implementation() public view returns (address) {
    return _storage.getAddress("implementation");
  }

  function upgradeTo(address impl) public onlyOwner {
    require(implementation() != impl);
    setImplementation(impl);
    emit Upgraded(impl);
  }

  function setImplementation(address implementation_) internal {
    _storage.setAddress("implementation", implementation_);
  }

}
