// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract PharosBadge {
    address public owner;

    struct Badge {
        bool issued;
        uint256 issuedAt;
        string label;
    }

    mapping(address => Badge) public badges;

    event BadgeIssued(address indexed user, string label, uint256 timestamp);
    event BadgeRevoked(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function issueBadge(address _user, string calldata _label) external onlyOwner {
        badges[_user] = Badge({
            issued: true,
            issuedAt: block.timestamp,
            label: _label
        });

        emit BadgeIssued(_user, _label, block.timestamp);
    }

    function revokeBadge(address _user) external onlyOwner {
        delete badges[_user];
        emit BadgeRevoked(_user);
    }

    function hasBadge(address _user) external view returns (bool) {
        return badges[_user].issued;
    }

    function getBadge(address _user) external view returns (Badge memory) {
        return badges[_user];
    }
}
