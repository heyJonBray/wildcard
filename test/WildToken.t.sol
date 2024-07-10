// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WildToken.sol";

contract WildTokenTest is Test {
    WildToken token;
    address owner = address(this); // Set the owner to the test contract
    address user = address(2);

    function setUp() public {
        uint256 mintingAllowedAfter = block.timestamp + 365 days; // Set the initial minting allowed time
        token = new WildToken(mintingAllowedAfter);
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 1_000_000_000 * 10 ** token.decimals());
        assertEq(token.balanceOf(owner), 1_000_000_000 * 10 ** token.decimals());
    }

    function testInflation() public {
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Ensure owner has enough tokens to transfer
        assertEq(token.balanceOf(owner), 1_000_000_000 * 10 ** token.decimals());

        // Trigger a token transfer to apply inflation
        vm.prank(owner);
        token.transfer(user, 1 ether);

        uint256 expectedSupply = 1_000_000_000 * 10 ** token.decimals() + (1_000_000_000 * 10 ** token.decimals() * 5) / 100;
        assertEq(token.totalSupply(), expectedSupply);
    }
}
