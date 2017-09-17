pragma solidity 0.4.15;

import {Pausable} from './Pausable.sol';

contract Listing is Pausable {
    bytes32 public shortName;
    bytes32 public ipfsDescriptionHash;
    uint public qty;
    uint public price;
    uint public blockExpiration;

    function placeOrder() {
        // TOOD: create order
        revert();
    }

}