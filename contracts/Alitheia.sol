pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Mint.sol";
import "./DateTime.sol";

contract Alitheia is Mint, DateTime{
    using SafeMath for uint256;

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

    function setUnitPrice(uint256 _unitPrice) public returns (bool){
        unitPrice = _unitPrice;
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

    // Function that is called when a user or another contract wants to transfer funds
    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool){  
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        if(isContract(_to)){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }else
            return transferToAddress(_to, _value, _data);
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        if(isContract(_to))
            return transferToContract(_to, _value, _data);
        else
            return transferToAddress(_to, _value, _data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _value) public returns (bool) {      
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        bytes memory empty;

        if(isContract(_to))
            return transferToContract(_to, _value, empty);
        else
            return transferToAddress(_to, _value, empty);
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
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool){
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool){
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223_ContractReceiver receiver = ERC223_ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
}