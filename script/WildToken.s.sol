// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WildToken} from "../src/WildToken.sol";

contract WildTokenScript is Script {
    // Base Network
    // simulate with: forge script script/WildToken.s.sol:WildTokenScript --rpc-url $BASE_RPC_URL --chain-id 8453 -vv
    // broadcast to network: forge script script/WildToken.s.sol:WildTokenScript --rpc-url $BASE_RPC_URL --chain-id 8453 -vv --broadcast

    WildToken public wildToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Set the initial minting allowed time
        uint256 mintingAllowedAfter = block.timestamp + 365 days;

        console.log("Deploying WildToken...");
        wildToken = new WildToken(mintingAllowedAfter);

        console.log("WildToken deployed to:", address(wildToken));

        vm.stopBroadcast();
    }
}
