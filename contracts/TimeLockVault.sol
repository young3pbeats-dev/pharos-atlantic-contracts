// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract TimeLockVault {
    address public owner;
    uint256 public unlockTime;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event UnlockTimeUpdated(uint256 newUnlockTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _unlockTime) {
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        require(block.timestamp >= unlockTime, "Vault still locked");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(owner, balance);
    }

    function updateUnlockTime(uint256 newUnlockTime) external onlyOwner {
        require(newUnlockTime > unlockTime, "New unlock must be later");
        unlockTime = newUnlockTime;
        emit UnlockTimeUpdated(newUnlockTime);
    }
}
