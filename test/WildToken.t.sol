// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WildToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WildTokenTest is Test {
    WildToken token;
    address owner = address(this); // set the owner to the test contract
    address user = address(2);
    ERC20 otherToken;

    function setUp() public {
        // to test on live network
        // forge test --rpc-url $BASE_RPC_URL --chain-id 8453 -vv
        uint256 mintingAllowedAfter = block.timestamp + 365 days;
        token = new WildToken(mintingAllowedAfter);
        otherToken = new ERC20("OtherToken", "OTK");
        console.log("Setup completed. Owner address: %s, User address: %s", owner, user);
    }

    function testInitialSupply() public {
        uint256 initialSupply = 1_000_000_000 * 10 ** token.decimals();
        console.log("Testing Initial Supply");
        console.log("Expected initial supply: %s", initialSupply);
        console.log("Actual initial supply: %s", token.totalSupply());
        assertEq(token.totalSupply(), initialSupply);
        console.log("Expected owner balance: %s", initialSupply);
        console.log("Actual owner balance: %s", token.balanceOf(owner));
        assertEq(token.balanceOf(owner), initialSupply);
    }

    function testInflation() public {
        console.log("Testing Inflation");
        // fast forward 1 year
        vm.warp(block.timestamp + 365 days);
        console.log("Fast forwarded 1 year");

        uint256 initialSupply = token.totalSupply();
        uint256 mintAmount = (initialSupply * 4) / 100;
        console.log("Minting 4%% of the total supply: %s", mintAmount);
        token.mint(owner, mintAmount);

        uint256 expectedSupply = initialSupply + mintAmount;
        console.log("Expected supply after minting 4%%: %s", expectedSupply);
        console.log("Actual supply after minting 4%%: %s", token.totalSupply());
        assertEq(token.totalSupply(), expectedSupply);

        // mint another 1% of the total supply
        mintAmount = (token.totalSupply() * 1) / 100;
        console.log("Minting 1%% of the total supply: %s", mintAmount);
        token.mint(owner, mintAmount);

        expectedSupply += mintAmount;
        console.log("Expected supply after minting another 1%%: %s", expectedSupply);
        console.log("Actual supply after minting another 1%%: %s", token.totalSupply());
        assertEq(token.totalSupply(), expectedSupply);

        // try to mint another 1%, should fail due to cap
        mintAmount = (token.totalSupply() * 1) / 100;
        console.log("Attempting to mint another 1%%, expecting revert due to cap");
        vm.expectRevert(WildToken.MintCapExceeded.selector);
        token.mint(owner, mintAmount);

        // fast forward another year and ensure minting works again
        vm.warp(block.timestamp + 365 days);
        console.log("Fast forwarded another year");
        token.mint(owner, mintAmount);
        expectedSupply += mintAmount;
        console.log("Expected supply after minting another 1%%: %s", expectedSupply);
        console.log("Actual supply after minting another 1%%: %s", token.totalSupply());
        assertEq(token.totalSupply(), expectedSupply);
    }

    function testMintToContractAddressBlocked() public {
        vm.warp(block.timestamp + 365 days);
        uint256 mintAmount = (token.totalSupply() * 1) / 100;

        console.log("Attempting to mint to contract address, expecting revert");
        vm.expectRevert(WildToken.MintToContractAddressBlocked.selector);
        token.mint(address(token), mintAmount);
    }

    function testRecoverTokens() public {
        vm.warp(block.timestamp + 365 days);
        uint256 mintAmount = (token.totalSupply() * 1) / 100;
        token.mint(owner, mintAmount);
        token.transfer(address(token), mintAmount);

        uint256 contractBalanceBefore = token.balanceOf(address(token));
        console.log("Contract balance before recovery: %s", contractBalanceBefore);
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        console.log("Owner balance before recovery: %s", ownerBalanceBefore);

        token.recoverTokens(address(token), mintAmount, owner);

        uint256 contractBalanceAfter = token.balanceOf(address(token));
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        console.log("Contract balance after recovery: %s", contractBalanceAfter);
        console.log("Owner balance after recovery: %s", ownerBalanceAfter);

        assertEq(contractBalanceAfter, contractBalanceBefore - mintAmount);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + mintAmount);
    }

    function testTotalSupplyAfterInflation() public {
        console.log("Testing Total Supply After Inflation for 5 years");
        for (uint256 year = 1; year <= 5; year++) {
            vm.warp(block.timestamp + 365 days);

            uint256 mintAmount = (token.totalSupply() * 5) / 100;
            token.mint(owner, mintAmount);
            console.log("Year %s - Minted amount: %s", year, mintAmount);
            console.log("Year %s - Total Supply: %s", year, token.totalSupply());
        }
    }

    function testPauseAndUnpause() public {
        console.log("Testing Pause and Unpause");
        token.pause();
        console.log("Contract paused");
        vm.expectRevert("Pausable: paused");
        token.transfer(user, 1);
        token.unpause();
        console.log("Contract unpaused");
        token.transfer(user, 1);
        console.log("Transferred 1 token to user");
        assertEq(token.balanceOf(user), 1);
    }

    function testPauseAndUnpauseByNonOwner() public {
        vm.prank(user);
        console.log("Attempting to pause contract as non-owner, expecting revert");
        vm.expectRevert("Ownable: caller is not the owner");
        token.pause();
    }

    function testPermit() public {
        console.log("Testing Permit Functionality");
        uint256 amount = 1_000_000;
        bytes32 permitHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                address(this),
                user,
                amount,
                token.nonces(address(this)),
                block.timestamp
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(permitHash), address(this));
        token.permit(address(this), user, amount, block.timestamp, v, r, s);
        console.log("Permit granted: Allowance of %s for user", amount);
        assertEq(token.allowance(address(this), user), amount);
    }

    function testDelegationAndVoting() public {
        console.log("Testing Delegation and Voting");
        token.delegate(user);
        console.log("Owner delegated votes to user");
        assertEq(token.delegates(owner), user);
        uint256 initialVotes = token.getVotes(user);
        console.log("Initial votes for user: %s", initialVotes);
        token.transfer(user, 100);
        console.log("Transferred 100 tokens to user");
        assertEq(token.getVotes(user), initialVotes + 100);
    }

    function testTransferOwnership() public {
        console.log("Testing Ownership Transfer");
        token.transferOwnership(user);
        console.log("Ownership transferred to user");
        vm.prank(user);
        token.pause();
        console.log("Contract paused by new owner");
        vm.prank(owner);
        vm.expectRevert("Ownable: caller is not the owner");
        token.unpause();
    }

    function testTokenTransfers() public {
        console.log("Testing Token Transfers");
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        console.log("Owner balance before transfer: %s", ownerBalanceBefore);
        token.transfer(user, 100);
        console.log("Transferred 100 tokens to user");
        assertEq(token.balanceOf(user), 100);
        console.log("User balance after transfer: %s", token.balanceOf(user));
        assertEq(token.balanceOf(owner), ownerBalanceBefore - 100);
        console.log("Owner balance after transfer: %s", token.balanceOf(owner));
    }

    function testRecoverOtherToken() public {
        console.log("Testing Recover Other Token");
        otherToken.transfer(address(token), 100);
        console.log("Transferred 100 OtherToken to contract");
        token.recoverTokens(address(otherToken), 100, owner);
        console.log("Recovered 100 OtherToken from contract to owner");
        assertEq(otherToken.balanceOf(owner), 100);
    }

    function testBurnTokens() public {
        console.log("Testing Token Burning");
        uint256 initialSupply = token.totalSupply();
        console.log("Initial total supply: %s", initialSupply);
        token.burn(100);
        console.log("Burned 100 tokens");
        assertEq(token.totalSupply(), initialSupply - 100);
        console.log("Total supply after burning: %s", token.totalSupply());
    }

    function testMintingInThePastReverts() public {
        console.log("Testing Minting in the Past Reverts");
        vm.warp(block.timestamp - 1);
        uint256 mintingAllowedAfter = block.timestamp + 365 days;
        vm.expectRevert(WildToken.MintAllowedAfterDeployOnly.selector);
        token = new WildToken(mintingAllowedAfter);
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
