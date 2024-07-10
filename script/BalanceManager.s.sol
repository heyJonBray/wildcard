// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AllowanceManager} from "../src/AllowanceManager.sol";

contract AllowanceManagerScript is Script {
    AllowanceManager public AllowanceManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        AllowanceManager = new AllowanceManager();

        console.log("AllowanceManager deployed to:", address(AllowanceManager));

        vm.stopBroadcast();
    }
}
