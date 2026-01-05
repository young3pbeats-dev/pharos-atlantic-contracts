// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/**
 * @title AuthorizedVault
 * @author Platonas
 * @notice ETH vault with owner-controlled withdrawal permissions
 */
contract AuthorizedVault {
    address public owner;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public authorized;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event AuthorizationSet(address indexed spender, uint256 allowance);
    event AuthorizationRevoked(address indexed spender);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function authorize(address _spender, uint256 _amount) external onlyOwner {
        authorized[_spender] = true;
        allowance[_spender] = _amount;
        emit AuthorizationSet(_spender, _amount);
    }

    function revoke(address _spender) external onlyOwner {
        authorized[_spender] = false;
        allowance[_spender] = 0;
        emit AuthorizationRevoked(_spender);
    }

    function withdraw(uint256 _amount) external onlyAuthorized {
        require(_amount <= allowance[msg.sender], "Exceeds allowance");
        require(address(this).balance >= _amount, "Insufficient balance");

        allowance[msg.sender] -= _amount;
       (bool success, ) = msg.sender.call{value: _amount}("");
require(success, "ETH transfer failed");

        emit Withdrawal(msg.sender, _amount);
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
