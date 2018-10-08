pragma solidity ^0.4.24;

import "./DateTime.sol";
import "./AlitheiaRestrictedToken.sol";

contract AlitheiaNonS1 is AlitheiaRestrictedToken, DateTime{
	/* Package Day */
	struct Package{
        uint256 amount;
        uint timestamp;
        uint lockedUntil;
        bool cleared;
    }

    /* Both of Packages Per Day */
    struct PackageDay{
        uint256 amount;
        Package[] packages;
    }

    address internal S1TokenAddress;

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

    /* Last Clearing Variables */
        bool private isClearing;
        bool private flag;

        mapping(address => uint) private lastYearIndex;
        mapping(address => uint) private lastMonthIndex;
        mapping(address => uint) private lastDayIndex;
        mapping(address => uint) private lastPackageIndex;
    /* Last Clearing Variables End */

	constructor () public {
        isClearing = false;
        flag = false;
    }

    modifier onlyS1TokenContract() { 
        require (msg.sender == S1TokenAddress); 
        _;
    }
    
    function setS1TokenAddress(address _address) onlyOwner public {
        S1TokenAddress = _address;
    }

    /* Save Last Clearing Data */
    function saveLastClearingData(address _address, uint _yearIndex, uint _monthIndex, uint _dayIndex, uint _packageIndex) private {
        uint year = holderYears[_address][_yearIndex];
        uint month = holderMonths[_address][year][_monthIndex];
        uint day = holderDays[_address][year][month][_dayIndex];
        
        if(_packageIndex < holderTokens[_address][year][month][day].packages.length - 1){
            lastYearIndex[_address] = _yearIndex;
            lastMonthIndex[_address] = _monthIndex;
            lastDayIndex[_address] = _dayIndex;
            lastPackageIndex[_address] = _packageIndex + 1;
        }else{
            lastPackageIndex[_address] = 0;
            
            if(_dayIndex < holderDays[_address][year][month].length - 1){
                lastYearIndex[_address] = _yearIndex;
                lastMonthIndex[_address] = _monthIndex;
                lastDayIndex[_address] = _dayIndex + 1;
            }else{
                lastDayIndex[_address] = 0;

                if(_monthIndex < holderMonths[_address][year].length - 1){
                    lastYearIndex[_address] = _yearIndex;
                    lastMonthIndex[_address] = _monthIndex + 1;
                }else{
                    lastYearIndex[_address] = _yearIndex + 1;
                    lastMonthIndex[_address] = 0;
                }
            }
        }
    }

    /* Get Start Day Index for Clearing */
    function getStartingDayIndex(address _address, uint _yearIndex, uint _monthIndex) private view returns (uint){
        uint startingDayIndex = lastDayIndex[_address];
        if(_yearIndex != lastYearIndex[_address] || _monthIndex != lastMonthIndex[_address])
            startingDayIndex = 0;

        return startingDayIndex;
    }

    /* Get Start Package Index for Clearing */
    function getStartingPackageIndex(address _address, uint _yearIndex, uint _monthIndex, uint _dayIndex) private view returns (uint){
        uint startingPackageIndex = lastPackageIndex[_address];
        if(_yearIndex != lastYearIndex[_address] || _monthIndex != lastMonthIndex[_address] || _dayIndex != lastDayIndex[_address])
            startingPackageIndex = 0;

        return startingPackageIndex;
    }

    /* Get Unlocked Balance By Day */
    function getUnlockedBalanceByDay(address _address, uint _yearIndex, uint _monthIndex, uint _dayIndex, uint timestamp) private returns (uint256){
        uint256 amount = 0;
        
        uint year = holderYears[_address][_yearIndex];
        uint month = holderMonths[_address][year][_monthIndex];
        uint day = holderDays[_address][year][month][_dayIndex];
        uint length = holderTokens[_address][year][month][day].packages.length;

        if(length == 0)
            return 0;

        for(uint i = getStartingPackageIndex(_address, _yearIndex, _monthIndex, _dayIndex); i < length; i++){
            if(holderTokens[_address][year][month][day].packages[i].cleared)
                continue;

            if(holderTokens[_address][year][month][day].packages[i].lockedUntil <= timestamp){
                amount = amount.add(holderTokens[_address][year][month][day].packages[i].amount);

                if(isClearing)
                    saveLastClearingData(_address, _yearIndex, _monthIndex, _dayIndex, i);
            }
            else
                flag = true;

            if(flag)
                break;
        }

        return amount;
    }   

    /* Get Unlocked Balance By Month */
    function getUnlockedBalanceByMonth(address _address, uint _yearIndex, uint _monthIndex, uint timestamp) private returns (uint256){
        uint year = holderYears[_address][_yearIndex];
        uint month = holderMonths[_address][year][_monthIndex];
        uint length = holderDays[_address][year][month].length;
        if(length == 0)
            return 0;

        uint startingDayIndex = getStartingDayIndex(_address, _yearIndex, _monthIndex);
        if(startingDayIndex >= length)
            return 0;

        uint256 amount = 0;
        
        for(uint _dayIndex = startingDayIndex; _dayIndex < length; _dayIndex++){
            amount = amount.add(getUnlockedBalanceByDay(_address, _yearIndex, _monthIndex, _dayIndex, timestamp));

            if(flag)
                break;
        }

        return amount;
    }

    /* Get Unlocked Balance By Year */
    function getUnlockedBalanceByYear(address _address, uint _yearIndex, uint timestamp) private returns (uint256){
        uint256 amount = 0;
        
        uint year = holderYears[_address][_yearIndex];

        if(holderMonths[_address][year].length == 0)
            return 0;

        uint startingMonthIndex = lastMonthIndex[_address];
        if(_yearIndex != lastYearIndex[_address])
            startingMonthIndex = 0;

        if(startingMonthIndex >= holderMonths[_address][year].length)
            return 0;

        for(uint _monthIndex = startingMonthIndex; _monthIndex < holderMonths[_address][year].length; _monthIndex++){
            amount = amount.add(getUnlockedBalanceByMonth(_address, _yearIndex, _monthIndex, timestamp));
            
            if(flag)
                break;
        }

        return amount;
    }

    /* Get Unlocked Balance */
    function getUnlockedBalanceOf(address _address) public returns (uint256){
        isClearing = false;
        flag = false;

        uint256 amount = 0;
        
        if(holderYears[_address].length == 0 || lastYearIndex[_address] >= holderYears[_address].length)
            return amount;

        for(uint yearIndex = lastYearIndex[_address]; yearIndex < holderYears[_address].length; yearIndex++){
            amount = amount.add(getUnlockedBalanceByYear(_address, yearIndex, now));

            if(flag)
                break;
        }

        return amount;
    }

    /* Clear Unlocked Balance */
    function clearUnlockedBalanceOf(address _address, uint timestamp) private returns (uint256){
        isClearing = true;
        flag = false;

        uint256 amount = 0;
        
        if(holderYears[_address].length == 0 || lastYearIndex[_address] >= holderYears[_address].length)
            return amount;

        for(uint yearIndex = lastYearIndex[_address]; yearIndex < holderYears[_address].length; yearIndex++){
            amount = amount.add(getUnlockedBalanceByYear(_address, yearIndex, timestamp));

            if(flag)
                break;
        }

        return amount;
    }

    /* Clear Available Non S1 Tokens */
    function clearAvailableTokens(address _address) onlyS1TokenContract public returns (uint256){
        uint256 amount = clearUnlockedBalanceOf(_address, now);
        
        if(amount > 0){
            _burn(_address, amount);
            return amount;
        }else
            return 0;
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
        uint year = getYear(timestamp);
        uint month = getMonth(timestamp);
        uint day = getDay(timestamp);

        addTime(_address, year, month, day);

        uint lockTime = timestamp + 2 * 365 * 1 days;

        /* Saving Tokens to the variable */
        holderTokens[_address][year][month][day].amount = holderTokens[_address][year][month][day].amount.add(_amount);
        holderTokens[_address][year][month][day].packages.push(Package(_amount, timestamp, lockTime, false));
    }

    /**
     * @dev Function to burn owner tokens
     */
    function burnOwner(uint256 _amount) onlyOwner public{
        _burn(msg.sender, _amount);
    } 

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool){
        require(_to != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        if(_to != owner)
            addTokenData(_to, _amount, now);

        emit Mint(_to, _amount);

        bytes memory empty;
        emit Transfer(msg.sender, _to, _amount, empty);
        return true;
    }

	// Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint256 _amount, bytes _data) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_to != owner);
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
        require(_to != owner);
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

    // This function is for test - This should be removed when deploying on the live network
    function transferTest(address _to, uint256 _amount, uint16 _year, uint8 _month, uint8 _day) onlyOwner public returns (bool){    
        uint timestamp = toTimestamp(_year, _month, _day);

        require(_to != address(0));
        require(_to != owner);
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        bytes memory empty;
        bool result = false;

        if(isContract(_to))
            result = transferToContract(_to, _amount, empty);
        else
            result = transferToAddress(_to, _amount, empty);

        if(result)
            addTokenData(_to, _amount, timestamp);

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

    //function to get holder years
    function getHolderYears(address _address) onlyOwner public view returns (uint[]) {
        return holderYears[_address];
    }

    //function to get holder months from year
    function getHolderMonths(address _address, uint _year) onlyOwner public view returns (uint[]) {
        return holderMonths[_address][_year];
    }

    //function to get holder days from year and month
    function getHolderDays(address _address, uint _year, uint _month) onlyOwner public view returns (uint[]) {
        return holderDays[_address][_year][_month];
    }
}