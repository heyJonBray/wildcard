// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BalanceManager is Ownable, ReentrancyGuard {
    mapping(address => bool) public admins;
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => uint256) public totalBalances;
    mapping(address => address[]) public walletTokens;
    mapping(address => address[]) public tokenWallets;

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

    constructor(address initialOwner) Ownable(initialOwner) {}

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
        if (currentBalance == 0 && amount > 0) {
            walletTokens[user].push(token);
            tokenWallets[token].push(user);
        }

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

        if (balances[user][token] == 0 && amount > 0) {
            walletTokens[user].push(token);
            tokenWallets[token].push(user);
        }

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

    // function to allow any wallet to fund the contract
    function fund(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Funded(token, amount);
    }

    // function to allow user to claim balance
    function claim(address token) public notContract(msg.sender) nonReentrant {
        require(token != address(0), "Invalid token address");
        uint256 balance = balances[msg.sender][token];
        require(balance > 0, "No balance available");

        balances[msg.sender][token] = 0;
        totalBalances[token] -= balance;
        emit BalanceClaimed(msg.sender, token, balance);
        IERC20(token).transfer(msg.sender, balance);
    }

    // function to allow user to claim all balances
    function claimAll() external notContract(msg.sender) nonReentrant {
        uint256 length = walletTokens[msg.sender].length;
        require(length > 0, "No balances available to claim");

        for (uint256 i = 0; i < length; i++) {
            address token = walletTokens[msg.sender][i];
            uint256 balance = balances[msg.sender][token];
            if (balance > 0) {
                balances[msg.sender][token] = 0;
                totalBalances[token] -= balance;
                emit BalanceClaimed(msg.sender, token, balance);
                IERC20(token).transfer(msg.sender, balance);
            }
        }
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

    // get balance for a specific (wallet, token) combo
    function getBalance(address wallet, address token) external view returns (uint256) {
        return balances[wallet][token];
    }

    // get all [token, balance] for a specific wallet
    function getBalancesForWallet(address wallet) external view returns (address[] memory, uint256[] memory) {
        uint256 length = walletTokens[wallet].length;
        address[] memory tokens = new address[](length);
        uint256[] memory balanceValues = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = walletTokens[wallet][i];
            balanceValues[i] = balances[wallet][tokens[i]];
        }
        return (tokens, balanceValues);
    }

    // get all [wallet, balance] for a specific token
    function getBalancesForToken(address token) external view returns (address[] memory, uint256[] memory) {
        uint256 length = tokenWallets[token].length;
        address[] memory wallets = new address[](length);
        uint256[] memory balanceValues = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            wallets[i] = tokenWallets[token][i];
            balanceValues[i] = balances[wallets[i]][token];
        }
        return (wallets, balanceValues);
    }
}
