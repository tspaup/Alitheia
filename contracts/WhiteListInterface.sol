pragma solidity ^0.4.24;

contract WhiteListInterface {
    event WhiteListChanged(
        string eventType,
        address changedAddress
    );

    function addToSendAllowed(address sendAllowedAddress) public;

    function addToReceiveAllowed(address receiveAllowedAddress) public;

    function addToBothSendAndReceiveAllowed(address _address) public;

    function removeFromSendAllowed(address sendNotAllowedAddress) public;

    function removeFromReceiveAllowed(address receiveNotAllowedAddress) public;

    function checkReceiveAllowed(address _address) public view returns (bool);

    function checkSendAllowed(address _address) public view returns (bool);

    function pauseTransfers() public;

    function unPauseTransfers() public;

    function areTransfersPaused() public view returns (bool);

    function checkTransferAllowed(address _from, address _to) public view returns (uint);

    function restrictionCodeToMessage (uint restrictionCode) public view returns (string message);
}