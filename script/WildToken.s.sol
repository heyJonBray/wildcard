// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WildToken} from "../src/WildToken.sol";

contract WildTokenScript is Script {
    WildToken public wildToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        uint256 mintingAllowedAfter = block.timestamp + 365 days; // initialize initial mint date

        wildToken = new WildToken(mintingAllowedAfter);

        console.log("WildToken deployed to:", address(wildToken));

        vm.stopBroadcast();
    }
}
