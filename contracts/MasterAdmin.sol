pragma solidity ^0.4.24;

import "./MultiSigWallet.sol";

contract MasterAdmin is MultiSigWallet {

  string public constant name = "Alitheia Master Admin Contract";

  address nonS1TokenAddress;
  address S1TokenAddress;

  constructor(address[] _owners, uint256 _required, address _nonS1TokenAddress, address _S1TokenAddress) public MultiSigWallet(_owners, _required) {
    nonS1TokenAddress = _nonS1TokenAddress;
    S1TokenAddress = _S1TokenAddress;
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