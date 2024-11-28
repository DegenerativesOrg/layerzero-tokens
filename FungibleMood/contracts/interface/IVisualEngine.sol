// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

interface IVisualEngine {
    function generateMetadata(
        uint256 tokenId,
        address owner,
        string[] memory data,
        uint256
    ) external view returns (string memory);
}
