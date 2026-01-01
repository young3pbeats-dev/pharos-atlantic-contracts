// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/**
 * @title PharosHello
 * @author Plato
 * @notice Simple hello-world contract deployed on Pharos Atlantic Testnet
 */
contract PharosHello {
    event Hello(address indexed from, string message);

    function sayHello() external {
        emit Hello(msg.sender, "Hello Pharos");
    }
}
