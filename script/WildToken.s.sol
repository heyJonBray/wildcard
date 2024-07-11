// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WildToken} from "../src/WildToken.sol";

contract WildTokenScript is Script {
    WildToken public wildToken;

    function setUp() public {}

    function run() public {
        // load private key from environment variable
        uint256 devPrivateKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(devPrivateKey);

        uint256 mintingAllowedAfter = block.timestamp + 365 days; // Set the initial minting allowed time

        wildToken = new WildToken(mintingAllowedAfter);

        console.log("WildToken deployed to:", address(wildToken));

        vm.stopBroadcast();
    }
}
