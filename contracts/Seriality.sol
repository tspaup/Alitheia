pragma solidity ^0.4.24;

import "./BytesToTypes.sol";
import "./TypesToBytes.sol";
import "./SizeOf.sol";

contract Seriality is BytesToTypes, TypesToBytes, SizeOf {}