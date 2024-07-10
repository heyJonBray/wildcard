// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BalanceManager is Ownable {
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) public admins;

    // check if caller is admin
    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not an admin");
        _;
    }

    // prevent contract itself from being the user
    modifier notContract(address user) {
        require(user != address(this), "Contract cannot be the user");
        _;
    }

    // events to log balance changes
    event BalanceSet(address indexed user, address indexed token, uint256 balance);
    event BalanceIncreased(address indexed user, address indexed token, uint256 amount);
    event BalanceClaimed(address indexed user, address indexed token, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Funded(address indexed token, uint256 amount);

    // function to allow owner to add admin role
    function addAdmin(address admin) external onlyOwner {
        admins[admin] = true;
        emit AdminAdded(admin);
    }

    // function to allow owner to remove admin role
    function removeAdmin(address admin) external onlyOwner {
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    // function to allow admin to set balance
    function setBalance(address user, address token, uint256 amount) external onlyAdmin notContract(user) {
        require(user != address(0), "Invalid user address");
        require(token != address(0), "Invalid token address");
        balances[user][token] = amount;
        emit BalanceSet(user, token, amount);
    }

    // function to allow admin to increase balance
    function increaseBalance(address user, address token, uint256 amount) external onlyAdmin notContract(user) {
        require(user != address(0), "Invalid user address");
        require(token != address(0), "Invalid token address");
        balances[user][token] += amount;
        emit BalanceIncreased(user, token, amount);
    }

    // function to allow admin to fund contract
    function fund(address token, uint256 amount) external onlyAdmin {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Funded(token, amount);
    }

    // function to allow user to claim balance
    function claim(address token) external notContract(msg.sender) {
        require(token != address(0), "Invalid token address");
        uint256 balance = balances[msg.sender][token];
        require(balance > 0, "No balance available");
        // reset balance before transfer to avoid reentrancy
        balances[msg.sender][token] = 0;
        emit BalanceClaimed(msg.sender, token, balance);
        IERC20(token).transfer(msg.sender, balance);
    }
}
