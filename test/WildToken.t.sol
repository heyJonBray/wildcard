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

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1_000_000_000 * 10 ** token.decimals());
        assertEq(token.balanceOf(owner), 1_000_000_000 * 10 ** token.decimals());
    }

    function testInflation() public {
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Mint 4% of the total supply
        uint256 mintAmount = (token.totalSupply() * 4) / 100;
        token.mint(owner, mintAmount);

        uint256 expectedSupply = 1_000_000_000 * 10 ** token.decimals() + mintAmount;
        assertEq(token.totalSupply(), expectedSupply);

        // Mint another 1% of the total supply
        mintAmount = (token.totalSupply() * 1) / 100;
        token.mint(owner, mintAmount);

        expectedSupply += mintAmount;
        assertEq(token.totalSupply(), expectedSupply);

        // Try to mint another 1%, should fail due to cap
        mintAmount = (token.totalSupply() * 1) / 100;
        vm.expectRevert(WildToken.MintCapExceeded.selector);
        token.mint(owner, mintAmount);

        // Fast forward another year and ensure minting works again
        vm.warp(block.timestamp + 365 days);
        token.mint(owner, mintAmount);
        expectedSupply += mintAmount;
        assertEq(token.totalSupply(), expectedSupply);
    }
}
