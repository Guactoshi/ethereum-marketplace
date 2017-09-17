pragma solidity 0.4.15;

import {Pausable} from './Pausable.sol';
import {Vendor} from './Vendor.sol';

contract Marketplace is Pausable {
    mapping(address => Vendor) public vendors;

    event LogNewVendor(bytes32 shortName, address vendorAddress);

    function registerVendor(bytes32 shortName) 
        notPaused
        returns (Vendor createdVendor)
    {
        require(vendors[msg.sender].owner() == address(0));
        Vendor vendor = new Vendor(shortName, msg.sender);
        vendors[msg.sender] = vendor;
        LogNewVendor(shortName, msg.sender);
        return vendor;
    }

    function toggleVendorPaused(address vendor) 
        ownerOnly
    {
        vendors[vendor].togglePaused();
    }
    
}