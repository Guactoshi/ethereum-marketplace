pragma solidity 0.4.15;

import {Pausable} from './Pausable.sol';
import {Listing} from './Listing.sol';

contract Vendor is Pausable {
    bytes32 public shortName;
    address public vendorAddress;
    Listing[] public listings;

    function Vendor(bytes32 _shortName, address _vendorAddress) {
        shortName = _shortName;
        vendorAddress = _vendorAddress;
    }

    function createListing()
        ownerOnly
        notPaused
        returns (bool success) 
    {
        // TOOD: Create listing
        revert();
    }
}