pragma solidity ^0.4.24;

import "./DateTime.sol";
import "./AlitheiaRestrictedToken.sol";

contract AlitheiaNonS1 is AlitheiaRestrictedToken, DateTime{
	/* Package Day */
	struct Package{
        uint256 amount;
        uint timestamp;
        uint lockedUntil;
    }

    /* Both of Packages Per Day */
    struct PackageDay{
        uint256 amount;
        Package[] packages;
    }

    // Holder Addresses
   	address[] private holders;

   	// Holder Existence
   	mapping(address => bool) holderExist;

    /* Token Variables */
        // Address -> Years
        mapping(address => uint[]) private holderYears;
        // Address -> Year -> Bool
        mapping(address => mapping (uint => bool)) private holderYearExist;

        // Address -> Year -> Months
        mapping(address => mapping (uint => uint[])) private holderMonths;
        // Address -> Year -> Month -> Bool
        mapping(address => mapping (uint => mapping (uint => bool))) private holderMonthExist;

        // Address -> Year -> Month -> Days
        mapping(address => mapping (uint => mapping (uint => uint[]))) private holderDays;
        // Address -> Year -> Month -> Day -> Bool
        mapping(address => mapping (uint => mapping (uint => mapping(uint => bool)))) private holderDayExist;

        // Address -> Year -> Month -> Day -> PackageDay
        mapping(address => mapping (uint => mapping (uint => mapping (uint => PackageDay)))) private holderTokens;
    /* Token Variables End */

	constructor () public {}

    /* Clear Unlocked Balance */
    function clearUnlockedBalanceOf(address _address, uint timestamp) private returns (uint256){
        uint256 amount = 0;
        bool flag = false;

        if(!holderExist[_address] || holderYears[_address].length == 0)
            return amount;

        for(uint yearIndex = 0; yearIndex < holderYears[_address].length; yearIndex++){
            uint year = holderYears[_address][yearIndex];

            if(holderMonths[_address][year].length == 0)
                continue;

            for(uint monthIndex = 0; monthIndex < holderMonths[_address][year].length; monthIndex++){
                uint month = holderMonths[_address][year][monthIndex];

                if(holderDays[_address][year][month].length == 0)
                    continue;

                for(uint dayIndex = 0; dayIndex < holderDays[_address][year][month].length; dayIndex++){
                    uint day = holderDays[_address][year][month][dayIndex];

                    if(holderTokens[_address][year][month][day].packages.length == 0)
                        continue;
                    
                    for(uint i = 0; i < holderTokens[_address][year][month][day].packages.length; i++){
                        if(holderTokens[_address][year][month][day].packages[i].lockedUntil <= timestamp){
                            amount = amount.add(holderTokens[_address][year][month][day].packages[i].amount);

                            /* Clear Tokens */
                            clearPackage(_address, year, month, day, i);

                            if(holderTokens[_address][year][month][day].amount == 0 || holderTokens[_address][year][month][day].packages.length == 0){
                                /* Clear Day */
                                clearDay(_address, year, month, day, dayIndex);

                                if(holderDays[_address][year][month].length == 0){
                                    /* Clear Month */
                                    clearMonth(_address, year, month, monthIndex);

                                    if(holderMonths[_address][year].length == 0){
                                        /* Clear Year */
                                        clearYear(_address, year, yearIndex);
                                    }
                                }
                            }
                        }else
                            flag = true;

                        if(flag)
                            break;
                    }

                    if(flag)
                        break;
                }

                if(flag)
                    break;
            }

            if(flag)
                break;
        }

        return amount;
    }

    /* Clear Year By Index */
    function clearYear(address _address, uint _year, uint _index) private{
        if(_index < holderYears[_address].length - 1){
            for(uint i = _index; i < holderYears[_address].length - 1; i++)
                holderYears[_address][i] = holderYears[_address][i+1];
        }

        holderYears[_address].length--;
        holderYearExist[_address][_year] = false;
    }

    /* Clear Month By Index */
    function clearMonth(address _address, uint _year, uint _month, uint _index) private{
        if(_index < holderMonths[_address][_year].length - 1){
            for(uint i = _index; i < holderMonths[_address][_year].length - 1; i++)
                holderMonths[_address][_year][i] = holderMonths[_address][_year][i+1];
        }

        holderMonths[_address][_year].length--;
        holderMonthExist[_address][_year][_month] = false;
    }

    /* Clear Day By Index */
    function clearDay(address _address, uint _year, uint _month, uint _day, uint _index) private{
        if(_index < holderDays[_address][_year][_month].length - 1){
            for(uint i = _index; i < holderDays[_address][_year][_month].length - 1; i++)
                holderDays[_address][_year][_month][i] = holderDays[_address][_year][_month][i+1];
        }

        holderDays[_address][_year][_month].length--;
        holderDayExist[_address][_year][_month][_day] = false;
    }

    /* Clear Package By Index */
    function clearPackage(address _address, uint _year, uint _month, uint _day, uint _index) private{
        if(_index < holderTokens[_address][_year][_month][_day].packages.length - 1){
            for(uint i = _index; i < holderTokens[_address][_year][_month][_day].packages.length - 1; i++){
                holderTokens[_address][_year][_month][_day].packages[i] = holderTokens[_address][_year][_month][_day].packages[i+1];
            }
        }

        holderTokens[_address][_year][_month][_day].amount.sub(holderTokens[_address][_year][_month][_day].packages[_index].amount);
            
        holderTokens[_address][_year][_month][_day].packages.length--;
    }

    /* Clear Available Non S1 Tokens */
    function clearAvailableTokens() public returns (uint256){
        uint256 amount = clearUnlockedBalanceOf(msg.sender, now);
        
        if(amount > 0)        
            burn(msg.sender, amount);

        return amount;
    }

	function addHolder(address _address) private{
		if(!holderExist[_address]){
			holderExist[_address] = true;
			holders.push(_address);
		}
	}

    function addTime(address _address, uint _year, uint _month, uint _day) private{
        if(!holderYearExist[_address][_year]){
            holderYearExist[_address][_year] = true;
            holderYears[_address].push(_year);
        }

        if(!holderMonthExist[_address][_year][_month]){
            holderMonthExist[_address][_year][_month] = true;
            holderMonths[_address][_year].push(_month);
        }

        if(!holderDayExist[_address][_year][_month][_day]){
            holderDayExist[_address][_year][_month][_day] = true;
            holderDays[_address][_year][_month].push(_day);
        }
    }

    function addTokenData(address _address, uint256 _amount, uint timestamp) private{
        addHolder(_address);

        uint year = getYear(timestamp);
        uint month = getMonth(timestamp);
        uint day = getDay(timestamp);

        addTime(_address, year, month, day);

        uint lockTime = timestamp + 2 * 365 * 1 days;

        /* Saving Tokens to the variable */
        holderTokens[_address][year][month][day].amount.add(_amount);
        holderTokens[_address][year][month][day].packages.push(Package(_amount, timestamp, lockTime));
    }

	// Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint256 _amount, bytes _data) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        bool result = false;

        if(isContract(_to))
            result = transferToContract(_to, _amount, _data);
        else
            result = transferToAddress(_to, _amount, _data);

        if(result)
            addTokenData(_to, _amount, now);

        return result;
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _amount) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        bytes memory empty;
        bool result = false;

        if(isContract(_to))
            result = transferToContract(_to, _amount, empty);
        else
            result = transferToAddress(_to, _amount, empty);

        if(result)
            addTokenData(_to, _amount, now);

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