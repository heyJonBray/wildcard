// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BalanceManager.sol";

contract DeployBalanceManager is Script {
    function run() external {
        // Load private key from environment variable or define it here
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the BalanceManager contract
        BalanceManager balanceManager = new BalanceManager();

        // Add initial admins if needed
        // balanceManager.addAdmin(adminAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Optionally log the address of the deployed contract
        console.log("BalanceManager deployed at:", address(balanceManager));
    }
}
