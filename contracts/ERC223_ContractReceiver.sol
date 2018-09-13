pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ERC223_ContractReceiver is Ownable{
	struct TX{
		address sender;
		uint256 value;
		bytes data;
		bytes4 sig;
	}

	function tokenFallback(address _from, uint256 _value, bytes _data) public pure{
		TX memory tran;

		tran.sender = _from;
		tran.value = _value;
		tran.data = _data;
		uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      	tran.sig = bytes4(u);
	}
}