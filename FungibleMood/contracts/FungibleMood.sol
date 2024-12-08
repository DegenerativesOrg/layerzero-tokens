// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { IFungibleMood } from "./interface/IFungibleMood.sol";

/// @title FungibleMood
/// @notice This contract implements a fungible token (MOOD) with cross-chain functionality using LayerZero OFT.
/// It also includes migration functionality from an old token contract.
contract FungibleMood is OFT, IFungibleMood {
    address immutable NONFUNGIBLEMOOD;
    uint256 public immutable MAXTOKENSUPPLY = 100000 * 10 ** 18;

    /// @notice Constructor initializes the OFT contract and sets important addresses.
    /// @param _lzEndpoint Address of the LayerZero endpoint.
    /// @param _delegate Address of the delegate account (likely the owner).
    /// @param _nonFungibleMood Address of the non-fungible MOOD contract.
    constructor(
        address _lzEndpoint,
        address _delegate,
        address _nonFungibleMood
    ) OFT("Fungible Mood", "MOOD", _lzEndpoint, _delegate) Ownable(_delegate) {
        NONFUNGIBLEMOOD = _nonFungibleMood;
    }

    /// @notice Allows the non-fungible MOOD contract to mint new fungible mood tokens.
    /// @param _account Address of the recipient.
    /// @param _value Amount of tokens to mint.
    /// @return True if minting was successful.
    function claim(address _account, uint256 _value) external returns (bool) {
        require(NONFUNGIBLEMOOD == msg.sender, "Only non-fungible mood can issue reward");
        require(totalSupply() + _value <= MAXTOKENSUPPLY, "Max token supply reached");
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
}
