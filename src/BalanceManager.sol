// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BalanceManager is Ownable, ReentrancyGuard {
    mapping(address => bool) public admins;
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => uint256) public totalBalances;

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
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event BalanceSet(address indexed user, address indexed token, uint256 balance);
    event BalanceIncreased(address indexed user, address indexed token, uint256 amount);
    event BalanceReduced(address indexed user, address indexed token, uint256 amount);
    event BalanceClaimed(address indexed user, address indexed token, uint256 amount);
    event Funded(address indexed token, uint256 amount);
    event TokensWithdrawn(address indexed token, uint256 amount, address indexed to);

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

        uint256 currentBalance = balances[user][token];
        if (amount > currentBalance) {
            totalBalances[token] += (amount - currentBalance);
        } else {
            totalBalances[token] -= (currentBalance - amount);
        }

        balances[user][token] = amount;
        emit BalanceSet(user, token, amount);
    }

    // function to allow admin to increase balance
    function increaseBalance(address user, address token, uint256 amount) external onlyAdmin notContract(user) {
        require(user != address(0), "Invalid user address");
        require(token != address(0), "Invalid token address");

        balances[user][token] += amount;
        totalBalances[token] += amount;
        emit BalanceIncreased(user, token, amount);
    }

    // function to allow admin to reduce balance
    function reduceBalance(address user, address token, uint256 amount) external onlyAdmin notContract(user) {
        require(user != address(0), "Invalid user address");
        require(token != address(0), "Invalid token address");
        require(balances[user][token] >= amount, "Insufficient balance");

        balances[user][token] -= amount;
        totalBalances[token] -= amount;
        emit BalanceReduced(user, token, amount);
    }

    // function to allow admin to fund contract
    function fund(address token, uint256 amount) external onlyAdmin {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Funded(token, amount);
    }

    // function to allow user to claim balance
    function claim(address token) external notContract(msg.sender) nonReentrant {
        require(token != address(0), "Invalid token address");
        uint256 balance = balances[msg.sender][token];
        require(balance > 0, "No balance available");
        
        balances[msg.sender][token] = 0;
        totalBalances[token] -= balance;
        emit BalanceClaimed(msg.sender, token, balance);
        IERC20(token).transfer(msg.sender, balance);
    }

    // function to allow owner to withdraw stuck tokens
    function withdrawExcessTokens(address token, uint256 amount, address to) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");

        uint256 availableAmount = IERC20(token).balanceOf(address(this)) - totalBalances[token];
        require(amount <= availableAmount, "Insufficient excess token balance");

        IERC20(token).transfer(to, amount);
        emit TokensWithdrawn(token, amount, to);
    }
}
