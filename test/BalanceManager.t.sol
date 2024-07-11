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
    MockERC20 mockTokenA;
    MockERC20 mockTokenB;
    MockERC20 mockTokenC;
    address owner;
    address admin1;
    address admin2;
    address user1;
    address user2;

    uint256 threeHundred = 300 * 10 ** 18;
    uint256 fiveHundred = 500 * 10 ** 18;
    uint256 oneThousand = 1000 * 10 ** 18;
    uint256 hundredThousand = 100000 * 10 ** 18;
    
    function setUp() public {
        owner = address(this);
        admin1 = vm.addr(1);
        admin2 = vm.addr(2);
        user1 = vm.addr(3);
        user2 = vm.addr(4);

        // Deploy the BalanceManager contract with the owner address
        balanceManager = new BalanceManager(owner);

        // Deploy the test tokens
        mockTokenA = new MockERC20("Token A", "AMKT");
        mockTokenB = new MockERC20("Token B", "BMKT");
        mockTokenC = new MockERC20("Token C", "CMKT");

        // Mint tokens to the admins
        mockTokenA.mint(admin1, hundredThousand);
        mockTokenA.mint(admin2, hundredThousand);

        mockTokenB.mint(admin1, hundredThousand);
        mockTokenB.mint(admin2, hundredThousand);

        mockTokenC.mint(admin1, hundredThousand);
        mockTokenC.mint(admin2, hundredThousand);

        // Mint tokens to the users
        mockTokenA.mint(user1, hundredThousand);
        mockTokenC.mint(user1, hundredThousand);

        mockTokenB.mint(user2, hundredThousand);

        // Set admin roles
        balanceManager.addAdmin(admin1);
        balanceManager.addAdmin(admin2);

        // Log the token addresses and user/admin addresses
        console.log("Token A address:", address(mockTokenA));
        console.log("Token B address:", address(mockTokenB));
        console.log("Token C address:", address(mockTokenC));
        console.log("Owner address:", owner);
        console.log("Admin1 address:", admin1);
        console.log("Admin2 address:", admin2);
        console.log("User1 address:", user1);
        console.log("User2 address:", user2);
    }

    function testAddRemoveAdmin() public {
        address newAdmin = vm.addr(5);

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
        vm.startPrank(admin1);

        console.log("Initial balance:", balanceManager.balances(user1, address(mockTokenA)));
        balanceManager.setBalance(user1, address(mockTokenA), fiveHundred);
        console.log("Set balance:", fiveHundred);
        assertEq(balanceManager.balances(user1, address(mockTokenA)), fiveHundred, "Balance should be set");
        assertEq(balanceManager.totalBalances(address(mockTokenA)), fiveHundred, "Total balance should be updated");
        console.log("Expected balance:", fiveHundred);
        console.log("Actual balance:", balanceManager.balances(user1, address(mockTokenA)));

        vm.stopPrank();
    }

    function testIncreaseBalance() public {
        vm.startPrank(admin1);

        uint256 initialAmount = 300 * 10 ** 18;
        balanceManager.setBalance(user1, address(mockTokenA), initialAmount);
        console.log("Initial balance for user1:", initialAmount);

        uint256 increaseAmount = 200 * 10 ** 18;
        balanceManager.increaseBalance(user1, address(mockTokenA), increaseAmount);
        console.log("Increase user1 balance by:", increaseAmount);

        uint256 expectedBalance = initialAmount + increaseAmount;
        assertEq(balanceManager.balances(user1, address(mockTokenA)), expectedBalance, "Balance should be increased");
        assertEq(balanceManager.totalBalances(address(mockTokenA)), expectedBalance, "Total balance should be updated");
        console.log("Expected user1 balance:", expectedBalance);
        console.log("Actual user1 balance:", balanceManager.balances(user1, address(mockTokenA)));

        vm.stopPrank();
    }

    function testReduceBalance() public {
        vm.startPrank(admin1);

        uint256 initialAmount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(mockTokenA), initialAmount);
        console.log("Initial balance for user1:", initialAmount);

        uint256 reduceAmount = 200 * 10 ** 18;
        balanceManager.reduceBalance(user1, address(mockTokenA), reduceAmount);
        console.log("Reduce user1 balance by:", reduceAmount);

        uint256 expectedBalance = initialAmount - reduceAmount;
        assertEq(balanceManager.balances(user1, address(mockTokenA)), expectedBalance, "Balance should be reduced");
        assertEq(balanceManager.totalBalances(address(mockTokenA)), expectedBalance, "Total balance should be updated");
        console.log("Expected user1 balance:", expectedBalance);
        console.log("Actual user1 balance:", balanceManager.balances(user1, address(mockTokenA)));

        vm.stopPrank();
    }

function testClaimBalance() public {
    vm.startPrank(admin1);

    uint256 amount = 500 * 10 ** 18;
    balanceManager.setBalance(user1, address(mockTokenA), amount);

    vm.stopPrank();

    // Fund the contract with tokens
    vm.startPrank(user1);
    mockTokenA.approve(address(balanceManager), amount);
    balanceManager.fund(address(mockTokenA), amount);
    console.log("Funded contract with tokens:", amount);
    vm.stopPrank();

    uint256 initialBalance = mockTokenA.balanceOf(user1);
    console.log("Initial User1 Token A balance:", initialBalance);

    vm.startPrank(user1);
    balanceManager.claim(address(mockTokenA));
    uint256 claimedBalance = mockTokenA.balanceOf(user1);
    console.log("User1 claimed Token A balance:", claimedBalance - initialBalance);
    
    assertEq(balanceManager.balances(user1, address(mockTokenA)), 0, "Balance should be claimed");
    assertEq(claimedBalance, initialBalance + amount, "User1 should receive the claimed tokens");
    console.log("User1 final Token A balance:", claimedBalance);

    vm.stopPrank();
}

function testClaimAllBalances() public {
    vm.startPrank(admin1);

    balanceManager.setBalance(user1, address(mockTokenA), fiveHundred); // set token A balance to 500
    balanceManager.setBalance(user1, address(mockTokenC), threeHundred); // set token C balance to 300
    console.log("Token A balance for user1:", fiveHundred);
    console.log("Token C balance for user1:", threeHundred);

    vm.stopPrank();

    // Fund the contract with tokens
    vm.startPrank(user1);
    mockTokenA.approve(address(balanceManager), oneThousand); // approve for more than balance
    mockTokenC.approve(address(balanceManager), oneThousand);
    balanceManager.fund(address(mockTokenA), oneThousand); // fund for more than balance
    balanceManager.fund(address(mockTokenC), oneThousand);
    console.log("Funded contract with Token A:", oneThousand);
    console.log("Funded contract with Token C:", oneThousand);
    vm.stopPrank();

    // Check initial balances
    uint256 initialTokenABalance = mockTokenA.balanceOf(user1);
    uint256 initialTokenCBalance = mockTokenC.balanceOf(user1);
    console.log("Initial User1 Token A balance:", initialTokenABalance);
    console.log("Initial User1 Token C balance:", initialTokenCBalance);

    vm.startPrank(user1);
    balanceManager.claimAll();
    assertEq(balanceManager.balances(user1, address(mockTokenA)), 0, "Balance for Token A should be claimed");
    assertEq(balanceManager.balances(user1, address(mockTokenC)), 0, "Balance for Token C should be claimed");

    uint256 finalTokenABalance = mockTokenA.balanceOf(user1);
    uint256 finalTokenCBalance = mockTokenC.balanceOf(user1);
    console.log("Final User1 Token A balance:", finalTokenABalance);
    console.log("Final User1 Token C balance:", finalTokenCBalance);

    assertEq(finalTokenABalance, initialTokenABalance + fiveHundred, "User1 should receive the claimed Token A");
    assertEq(finalTokenCBalance, initialTokenCBalance + threeHundred, "User1 should receive the claimed Token C");
    console.log("User1 claimed all balances");

    vm.stopPrank();
}


    function testWithdrawExcessTokens() public {
        vm.startPrank(admin1);

        uint256 amount = 500 * 10 ** 18;
        balanceManager.setBalance(user1, address(mockTokenA), amount);

        // Fund the contract with tokens
        mockTokenA.approve(address(balanceManager), amount * 2);
        balanceManager.fund(address(mockTokenA), amount);
        balanceManager.fund(address(mockTokenA), amount);

        uint256 excessAmount = amount;
        balanceManager.withdrawExcessTokens(address(mockTokenA), excessAmount, admin1);
        assertEq(mockTokenA.balanceOf(admin1), excessAmount, "Admin1 should receive the excess tokens");
        console.log("Admin1 withdrew excess tokens:", excessAmount);

        vm.stopPrank();
    }

    function testGetterMethods() public {
        vm.startPrank(admin1);

        uint256 amountA = 500 * 10 ** 18;
        uint256 amountC = 300 * 10 ** 18;
        balanceManager.setBalance(user1, address(mockTokenA), amountA);
        balanceManager.setBalance(user1, address(mockTokenC), amountC);

        vm.stopPrank();

        // Test getBalance
        uint256 balanceA = balanceManager.getBalance(user1, address(mockTokenA));
        uint256 balanceC = balanceManager.getBalance(user1, address(mockTokenC));
        assertEq(balanceA, amountA, "Getter method getBalance should return correct balance for Token A");
        assertEq(balanceC, amountC, "Getter method getBalance should return correct balance for Token C");

        // Test getBalancesForWallet
        (address[] memory tokens, uint256[] memory balances) = balanceManager.getBalancesForWallet(user1);
        assertEq(tokens[0], address(mockTokenA), "First token for user1 should be Token A");
        assertEq(tokens[1], address(mockTokenC), "Second token for user1 should be Token C");
        assertEq(balances[0], amountA, "First balance for user1 should match Token A balance");
        assertEq(balances[1], amountC, "Second balance for user1 should match Token C balance");

        // Test getBalancesForToken
        (address[] memory walletsA, uint256[] memory tokenBalancesA) = balanceManager.getBalancesForToken(address(mockTokenA));
        assertEq(walletsA[0], user1, "First wallet for Token A should be user1");
        assertEq(tokenBalancesA[0], amountA, "Balance for user1 with Token A should match");

        (address[] memory walletsC, uint256[] memory tokenBalancesC) = balanceManager.getBalancesForToken(address(mockTokenC));
        assertEq(walletsC[0], user1, "First wallet for Token C should be user1");
        assertEq(tokenBalancesC[0], amountC, "Balance for user1 with Token C should match");

        // Test getAllTotalBalances
        (address[] memory allTokens, uint256[] memory totalBalances) = balanceManager.getAllTotalBalances();
        assertEq(allTokens[0], address(mockTokenA), "First token in allTokens should be Token A");
        assertEq(totalBalances[0], amountA, "Total balance for Token A should match");
        assertEq(allTokens[1], address(mockTokenC), "Second token in allTokens should be Token C");
        assertEq(totalBalances[1], amountC, "Total balance for Token C should match");

        // Test getAllAdmins
        address[] memory admins = balanceManager.getAllAdmins();
        assertEq(admins[0], admin1, "First admin should be admin1");
        assertEq(admins[1], admin2, "Second admin should be admin2");

        // Test isAdmin
        bool isAdmin1 = balanceManager.isAdmin(admin1);
        bool isAdmin2 = balanceManager.isAdmin(admin2);
        bool isAdmin3 = balanceManager.isAdmin(user1); // should be false
        assertTrue(isAdmin1, "Admin1 should be recognized as admin");
        assertTrue(isAdmin2, "Admin2 should be recognized as admin");
        assertFalse(isAdmin3, "User1 should not be recognized as admin");

        // Test getTokensForUser
        address[] memory user1Tokens = balanceManager.getTokensForUser(user1);
        assertEq(user1Tokens[0], address(mockTokenA), "User1 should have Token A");
        assertEq(user1Tokens[1], address(mockTokenC), "User1 should have Token C");

        // Test getUsersForToken
        address[] memory tokenAUsers = balanceManager.getUsersForToken(address(mockTokenA));
        assertEq(tokenAUsers[0], user1, "Token A should be associated with user1");

        address[] memory tokenCUsers = balanceManager.getUsersForToken(address(mockTokenC));
        assertEq(tokenCUsers[0], user1, "Token C should be associated with user1");

        // Ensure token B associations are correct
        (address[] memory walletsB, uint256[] memory tokenBalancesB) = balanceManager.getBalancesForToken(address(mockTokenB));
        address[] memory user2Tokens = balanceManager.getTokensForUser(user2);

        assertEq(walletsB.length, 0, "Token B should have no associated wallets initially");
        assertEq(user2Tokens.length, 0, "User2 should have no associated tokens initially");
    }
}
