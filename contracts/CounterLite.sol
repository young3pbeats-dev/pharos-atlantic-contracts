// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/**
 * @title CounterLite
 * @author Plato
 * @notice Minimal counter contract for Pharos Atlantic Testnet
 */
contract CounterLite {
    uint256 public counter;
    address public owner;

    event Incremented(uint256 newValue);
    event Reset();

    constructor() {
        owner = msg.sender;
    }

    function increment() external {
        counter += 1;
        emit Incremented(counter);
    }

    function reset() external {
        require(msg.sender == owner, "Not owner");
        counter = 0;
        emit Reset();
    }
}
