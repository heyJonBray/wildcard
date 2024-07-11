// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BalanceManager.sol";

contract DeployBalanceManager is Script {
    function run() external {
        // load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint(process.env.PRIVATE_KEY);
        vm.startBroadcast(deployerPrivateKey);

        // deploy contract
        BalanceManager balanceManager = new BalanceManager();

        // add initial admins if needed
        // balanceManager.addAdmin(adminAddress);

        vm.stopBroadcast();

        // log the address of the deployed contract
        console.log("BalanceManager deployed at:", address(balanceManager));
    }
}
