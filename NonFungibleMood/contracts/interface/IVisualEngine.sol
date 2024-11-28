// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.22;

interface IVisualEngine {
    function generateMetadata(uint256, address, uint256) external view returns (string memory);
}
