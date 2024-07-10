// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WildToken} from "../src/WildToken.sol";

contract WildTokenScript is Script {
    WildToken public wildToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Change the parameters as needed
        string memory name = "Wildcard Token";
        string memory symbol = "WILD";
        uint256 initialSupply = 1000 ether;
        address owner = msg.sender;

        wildToken = new WildToken(name, symbol, initialSupply, owner);

        console.log("WildToken deployed to:", address(wildToken));

        vm.stopBroadcast();
    }
}