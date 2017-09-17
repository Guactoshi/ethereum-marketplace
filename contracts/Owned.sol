pragma solidity 0.4.15;

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }
    
    modifier ownerOnly(){
        require(owner == msg.sender);
        _;
    }
}