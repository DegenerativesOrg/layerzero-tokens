// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IFungibleMood {
    function claim(address _account, uint256 _tokenId) external returns (bool);
    function burn(address _account, uint256 _value) external returns (bool);
}
