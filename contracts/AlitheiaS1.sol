pragma solidity ^0.4.24;

import "./DateTime.sol";
import "./AlitheiaToken.sol";

contract AlitheiaS1 is AlitheiaToken, DateTime{
    uint256 pointMultiplier = 10e18;

    /* Dividend Variables Start */
        struct DividendEvent {
            uint256 amount;
            uint256 totalSupplyAtEvent;
        }

        // dividendEvents each key value pair represents single dividend payout event
        // Key: dividendEventId increment by 1 for every dividend payout event
        // Value: DividentEvent
        mapping(uint256 => DividendEvent) private dividendEvents;

        // dividendEventIdForAddress must be set for both to and from for every transfer() call to currentGlobalDividendEventId
        mapping(address => uint256) private dividendEventIdForAddress;

        // Most recent dividend event id
        uint256 currentGlobalDividendEventId;
    /* Dividend Variables End */

    /* Interest Variables Start */
        struct InterestEvent {
            uint256 amount;
            uint256 totalSupplyAtEvent;
        }

        // interestEvents each key value pair represents single interest payout event
        // Key: InterestEvent increment by 1 for every interest payout event
        // Value: DividentEvent
        mapping(uint256 => InterestEvent) private interestEvents;

        // interestEventIdForAddress must be set for both to and from for every transfer() call to currentGlobalDividendEventId
        mapping(address => uint256) private interestEventIdForAddress;

        // Most recent dividend event id
        uint256 currentGlobalInterestEventId;
    /* Interest Variables End */

    function () public payable {}
    
    // Constructor
    constructor(address _restrictedAddress) public AlitheiaToken(_restrictedAddress) {
        currentGlobalDividendEventId = 0;
        currentGlobalInterestEventId = 0;
    }

    function getCurrentGlobalDividendEventId() public view returns (uint256) {
        return currentGlobalDividendEventId;
    }

    function getDividendEventIdForAddress(address _address) public view returns (uint256) {
        return dividendEventIdForAddress[_address];
    }

    function getInterestEventIdForAddress(address _address) public view returns (uint256) {
        return interestEventIdForAddress[_address];
    }

    function getAmountForDividendId(uint256 id) public view returns (uint256) {
        return dividendEvents[id].amount;
    }

    function getTotalSupplyAtEventForDividendId(uint256 id) public view returns (uint256) {
        return dividendEvents[id].totalSupplyAtEvent;
    }

    // Customized BalanceOf Function
    function balanceOf(address _address) public view returns (uint256) {
        uint256 dividendOwed = calculateDividendOwed(_address);
        uint256 interestOwed = calculateInterestOwed(_address);
        return balances[_address] + dividendOwed + interestOwed;
    }

    // Includes NonS1 Tokens
    function totalBalanceOf(address _address) public view returns (uint256) {
        return balanceOf(_address) + restrictedContract().balanceOf(_address);
    }

    // Calculate Owed Dividend
    function calculateDividendOwed(address _address) public view returns (uint256) {
        uint256 currentDividendEventId = dividendEventIdForAddress[_address];

        // If current == global assume all dividends were paid
        if(currentDividendEventId == currentGlobalDividendEventId)
            return 0;

        uint256 currentBalance = balances[_address] + restrictedContract().balanceOf(_address);

        currentDividendEventId += 1; // Since current dividend is already paid we need to skip to the next dividend event

        for (currentDividendEventId; currentDividendEventId <= currentGlobalDividendEventId; currentDividendEventId++) {
            currentBalance += (((dividendEvents[currentDividendEventId].amount * pointMultiplier) / dividendEvents[currentDividendEventId].totalSupplyAtEvent) * currentBalance) / pointMultiplier;
        }

        return currentBalance - (balances[_address] + restrictedContract().balanceOf(_address));
    }

    // Calculate Owed Interest
    function calculateInterestOwed(address _address) public view returns (uint256) {
        uint256 currentInterestEventId = interestEventIdForAddress[_address];

        // If current == global assume all interest were paid
        if(currentInterestEventId == currentGlobalDividendEventId)
            return 0;

        uint256 currentBalance = balances[_address] + restrictedContract().balanceOf(_address);

        currentInterestEventId += 1; // Since current interest is already paid we need to skip to the next interest event

        for (currentInterestEventId; currentInterestEventId <= currentGlobalInterestEventId; currentInterestEventId++) {
            currentBalance = currentBalance + (((interestEvents[currentInterestEventId].amount * pointMultiplier) / interestEvents[currentInterestEventId].totalSupplyAtEvent) * currentBalance) / pointMultiplier;
        }

        return currentBalance - (balances[_address] + restrictedContract().balanceOf(_address));
    }

    // Create Dividend Event
    function createDividendEvent(uint256 amount) onlyArbOrOwner public returns (uint256) {
        uint256 newCurrentGlobalDividendEventId = currentGlobalDividendEventId += 1;
        totalSupply_ = totalSupply_.add(amount);

        dividendEvents[newCurrentGlobalDividendEventId] = DividendEvent(amount, (totalSupply_ + restrictedContract().totalSupply()));
        return newCurrentGlobalDividendEventId;
    }

    // Create Interest Event
    function createInterestEvent(uint256 amount) onlyArbOrOwner public returns (uint256) {
        uint256 newCurrentGlobalInterestEventId = currentGlobalInterestEventId += 1;
        totalSupply_ = totalSupply_.add(amount);

        interestEvents[newCurrentGlobalInterestEventId] = InterestEvent(amount, (totalSupply_ + restrictedContract().totalSupply()));

        return newCurrentGlobalInterestEventId;
    }

    // customMint does not increase totalSupply_
    function customMint(address _to, uint256 _amount) private returns (bool) {
        require(_to != owner);
        require(_amount > 0);

        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

    // Called by project contracts to payout custom amounts
    function customPayout(uint256 _amount) onlyArbiter public returns (bool) {
        require(_amount > 0);

        totalSupply_ = totalSupply_.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Mint(msg.sender, _amount);
        return true;
    }

    // Will burn Non S1 tokens and mint and credit equivalent S1 Tokens
    function convertNonS1Tokens() public returns (uint256) {
        uint256 amount = restrictedContract().clearAvailableTokens(msg.sender);
        if (amount > 0) {
            totalSupply_ = totalSupply_.add(amount);
            balances[msg.sender] = balances[msg.sender].add(amount);
            emit Mint(msg.sender, amount);
            return amount;
        } else {
            return 0;
        }
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint256 _amount, bytes _data) public returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        /* Dividend */
        if(msg.sender != owner){
            uint256 senderDividendOwed = calculateDividendOwed(msg.sender);
            dividendEventIdForAddress[msg.sender] = currentGlobalDividendEventId;
            if(senderDividendOwed > 0)
                customMint(msg.sender, senderDividendOwed);
        }

        if(_to != owner){
            uint256 receiverDividendOwed = calculateDividendOwed(_to);
            dividendEventIdForAddress[_to] = currentGlobalDividendEventId;
            if(receiverDividendOwed > 0)
                customMint(_to, receiverDividendOwed);
        }
        /* Dividend End */

        /* Interest */
        if(msg.sender != owner){
            uint256 senderInterestOwed = calculateInterestOwed(msg.sender);
            interestEventIdForAddress[msg.sender] = currentGlobalInterestEventId;
            if(senderInterestOwed > 0)
                customMint(msg.sender, senderInterestOwed);
        }

        if(_to != owner){
            uint256 receiverInterestOwed = calculateInterestOwed(_to);
            interestEventIdForAddress[_to] = currentGlobalInterestEventId;
            if(receiverInterestOwed > 0)
                customMint(_to, receiverInterestOwed);
        }
        /* Interest End */

        bool result = false;

        if(isContract(_to))
            result = transferToContract(_to, _amount, _data);
        else
            result = transferToAddress(_to, _amount, _data);
    
        return result;
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _amount) public returns (bool) {      
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        /* Dividend */
        if(msg.sender != owner){
            uint256 senderDividendOwed = calculateDividendOwed(msg.sender);
            dividendEventIdForAddress[msg.sender] = currentGlobalDividendEventId;
            if(senderDividendOwed > 0)
                customMint(msg.sender, senderDividendOwed);
        }

        if(_to != owner){
            uint256 receiverDividendOwed = calculateDividendOwed(_to);
            dividendEventIdForAddress[_to] = currentGlobalDividendEventId;
            if(receiverDividendOwed > 0)
                customMint(_to, receiverDividendOwed);
        }
        /* Dividend End */

        /* Interest */
        if(msg.sender != owner){
            uint256 senderInterestOwed = calculateInterestOwed(msg.sender);
            interestEventIdForAddress[msg.sender] = currentGlobalInterestEventId;
            if(senderInterestOwed > 0)
                customMint(msg.sender, senderInterestOwed);
        }

        if(_to != owner){
            uint256 receiverInterestOwed = calculateInterestOwed(_to);
            interestEventIdForAddress[_to] = currentGlobalInterestEventId;
            if(receiverInterestOwed > 0)
                customMint(_to, receiverInterestOwed);
        }
        /* Interest End */

        bool result = false;
        bytes memory empty;
        
        if(isContract(_to))
            result = transferToContract(_to, _amount, empty);
        else
            result = transferToAddress(_to, _amount, empty);
    
        return result;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool){
        uint256 length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint256 _amount, bytes _data) private returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _amount, bytes _data) private returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        ERC223_ContractReceiver receiver = ERC223_ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _amount, _data);
        
        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }
}