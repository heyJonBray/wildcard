// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WildToken.sol";

contract WildTokenTest is Test {
    WildToken token;
    address owner = address(1);
    address user = address(2);

    function setUp() public {
        token = new WildToken("Wild Token", "WILD", 1000 ether, owner);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000 ether);
        assertEq(token.balanceOf(owner), 1000 ether);
    }

    function testInflation() public {
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Trigger a token transfer to apply inflation
        vm.prank(owner);
        token.transfer(user, 1 ether);

        uint256 expectedSupply = 1000 ether + (1000 ether * 5) / 100;
        assertEq(token.totalSupply(), expectedSupply);
    }
}
