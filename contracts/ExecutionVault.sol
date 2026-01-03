// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract ExecutionVault {
    address public owner;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdraw(owner, amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Zero balance");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "ETH transfer failed");

        emit Withdraw(owner, balance);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
