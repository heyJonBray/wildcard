// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/BalanceManager.sol";

contract DeployBalanceManager is Script {

    address public ownerAddress = 0x0000000000000000000000000000000000000000;
    function run() external {
        // load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy contract
        BalanceManager balanceManager = new BalanceManager(ownerAddress);

        // add initial admins if needed
        // balanceManager.addAdmin(adminAddress);

        vm.stopBroadcast();
        console.log("BalanceManager deployed at:", address(balanceManager));
    }
}
