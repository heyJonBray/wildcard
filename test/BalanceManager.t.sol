// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BalanceManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18); // Mint initial supply to the deployer
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BalanceManagerTest is Test {
    BalanceManager balanceManager;
    MockERC20 testTokenA;
    MockERC20 testTokenB;
    MockERC20 testTokenC;
    address owner;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        admin = vm.addr(1);
        user1 = vm.addr(2);
        user2 = vm.addr(3);

        // Deploy the BalanceManager contract with the owner address
        balanceManager = new BalanceManager(owner);
        
        // Deploy the test tokens
        testTokenA = new MockERC20("Token A", "ATKN");
        testTokenB = new MockERC20("Token B", "BTKN");
        testTokenC = new MockERC20("Token C", "CTKN");

        // Mint tokens to the admin and test accounts
        uint256 mintAmount = 10000 * 10 ** 18;
        testTokenA.mint(admin, mintAmount);
        testTokenA.mint(user1, mintAmount);
        testTokenA.mint(user2, mintAmount);
        
        testTokenB.mint(admin, mintAmount);
        testTokenB.mint(user1, mintAmount);
        testTokenB.mint(user2, mintAmount);

        testTokenC.mint(admin, mintAmount);
        testTokenC.mint(user1, mintAmount);
        testTokenC.mint(user2, mintAmount);

        // Log the token addresses
        console.log("Test Token A address:", address(testTokenA));
        console.log("Test Token B address:", address(testTokenB));
        console.log("Test Token C address:", address(testTokenC));

        // Set admin role
        balanceManager.addAdmin(admin);

        // Log the addresses
        console.log("Owner:", owner);
        console.log("Admin:", admin);
        console.log("User1:", user1);
        console.log("User2:", user2);
    }

    function testAddRemoveAdmin() public {
        address newAdmin = vm.addr(4);

        // Add new admin
        balanceManager.addAdmin(newAdmin);
        assertTrue(balanceManager.admins(newAdmin), "New admin should be added");
        console.log("Added new admin:", newAdmin);

        // Remove new admin
        balanceManager.removeAdmin(newAdmin);
        assertFalse(balanceManager.admins(newAdmin), "New admin should be removed");
        console.log("Removed new admin:", newAdmin);
    }

    function testSetBalance() public {
        vm.startPrank(admin);

        uint256 amount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(testTokenA), amount);
        assertEq(balanceManager.balances(user1, address(testTokenA)), amount, "Balance should be set");
        assertEq(balanceManager.totalBalances(address(testTokenA)), amount, "Total balance should be updated");

        console.log("Set balance for user1:", amount);

        vm.stopPrank();
    }

    function testIncreaseBalance() public {
        vm.startPrank(admin);

        uint256 initialAmount = 300 * 10 ** 18;
        balanceManager.setBalance(user1, address(testTokenA), initialAmount);

        uint256 increaseAmount = 200 * 10 ** 18;
        balanceManager.increaseBalance(user1, address(testTokenA), increaseAmount);

        uint256 expectedBalance = initialAmount + increaseAmount;
        assertEq(balanceManager.balances(user1, address(testTokenA)), expectedBalance, "Balance should be increased");
        assertEq(balanceManager.totalBalances(address(testTokenA)), expectedBalance, "Total balance should be updated");

        console.log("Increased balance for user1 by:", increaseAmount);

        vm.stopPrank();
    }

    function testReduceBalance() public {
        vm.startPrank(admin);

        uint256 initialAmount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(testTokenA), initialAmount);

        uint256 reduceAmount = 200 * 10 ** 18;
        balanceManager.reduceBalance(user1, address(testTokenA), reduceAmount);

        uint256 expectedBalance = initialAmount - reduceAmount;
        assertEq(balanceManager.balances(user1, address(testTokenA)), expectedBalance, "Balance should be reduced");
        assertEq(balanceManager.totalBalances(address(testTokenA)), expectedBalance, "Total balance should be updated");

        console.log("Reduced balance for user1 by:", reduceAmount);

        vm.stopPrank();
    }

    function testClaimBalance() public {
        vm.startPrank(admin);

        uint256 amount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(testTokenA), amount);

        vm.stopPrank();

        // Fund the contract with tokens
        vm.startPrank(admin);
        testTokenA.transferFrom(admin, address(balanceManager), amount);
        console.log("Funded contract with tokens:", amount);
        vm.stopPrank();

        vm.startPrank(user1);
        balanceManager.claim(address(testTokenA));
        assertEq(balanceManager.balances(user1, address(testTokenA)), 0, "Balance should be claimed");
        assertEq(testTokenA.balanceOf(user1), amount, "User1 should receive the claimed tokens");
        console.log("User1 claimed balance:", amount);

        vm.stopPrank();
    }

    function testWithdrawExcessTokens() public {
        vm.startPrank(admin);

        uint256 amount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(testTokenA), amount);
        testTokenA.transferFrom(admin, address(balanceManager), amount);
        vm.stopPrank();

        uint256 excessAmount = 200 * 10 ** 18;
        vm.startPrank(admin);
        testTokenA.transferFrom(admin, address(balanceManager), excessAmount);
        console.log("Admin funded contract with excess tokens:", excessAmount);
        vm.stopPrank();

        vm.startPrank(owner);
        balanceManager.withdrawExcessTokens(address(testTokenA), excessAmount, owner);
        assertEq(testTokenA.balanceOf(owner), excessAmount, "Owner should receive the excess tokens");
        console.log("Owner withdrew excess tokens:", excessAmount);

        vm.stopPrank();
    }
}
