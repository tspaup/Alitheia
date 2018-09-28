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

  function _burn(address _address, uint256 _amount) internal{
    require(_address != address(0));
    require(_amount <= balances[_address]);
    require(_amount > 0);

    bytes memory empty;

    balances[_address] = balances[_address].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);

    emit Burn(_address, _amount);
    emit Transfer(_address, address(0), _amount, empty);
  }
}