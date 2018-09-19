pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Proxy/OwnableKeyed.sol";

contract ProjectDelegate is OwnableKeyed {

  constructor(WhiteListedStorage storage_) OwnableKeyed(storage_) {}

  function s1Token() public view returns (s1TokenInterface) {
    return s1TokenInterface(S1TokenAddress);
  }

  function setNAV(uint256 amount, uint256 day, uint256 month, uint256 year) public onlyOwner {
    setDatedMetric("NAV", amount, day, month, year);
  }

  function setNAVIpfs(string _hash, uint256 day, uint256 month, uint256 year) public onlyOwner {
    setIpfsHash(_hash, "NAV", day, month, year);
  }

  function getLatestNAVIpfs() public view returns (string) {
    _storage.getString(keccak256(abi.encodePacked("IPFSHash", _type, day, month, year)));
  }

  function getLatestNAV() public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", "NAV", getDatedMetricLastDay("NAV"), getDatedMetricLastMonth("NAV"), getDatedMetricLastyear("NAV"))));
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

  function getDatedMetricLastDay(string _type) public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", _type, "day")));
  }

  function getDatedMetricLastMonth(string _type) public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", _type, "month")));
  }

  function getDatedMetricLastYear(string _type) public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", _type, "year")));
  }

  function getCustomDatedMetric(string _type, uint256 day, uint256 month, uint256 year) public view returns (uint256) {
    return _storage.getUint(keccak256(abi.encodePacked("datedMetric", _type, day, month, year)));
  }

  function getCustomIpfsHash(string _type, uint256 day, uint256 month, uint256 year) public view returns (string) {
    return _storage.getString(keccak256(abi.encodePacked("IPFSHash", _type, day, month, year)));
  }

  function payDividend(uint256 amount) public onlyOwner {
    s1Token().createDividendEvent(amount);
  }

  function customPayout(uint256 amount) public onlyOwner {
    s1Token().customPayout(amount);
  }

  function transferS1(address _to, uint256 _amount) public onlyOwner {
    s1Token().transfer(_to, _amount);
  }
}
