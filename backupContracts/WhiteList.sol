pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./WhiteListInterface.sol";

contract WhiteList is Ownable, WhiteListInterface {
    mapping(bytes32 => bool) _boolStorage;

    event WhiteListChanged(
      string eventType,
      address changedAddress
    );

    function addToSendAllowed(address sendAllowedAddress) public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("sendAllowed", sendAllowedAddress))] = true;
      emit WhiteListChanged("addToSendAllowed", sendAllowedAddress);
    }

    function addToReceiveAllowed(address receiveAllowedAddress) public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("receiveAllowed", receiveAllowedAddress))] = true;
      emit WhiteListChanged("addToReceiveAllowed", receiveAllowedAddress);
    }

    function addToBothSendAndReceiveAllowed(address _address) public onlyOwner {
      addToSendAllowed(_address);
      addToReceiveAllowed(_address);
    }

    function removeFromSendAllowed(address sendNotAllowedAddress) public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("sendAllowed", sendNotAllowedAddress))] = false;
      emit WhiteListChanged("removeFromSendAllowed", sendNotAllowedAddress);
    }

    function removeFromReceiveAllowed(address receiveNotAllowedAddress) public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("receiveAllowed", receiveNotAllowedAddress))] = false;
      emit WhiteListChanged("removeFromReceiveAllowed", receiveNotAllowedAddress);
    }

    function removeFromBothSendAndReceiveAllowed(address _address) public onlyOwner {
      removeFromSendAllowed(_address);
      removeFromReceiveAllowed(_address);
    }

    function checkReceiveAllowed(address _address) public view returns (bool) {
      return _boolStorage[keccak256(abi.encodePacked("receiveAllowed", _address))];
    }

    function checkSendAllowed(address _address) public view returns (bool) {
      return _boolStorage[keccak256(abi.encodePacked("sendAllowed", _address))];
    }

    function pauseTransfers() public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("transfersPaused"))] = true;
    }

    function unPauseTransfers() public onlyOwner {
      _boolStorage[keccak256(abi.encodePacked("transfersPaused"))] = false;
    }

    function areTransfersPaused() public view returns (bool) {
      return _boolStorage[keccak256(abi.encodePacked("transfersPaused"))];
    }

    function checkTransferAllowed(address _from, address _to) public view returns (uint) {
      if (areTransfersPaused()) {
          return 1;
      } else if (!checkSendAllowed(_from)) {
          return 2;
      } else if (!checkReceiveAllowed(_to)) {
          return 3;
      } else {
          return 0;
      }
    }

    function restrictionCodeToMessage (uint restrictionCode) public view returns (string message) {
      if (restrictionCode == 0) {
          return "Success";
      } else if (restrictionCode == 1) {
          return "All transfers are currently paused";
      } else if (restrictionCode == 2) {
          return "From adddress field is not allowed to send";
      } else if (restrictionCode == 3) {
          return "To address field is not allowed to recieve";
      } else {
          return "Not a valid error code";
      }
    }
}