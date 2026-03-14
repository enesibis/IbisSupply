// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title RoleManager
 * @notice Manages role-based access control for IbisSupply
 */
contract RoleManager {
    enum Role {
        NONE,        // 0
        CUSTOMER,    // 1
        RETAILER,    // 2
        LOGISTICS,   // 3
        WAREHOUSE,   // 4
        INSPECTOR,   // 5
        PROCESSOR,   // 6
        PRODUCER,    // 7
        ADMIN        // 8
    }

    mapping(address => Role) private roles;
    address[] private userList;
    address public owner;

    event RoleGranted(address indexed user, Role role);
    event RoleRevoked(address indexed user);

    modifier onlyAdmin() {
        require(roles[msg.sender] == Role.ADMIN, "RoleManager: caller is not admin");
        _;
    }

    constructor() {
        owner = msg.sender;
        roles[msg.sender] = Role.ADMIN;
        userList.push(msg.sender);
        emit RoleGranted(msg.sender, Role.ADMIN);
    }

    function grantRole(address user, Role role) external onlyAdmin {
        require(user != address(0), "Invalid address");
        if (roles[user] == Role.NONE) {
            userList.push(user);
        }
        roles[user] = role;
        emit RoleGranted(user, role);
    }

    function revokeRole(address user) external onlyAdmin {
        require(user != owner, "Owner role cannot be revoked");
        roles[user] = Role.NONE;
        emit RoleRevoked(user);
    }

    function getRole(address user) external view returns (Role) {
        return roles[user];
    }

    function getRoleValue(address user) external view returns (uint8) {
        return uint8(roles[user]);
    }

    function getUserCount() external view returns (uint256) {
        return userList.length;
    }

    function getAllUsers() external view returns (address[] memory) {
        return userList;
    }
}
