pragma solidity 0.4.15;

import {Owned} from './Owned.sol';

contract Pausable is Owned {
    bool public paused;

    modifier notPaused() {
        require(!paused);
        _;
    }

    function togglePaused() ownerOnly {
        paused = !paused;
    }
}