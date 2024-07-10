// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WildToken.sol";

contract WildTokenTest is Test {
    WildToken token;
    address owner = address(this); // set the owner to the test contract
    address user = address(2);

    function setUp() public {
        uint256 mintingAllowedAfter = block.timestamp + 365 days; // set the initial minting allowed time
        token = new WildToken(mintingAllowedAfter);
    }

    function testInitialSupply() public {
        uint256 initialSupply = 1_000_000_000 * 10 ** token.decimals();
        emit log_named_uint("Initial Supply", initialSupply);
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
    }

    function testInflation() public {
        // fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // mint 2.5% of the total supply
        uint256 mintAmount = (token.totalSupply() * 25) / 1000;
        token.mint(owner, mintAmount);
        uint256 expectedSupply = 1_000_000_000 * 10 ** token.decimals() + mintAmount;
        emit log_named_uint("After first mint - Total Supply", token.totalSupply());
        emit log_named_uint("After first mint - Owner Balance", token.balanceOf(owner));
        assertEq(token.totalSupply(), expectedSupply);

        // mint another 2.5% of the total supply
        token.mint(owner, mintAmount);
        expectedSupply += mintAmount;
        emit log_named_uint("After second mint - Total Supply", token.totalSupply());
        emit log_named_uint("After second mint - Owner Balance", token.balanceOf(owner));
        assertEq(token.totalSupply(), expectedSupply);

        // try to mint another 1%, should fail due to cap
        mintAmount = (token.totalSupply() * 1) / 100;
        vm.expectRevert(WildToken.MintCapExceeded.selector);
        token.mint(owner, mintAmount);

        // fast forward another year and ensure minting works again
        vm.warp(block.timestamp + 365 days);
        token.mint(owner, mintAmount);
        expectedSupply += mintAmount;
        emit log_named_uint("After third mint (new year) - Total Supply", token.totalSupply());
        emit log_named_uint("After third mint (new year) - Owner Balance", token.balanceOf(owner));
        assertEq(token.totalSupply(), expectedSupply);
    }

    function testMintToContractAddressBlocked() public {
        vm.warp(block.timestamp + 365 days);
        uint256 mintAmount = (token.totalSupply() * 1) / 100;

        // try to mint to the contract address, should fail
        vm.expectRevert(WildToken.MintToContractAddressBlocked.selector);
        token.mint(address(token), mintAmount);
    }

    function testRecoverTokens() public {
        // fast forward 1 year
        vm.warp(block.timestamp + 365 days);
        // mint tokens to owner address
        uint256 mintAmount = (token.totalSupply() * 1) / 100;
        token.mint(owner, mintAmount);
        // transfer tokens from owner to contract address
        token.transfer(address(token), mintAmount);
        // recover tokens from the contract address
        uint256 contractBalanceBefore = token.balanceOf(address(token));
        emit log_named_uint("Contract balance before recovery", contractBalanceBefore);
        token.recoverTokens(address(token), mintAmount, owner);
        uint256 contractBalanceAfter = token.balanceOf(address(token));
        emit log_named_uint("Contract balance after recovery", contractBalanceAfter);
        assertEq(contractBalanceAfter, contractBalanceBefore - mintAmount);
        assertEq(token.balanceOf(owner), 1_000_000_000 * 10 ** token.decimals() + mintAmount);
        emit log_named_uint("Owner balance after recovery", token.balanceOf(owner));
    }

    function testTotalSupplyAfterInflation() public {
        for (uint256 year = 1; year <= 5; year++) {
            vm.warp(block.timestamp + 365 days);

            uint256 mintAmount = (token.totalSupply() * 5) / 100;
            token.mint(owner, mintAmount);

            emit log_named_uint(
                string(abi.encodePacked("Year ", uint2str(year), " - Total Supply")),
                token.totalSupply()
            );
        }
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
}
