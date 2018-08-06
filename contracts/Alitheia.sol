pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./DateTime.sol";

contract Alitheia is ERC20, DateTime{
    using SafeMath for uint256;

    string public constant symbol = "ALIT";
    string public constant name = "Alitheia";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = (2000) * (10 ** 18); // 2 billion total supply

    // Owner of this contract
    address public owner;
    
    // Balances for each account
    mapping(address => uint256) balances;
  
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) internal allowed;

    // Year -> Month -> Hoder -> Tokens
    mapping(uint => mapping (unit => mapping(address => uint256))) private holderTokens;

    bool public mintingFinished = false;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission(){
        require(msg.sender == owner);
        _;
    }

    function () public payable {}
    
    // Constructor
    function Alitheia() public{
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, balances[owner]);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return remaining uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_owner != address(0));
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     */
    function increaseApproval (address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint256 _value) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_value > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_value);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        uint year = getYear(now)
        uint month = getMonth(now)

        if(holderTokens[year][month][_to] == address(0)){
            holderTokens[year][month][_to] = _value;
        }else{
            holderTokens[year][month][_to] = holderTokens[year][month][_to].add(_value);
        }

        uint256 remaining = _value;

        while(remaining > 0){
            if(holderTokens[year][month][_from] != address(0) && holderTokens[year][month][_from] != 0){
                if(remaining > holderTokens[year][month][_from]){
                    remaining = remaining.sub(holderTokens[year][month][_from]);
                    holderTokens[year][month][_from] = 0;    
                }else{
                    holderTokens[year][month][_from] = holderTokens[year][month][_from].sub(remaining);
                    remaining = 0;
                }
            }

            if(month > 1)
                month--;
            else{
                month = 12;
                year--;
            }
        }

        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to address The address to transfer to.
     * @param _value uint256 The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        uint year = getYear(now);
        uint month = getMonth(now);

        if(holderTokens[year][month][_to] == address(0)){
            holderTokens[year][month][_to] = _value;
        }else{
            holderTokens[year][month][_to] = holderTokens[year][month][_to].add(_value);
        }

        return true;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}