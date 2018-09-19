pragma solidity ^0.4.24;

import "./Proxy/OwnableProxy.sol";
import "./Storage/WhiteListedStorage.sol";

contract ProjectProxy is OwnableProxy {

  constructor(
    WhiteListedStorage storage_,
    address projectDelegateAddress,
    address S1TokenAddress,
    address nonS1TokenAddress
  )
    OwnableProxy(storage_, projectDelegateAddress)
    public
  {
    storage_.setAddress(keccak256(abi.encodePacked("S1TokenAddress")), S1TokenAddress);
    storage_.setAddress(keccak256(abi.encodePacked("nonS1TokenAddress")), nonS1TokenAddress);
  }

  function getS1TokenAddress() public view returns (address) {
    return _storage_.getAddress(keccak256(abi.encodePacked("S1TokenAddress")));
  }

  function getNonS1TokenAddress() public view returns (address) {
    return _storage_.setAddress(keccak256(abi.encodePacked("nonS1TokenAddress")));
  }

  struct TX{
    address sender;
    uint256 value;
    bytes data;
    bytes4 sig;
  }

  function tokenFallback(address _from, uint256 _value, bytes _data) public pure{
    TX memory tran;

    tran.sender = _from;
    tran.value = _value;
    tran.data = _data;
    uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tran.sig = bytes4(u);
  }

}
