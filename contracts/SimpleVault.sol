// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract SimpleVault {
    address public owner;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(owner, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
