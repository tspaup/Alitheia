pragma solidity ^0.4.24;

import "./MintToken.sol";
import "./DateTime.sol";

contract Alitheia is MintToken, DateTime{
    /* Not Minted Tokens */
    struct Package{
        uint256 amount;
        uint timestamp;
        uint lockedUntil;
    }

    /* Minted Tokens */
    struct PackageMinted{
        uint256 amount;
        uint timestamp;
    }

    /* Both of Packages Per Day */
    struct PackageDay{
        uint256 amount;
        Package[] packages;
        PackageMinted[] packagesMinted;
    }

    string public constant symbol = "ALIT";
    string public constant name = "Alitheia";
    uint8 public constant decimals = 18;

    uint256 public unitPrice = (20) * (10 ** 4); // Decimal 4

    /* Balance Variables */
        // Existence
        mapping(address => bool) holderExist;

        // Addresses
        address[] private holders;

        // Address -> Years
        mapping(address => uint[]) private holderYears;

        // Address -> Year -> Months
        mapping(address => mapping (uint => uint[])) private holderMonths;

        // Address -> Year -> Months -> Days
        mapping(address => mapping (uint => mapping (uint => uint[]))) private holderDays;

        // Address -> Year -> Month -> Day -> PackageDay
        mapping(address => mapping (uint => mapping (uint => mapping (uint => PackageDay)))) private holderTokens; 
    /* Balance Variables End */

    /* Interest Variables */
        // Last Paid Year
        mapping(address => uint) private interestYear;

        // Last Paid Month
        mapping(address => uint) private interestMonth;

        // Address -> Year -> Month -> Amount
        mapping(address => mapping (uint => mapping (uint => uint256))) private interestTokens;
    /* Interest Variables End */

    /* Contract Variables */
        // Creation Year
        uint private contractYear;

        // Creation Month
        uint private contractMonth;
    /* Contract Variables End */

    function () public payable {}
    
    // Constructor
    constructor() public{
        bytes memory empty;
        owner = msg.sender;
        balances[owner] = _totalSupply;

        contractYear = getYear(now);
        contractMonth = getMonth(now);

        emit Transfer(0x0, owner, balances[owner], empty);
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

    function addTokenData(address _owner, uint256 amount, uint timestamp, bool _minted) private returns (bool){
        if(!holderExist[_owner]){
            holderExist[_owner] = true;
            holders.push(_owner);
        }

        if(_minted)
            return addMintedTokenData(_owner, amount, timestamp);
        else
            return addNormalTokenData(_owner, amount, timestamp);
    }

    function addMintedTokenData(address _owner, uint256 amount, uint timestamp) private returns (bool){
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
    
        /* Saving Tokens to the variable */
        holderTokens[_owner][year][month][day].amount.add(amount);
        holderTokens[_owner][year][month][day].packagesMinted.push(PackageMinted(amount, timestamp));

        return true;
    }

    function addNormalTokenData(address _owner, uint256 amount, uint timestamp) private returns (bool){
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

        return true;
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
        require(_amount > 0);

        bool minted = false;

        if(msg.sender == owner) // Normal transaction
            minted = false;
        else // Mostly transaction between holders
            minted = true;

        if(isContract(_to)){
            return transferToContract(_to, _amount, _data, minted);
        }else{
            if(transferToAddress(_to, _amount, _data, minted)){
                if(_to == owner)
                    return true;
                else
                    return addTokenData(_to, _amount, now, minted);
            }else
                return false;
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _amount) onlyUnlocked(_amount) public returns (bool) {      
        require(_to != address(0));
        require(_amount > 0);

        bytes memory empty;
        bool minted = false;
        
        if(msg.sender == owner) // Normal transaction
            minted = false;
        else // Mostly transaction between holders
            minted = true;

        if(isContract(_to)){
            return transferToContract(_to, _amount, empty, minted);
        }else{
            if(transferToAddress(_to, _amount, empty, minted)){
                if(_to == owner)
                    return true;
                else
                    return addTokenData(_to, _amount, now, minted);
            }else
                return false;
        }
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool){
        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        if(_to != owner && !isContract(_to))
            addTokenData(_to, _amount, now, true);

        emit Mint(_to, _amount);
        
        bytes memory empty;
        emit Transfer(msg.sender, _to, _amount, empty);
        return true;
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
    function transferToAddress(address _to, uint256 _amount, bytes _data, bool _minted) private returns (bool){
        if(!_minted)
            balances[msg.sender] = balances[msg.sender].sub(_amount);
        
        balances[_to] = balances[_to].add(_amount);

        if(_minted)
            _totalSupply = _totalSupply.add(_amount);

        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _amount, bytes _data, bool _minted) private returns (bool){
        if(!_minted)
            balances[msg.sender] = balances[msg.sender].sub(_amount);
        
        balances[_to] = balances[_to].add(_amount);

        if(_minted)
            _totalSupply = _totalSupply.add(_amount);

        ERC223_ContractReceiver receiver = ERC223_ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _amount, _data);
        
        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }
}