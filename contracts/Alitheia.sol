pragma solidity ^0.4.24;

import "./MintToken.sol";
import "./DateTime.sol";

contract Alitheia is MintToken, DateTime{
    struct Package{
        uint256 amount;
        uint timestamp;
        uint lockedUntil;
    }

    struct PackageDay{
        uint256 amount;
        Package[] packages;
    }

    string public constant symbol = "ALIT";
    string public constant name = "Alitheia";
    uint8 public constant decimals = 18;

    uint256 public unitPrice = (20) * (10 ** 4); // Decimal 4

    /* Contract Variables */
        // Address -> Years
        mapping(address => uint[]) private holderYears;

        // Address -> Year -> Months
        mapping(address => mapping (uint => uint[])) private holderMonths;

        // Address -> Year -> Months -> Days
        mapping(address => mapping (uint => mapping (uint => uint[]))) private holderDays;

        // Address -> Year -> Month -> Day -> PackageDay
        mapping(address => mapping (uint => mapping (uint => mapping (uint => PackageDay)))) private holderTokens;
    /* Contract Variables End */

    function () public payable {}
    
    // Constructor
    constructor() public{
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(0x0, owner, balances[owner]);
    }

    modifier onlyUnlocked(uint256 _amount){
        uint256 unlockedBalance = unlockedBalanceOf(msg.sender);

        require(unlockedBalance >= _amount);
        _;
    }   

    function setUnitPrice(uint256 _unitPrice) public returns (bool){
        unitPrice = _unitPrice;
    }

    function unlockedBalanceOf(address _owner) public view returns (uint256){
        return this.balanceOf(_owner).sub(lockedBalanceOf(_owner));   
    }

    function lockedBalanceOf(address _owner) public view returns (uint256){
        uint256 amount = 0;
        bool flag = false;

        if(holderYears[_owner].length == 0)
            return amount;

        for(uint yearIndex = holderYears[_owner].length - 1; yearIndex >= 0; yearIndex--){
            uint year = holderYears[_owner][yearIndex];

            if(holderMonths[_owner][year].length == 0)
                continue;

            for(uint monthIndex = holderMonths[_owner][year].length - 1; monthIndex >= 0; monthIndex--){
                uint month = holderMonths[_owner][year][monthIndex];

                if(holderDays[_owner][year][month].length == 0)
                    continue;

                for(uint dayIndex = holderDays[_owner][year][month].length - 1; dayIndex >= 0; dayIndex--){
                    uint day = holderDays[_owner][year][month][dayIndex];

                    if(holderTokens[_owner][year][month][day].packages.length == 0)
                        continue;

                    for(uint i = holderTokens[_owner][year][month][day].packages.length - 1; i >= 0; i--){
                        if(holderTokens[_owner][year][month][day].packages[i].lockedUntil > now)
                            amount = amount.add(holderTokens[_owner][year][month][day].packages[i].amount);
                        else
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

    function removeTokenData(address _owner, uint256 amount) private returns (bool){
        uint256 _amount = amount;
        bool flag = false;

        if(holderYears[_owner].length > 0){
            for(uint yearIndex = 0; yearIndex < holderYears[_owner].length; yearIndex++){
                uint year = holderYears[_owner][yearIndex];
                
                if(holderMonths[_owner][year].length > 0){
                    for(uint monthIndex = 0; monthIndex < holderMonths[_owner][year].length; monthIndex++){
                        uint month = holderMonths[_owner][year][monthIndex];

                        if(holderDays[_owner][year][month].length > 0){
                            for(uint dayIndex = 0; dayIndex < holderDays[_owner][year][month].length; dayIndex++){
                                uint day = holderDays[_owner][year][month][dayIndex];

                                uint packageLength = holderTokens[_owner][year][month][day].packages.length;
                                if(packageLength > 0){
                                    bool packageFlag = true;
                                    uint packageIndex = 0;

                                    while(packageFlag){
                                        if(packageIndex >= packageLength)
                                            packageFlag = false;
                                        else{
                                            Package memory _package = holderTokens[_owner][year][month][day].packages[packageIndex];

                                            if(_package.lockedUntil <= now && _amount > 0){
                                                if(_package.amount > _amount){
                                                    _amount = 0;
                                                    _package.amount = _package.amount.sub(_amount);
                                                    
                                                    /* Adjust Package Amount */
                                                    holderTokens[_owner][year][month][day].packages[packageIndex].amount = _package.amount;

                                                    /* Adjust Package Day Amount */
                                                    holderTokens[_owner][year][month][day].amount = holderTokens[_owner][year][month][day].amount.sub(_amount);

                                                    packageFlag = false;
                                                    flag = true;
                                                }else{
                                                    _amount = _amount.sub(_package.amount);

                                                    /* remove the element */
                                                    removePackageByIndex(_owner, year, month, day, packageIndex);
                                                }
                                            }else{
                                                packageFlag = false;
                                                flag = true;
                                            }
                                        }
                                    }
                                }

                                if(flag)
                                    break;
                            }
                        }

                        if(flag)
                            break;
                    }    
                }

                if(flag)
                    break;
            } // End For
        } // End If

        return true;
    }

    function removePackageByIndex(address _owner, uint _year, uint _month, uint _day, uint _index) private returns (bool){
        uint length = holderTokens[_owner][_year][_month][_day].packages.length;

        if(_index < length){
            uint256 amount = holderTokens[_owner][_year][_month][_day].amount;

            if(_index != length - 1){
                for(uint i = _index; i < length - 1; i++){
                    holderTokens[_owner][_year][_month][_day].packages[i] = holderTokens[_owner][_year][_month][_day].packages[i+1];
                }
            }

            delete holderTokens[_owner][_year][_month][_day].packages[length - 1];
            holderTokens[_owner][_year][_month][_day].packages.length--;

            /* Adjust Package Day amount */
            holderTokens[_owner][_year][_month][_day].amount = holderTokens[_owner][_year][_month][_day].amount.sub(amount);

            /* Check and Adjust Year, Month, Day variables */
            if(holderTokens[_owner][_year][_month][_day].packages.length == 0 || holderTokens[_owner][_year][_month][_day].amount == 0){
                delete holderTokens[_owner][_year][_month][_day];

                removeDayByValue(_owner, _year, _month, _day);
                if(holderDays[_owner][_year][_month].length == 0){
                    delete holderDays[_owner][_year][_month];

                    removeMonthByValue(_owner, _year, _month);
                    if(holderMonths[_owner][_year].length == 0){
                        delete holderMonths[_owner][_year];

                        removeYearByValue(_owner, _year);
                        if(holderYears[_owner].length == 0)
                            delete holderYears[_owner];
                    }
                }
            }
        }

        return true;
    }

    function removeYearByValue(address _owner, uint _year) private returns (bool){
        uint length = holderYears[_owner].length;

        if(length > 0){
            uint index = getYearIndex(_owner, _year);

            if(index >= 0 && index < length){
                if(index != length - 1){
                    for(uint i = index; i < length - 1; i++){
                        holderYears[_owner][i] = holderYears[_owner][i+1];
                    }
                }

                delete holderYears[_owner][length - 1];
                holderYears[_owner].length--;
            }
        }   
    }

    function removeMonthByValue(address _owner, uint _year, uint _month) private returns (bool){
        uint length = holderMonths[_owner][_year].length;

        if(length > 0){
            uint index = getMonthIndex(_owner, _year, _month);

            if(index >= 0 && index < length){
                if(index != length - 1){
                    for(uint i = index; i < length - 1; i++){
                        holderMonths[_owner][_year][i] = holderMonths[_owner][_year][i+1];
                    }
                }

                delete holderMonths[_owner][_year][length - 1];
                holderMonths[_owner][_year].length--;
            }
        }

        return true;
    }

    function removeDayByValue(address _owner, uint _year, uint _month, uint _day) private returns (bool){
        uint length = holderDays[_owner][_year][_month].length;

        if(length > 0){
            uint index = getDayIndex(_owner, _year, _month, _day);

            if(index >= 0 && index < length){
                if(index != length - 1){
                    for(uint i = index; i < length - 1; i++){
                        holderDays[_owner][_year][_month][i] = holderDays[_owner][_year][_month][i+1];
                    }
                }

                delete holderDays[_owner][_year][_month][length - 1];
                holderDays[_owner][_year][_month].length--;
            }
        }

        return true;
    }

    function addTokenData(address _owner, uint256 amount, uint timestamp) private returns (bool){
        uint year = getYear(timestamp);
        uint month = getMonth(timestamp);
        uint day = getDay(timestamp);

        /* Year doesn't exist */
        if(getYearIndex(_owner, year) == holderYears[_owner].length)
            holderYears[_owner].push(year);

        /* Month doesn't exist */
        if(getMonthIndex(_owner, year, month) == holderMonths[_owner][year].length)
            holderMonths[_owner][year].push(month);

        /* Day doesn't exist */
        if(getDayIndex(_owner, year, month, day) == holderDays[_owner][year][month].length)
            holderDays[_owner][year][month].push(day);
    
        uint lockTime = timestamp + 2 * 365 * 1 days;

        /* Saving Tokens to the variable */
        holderTokens[_owner][year][month][day].amount.add(amount);
        holderTokens[_owner][year][month][day].packages.push(Package(amount, timestamp, lockTime));
    }

    /* Get the index of the year from variable */
    function getYearIndex(address _owner, uint year) private view returns (uint) {
        uint length = holderYears[_owner].length;
        uint index = 0;

        if(length == 0)
            return length;

        while(holderYears[_owner][index] != year || index < length){
            index++;
        }
        
        return index;
    }

    /* Get the index of the month from variable */
    function getMonthIndex(address _owner, uint year, uint month) private view returns (uint) {
        uint length = holderMonths[_owner][year].length;
        uint index = 0;

        if(length == 0)
            return length;

        while(holderMonths[_owner][year][index] != month || index < length){
            index++;
        }

        return index;
    }

    /* Get the index of the day from variable */
    function getDayIndex(address _owner, uint year, uint month, uint day) private view returns (uint) {
        uint length = holderDays[_owner][year][month].length;
        uint index = 0;

        if(length == 0)
            return length;

        while(holderDays[_owner][year][month][index] != day || index < length){
            index++;
        }

        return index;
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint256 _amount, bytes _data) onlyUnlocked(_amount) public returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);

        bool result = false;
        if(isContract(_to))
            result = transferToContract(_to, _amount, _data);
        else
            result = transferToAddress(_to, _amount, _data);

        if(result){
            removeTokenData(msg.sender, _amount);
            addTokenData(_to, _amount, now);
        }

        return result;
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _amount) public returns (bool) {      
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
        if (balanceOf(msg.sender) < _amount) revert();
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _amount, bytes _data) private returns (bool){
        if (balanceOf(msg.sender) < _amount) revert();
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        ERC223_ContractReceiver receiver = ERC223_ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _amount, _data);
        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }
}