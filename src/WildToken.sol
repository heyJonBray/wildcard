// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title Wildcard Token
 * @author [Jon Bray](https://warpcast.com/jonbray.eth)
 * @notice Initial supply: 1,000,000,000
 * @notice Inflation: 5% per year
 */
contract WildToken is ERC20, ERC20Burnable, ERC20Pausable, ERC20Permit, ERC20Votes, Ownable {
    string public constant TOKEN_NAME = "Wildcard";
    string public constant TOKEN_SYMBOL = "WILD";
    uint256 public constant TOKEN_INITIAL_SUPPLY = 1_000_000_000;
    uint32 public constant MINIMUM_TIME_BETWEEN_MINTS = 1 days * 365;
    uint8 public constant MINT_CAP = 5; // 5% per year inflation

    uint256 public mintingAllowedAfter;
    uint256 public lastMintingTime;
    uint256 public mintedThisYear;

    error MintingDateNotReached();
    error MintToZeroAddressBlocked();
    error MintToContractAddressBlocked();
    error MintAllowedAfterDeployOnly(uint256 blockTimestamp, uint256 mintingAllowedAfter);
    error MintCapExceeded();

    constructor(uint256 mintingAllowedAfter_)
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
        ERC20Permit(TOKEN_NAME)
        Ownable(msg.sender)
    {
        if (mintingAllowedAfter_ < block.timestamp) {
            revert MintAllowedAfterDeployOnly(block.timestamp, mintingAllowedAfter_);
        }

        _mint(msg.sender, TOKEN_INITIAL_SUPPLY * 10 ** decimals());
        mintingAllowedAfter = mintingAllowedAfter_;
        lastMintingTime = block.timestamp;
        mintedThisYear = 0;
    }

    /**
     * @dev mint new tokens for inflation mechanic
     * @dev inflation is compound 5% per year max
     * @param to the address of the target account
     * @param amount the number of tokens to be minted
     */
    function mint(address to, uint256 amount) external onlyOwner {
        if (block.timestamp < mintingAllowedAfter) {
            revert MintingDateNotReached();
        }
        // prevent minting to zero address
        if (to == address(0)) {
            revert MintToZeroAddressBlocked();
        }
        // prevent minting to contract address
        if (to == address(this)) {
            revert MintToContractAddressBlocked();
        }

        uint256 currentYear = (block.timestamp - lastMintingTime) / MINIMUM_TIME_BETWEEN_MINTS;

        if (currentYear >= 1) {
            // reset the yearly minting amount if a year has passed
            lastMintingTime = block.timestamp;
            mintedThisYear = 0;
        }

        // calculate the maximum mintable amount based on the current total supply
        uint256 maxMintable = (totalSupply() * MINT_CAP) / 100;

        // ensure the mint amount does not exceed the yearly cap
        if (mintedThisYear + amount > maxMintable) {
            revert MintCapExceeded();
        }

        mintedThisYear += amount;
        _mint(to, amount);
    }

    /**
     * @dev recover tokens sent to the contract address
     * @param token the address of the token to recover
     * @param amount the amount of tokens to recover
     * @param to the address to send the recovered tokens to
     */
    function recoverTokens(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev pause all token transfers
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause all token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // the following functions are overrides required by solidity
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
