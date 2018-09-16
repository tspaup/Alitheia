pragma solidity ^0.4.24;

import "./AlitheiaNonS1.sol";
import "./Arbiter.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract AlitheiaToken is Arbiter{
  using SafeMath for uint256;

  bool public mintingFinished = false;

  uint256 internal totalSupply_;
  mapping(address => uint256) internal balances;

  string public constant symbol = "ALIT";
  string public constant name = "Alitheia";
  uint8 public constant decimals = 18;

  address restrictedAddress;

  /* Events */
  event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  constructor (address _restrictedAddress) public {
    balances[msg.sender] = totalSupply_;

    restrictedAddress = _restrictedAddress;
  }

  function restrictedContract() public view returns (AlitheiaNonS1){
    return AlitheiaNonS1(restrictedAddress);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _address) public view returns (uint256) {
    return balances[_address];
  }

  modifier canMint(){
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission(){
    require(msg.sender == owner);
    _;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool){
      totalSupply_ = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);

      emit Mint(_to, _amount);
      
      bytes memory empty;
      emit Transfer(msg.sender, _to, _amount, empty);
      return true;
  }
}