// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IFungibleMood } from "../interface/IFungibleMood.sol";

/// @title FungibleMood
/// @author Rald Blox | raldblox.eth
/// @notice This contract implements a fungible token (MOOD) with cross-chain functionality using LayerZero OFT.
/// It also includes migration functionality from an old token contract.
contract FungibleMood is ERC20, IFungibleMood, Ownable {
    address immutable NONFUNGIBLEMOOD; // Address of the non-fungible MOOD contract
    address immutable OLDMOOD; // Address of the old MOOD token contract
    uint256 immutable ENDOFMIGRATION = 1735689600; // Jan-01-2025 12:00:00 AM

    /// @notice Constructor initializes the OFT contract and sets important addresses.
    /// @param _lzEndpoint Address of the LayerZero endpoint.
    /// @param _delegate Address of the delegate account (likely the owner).
    /// @param _nonFungibleMood Address of the non-fungible MOOD contract.
    /// @param _moodAddress Address of the old MOOD token contract.
    constructor(
        address _lzEndpoint,
        address _delegate,
        address _nonFungibleMood,
        address _moodAddress
    ) ERC20("Fungible Mood", "MOOD") Ownable(_delegate) {
        NONFUNGIBLEMOOD = _nonFungibleMood;
        OLDMOOD = _moodAddress;
    }

    /// @notice Returns the current block timestamp.
    /// @return The current block timestamp.
    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Allows the non-fungible MOOD contract to mint new fungible mood tokens.
    /// @param _account Address of the recipient.
    /// @param _value Amount of tokens to mint.
    /// @return True if minting was successful.
    function claim(address _account, uint256 _value) external returns (bool) {
        require(NONFUNGIBLEMOOD == msg.sender, "Only non-fungible mood can issue reward");
        _mint(_account, _value);
        return true;
    }

    /// @notice Burns tokens from an account.
    /// @param _account Address of the account to burn tokens from.
    /// @param _value Amount of tokens to burn.
    /// @return True if burning was successful.
    function burn(address _account, uint256 _value) external returns (bool) {
        require(msg.sender == _account || msg.sender == NONFUNGIBLEMOOD, "Unauthorized burn access");
        _burn(_account, _value);
        return true;
    }

    /// @notice Allows users to migrate their tokens from the old MOOD contract.
    /// @dev Burns the old tokens and mints new MOOD tokens at a 1000:1 ratio.
    /// @param _value Amount of old tokens to migrate.
    /// @return True if migration was successful.
    function migrate(uint256 _value) external returns (bool) {
        require(timeNow() > ENDOFMIGRATION, "Migration ended");
        require(IERC20(OLDMOOD).transfer(address(0xdead), _value), "Failed to burn old tokens");
        _mint(msg.sender, (_value / 1000));
        return true;
    }
}
