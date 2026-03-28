// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.31;

contract PharosAtlanticAccessLayer {

    struct User {
        bool registered;
        uint8 tier;
        uint256 joinedAt;
        string metadata;
    }

    mapping(address => User) private users;
    address[] private userList;

    address public owner;

    event Registered(address indexed user, uint8 tier);
    event TierUpdated(address indexed user, uint8 newTier);
    event MetadataUpdated(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyRegistered() {
        require(users[msg.sender].registered, "Not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(uint8 tier, string calldata metadata) external {
        require(!users[msg.sender].registered, "Already registered");

        users[msg.sender] = User({
            registered: true,
            tier: tier,
            joinedAt: block.timestamp,
            metadata: metadata
        });

        userList.push(msg.sender);

        emit Registered(msg.sender, tier);
    }

    function updateTier(address user, uint8 newTier) external onlyOwner {
        require(users[user].registered, "User not found");
        users[user].tier = newTier;

        emit TierUpdated(user, newTier);
    }

    function updateMetadata(string calldata metadata) external onlyRegistered {
        users[msg.sender].metadata = metadata;

        emit MetadataUpdated(msg.sender);
    }

    function getUser(address user) external view returns (User memory) {
        return users[user];
    }

    function totalUsers() external view returns (uint256) {
        return userList.length;
    }
}
