pragma solidity ^0.4.24;

import "../Storage/BaseStorage.sol";
import "./StorageStateful.sol";

contract StorageConsumer is StorageStateful {
  constructor(BaseStorage storage_) public {
    _storage = storage_;
  }
}
