pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Proxy/OwnableKeyed.sol";
import "./AlitheiaS1.sol";

contract Sector is OwnableKeyed {

  uint256 sectorId;

  constructor(BaseStorage storage_, uint256 _sectorId, address _S1TokenAddress, address _nonS1TokenAddress) public OwnableKeyed(storage_) {
    sectorId = _sectorId;
    storage_.setAddress(keccak256(abi.encodePacked("S1TokenAddress")), _S1TokenAddress);
    storage_.setAddress(keccak256(abi.encodePacked("nonS1TokenAddress")), _nonS1TokenAddress);
  }

  function getS1TokenAddress() public view returns (address) {
    return _storage.getAddress(keccak256(abi.encodePacked("S1TokenAddress")));
  }

  function getNonS1TokenAddress() public view returns (address) {
    return _storage.getAddress(keccak256(abi.encodePacked("nonS1TokenAddress")));
  }

  function s1Token() public view returns (AlitheiaS1) {
    return AlitheiaS1(getS1TokenAddress());
  }

  function transferS1(address _to, uint256 _amount) public onlyOwner {
    s1Token().transfer(_to, _amount);
  }

  function setCustomDatedMetric(string _type, uint256 amount, uint256 day, uint256 month, uint256 year) public onlyOwner {
    setDatedMetric(_type, amount, day, month, year);
  }

  function setCustomIpfsHash(string _hash, string _type, uint256 day, uint256 month, uint256 year) public onlyOwner {
    setIpfsHash(_hash, _type, day, month, year);
  }

  function setDatedMetric(string _type, uint256 amount, uint256 day, uint256 month, uint256 year) private {
    _storage.setUint(keccak256(abi.encodePacked("datedMetric", _type, day, month, year)), amount);
    _storage.setUint(keccak256(abi.encodePacked("datedMetric", _type, "day")), day);
    _storage.setUint(keccak256(abi.encodePacked("datedMetric", _type, "month")), month);
    _storage.setUint(keccak256(abi.encodePacked("datedMetric", _type, "year")), year);
  }

  function setIpfsHash(string _hash, string _type, uint256 day, uint256 month, uint256 year) private {
    _storage.setString(keccak256(abi.encodePacked("IPFSHash", _type, day, month, year)), _hash);
  }

  function getCustomDatedMetric(string _type, uint256 day, uint256 month, uint256 year) public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", _type, day, month, year)));
  }

  function getCustomIpfsHash(string _type, uint256 day, uint256 month, uint256 year) public view returns (string) {
    return _storage.getString(keccak256(abi.encodePacked("IPFSHash", _type, day, month, year)));
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
