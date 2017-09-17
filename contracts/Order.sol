pragma solidity 0.4.15;

import {Owned} from './Owned.sol';

contract Order is Owned {
    enum State {
        created, shipped, received, reported
    }

    uint public escrow;
    address public customer;
    bytes32 public ipfsInstructionHash;
    uint public blockAutoRelease;

}