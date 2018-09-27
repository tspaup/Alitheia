pragma solidity ^0.4.24;

import "./ERC223_ContractReceiver.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract AlitheiaRestrictedToken is ERC223_ContractReceiver{
  using SafeMath for uint256;

  uint256 internal totalSupply_;
  mapping(address => uint256) internal balances;

  string public constant symbol = "ALITR";
  string public constant name = "AlitheiaRestrictedToken";
  uint public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 0;

  /* Events */
  event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

  constructor () public {
    totalSupply_ = INITIAL_SUPPLY * (10 ** decimals);
    balances[msg.sender] = totalSupply_;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _address) public view returns (uint256) {
    return balances[_address];
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool){
      totalSupply_ = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);

      emit Mint(_to, _amount);
      
      bytes memory empty;
      emit Transfer(msg.sender, _to, _amount, empty);
      return true;
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _address, uint256 _amount) internal{
    require(_amount <= balances[_address]);
    require(_amount > 0);

    bytes memory empty;

    balances[_address] = balances[_address].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);

    emit Burn(_address, _amount);
    emit Transfer(_address, address(0), _amount, empty);
  }
}