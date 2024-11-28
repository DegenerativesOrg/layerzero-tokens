// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.22;

struct Mood {
    uint256 chainId;
    uint256 timestamp;
    string[] emojis;
    address themeAddress;
    string bgColor;
    string fontColor;
    uint8 expansionLevel;
    address user;
}

interface IMoodBank {
    function addMood(bytes calldata mood) external payable returns (uint256, address);
    function decodeMood(bytes calldata _moodData) external pure returns (Mood memory);
    function encodeMood(Mood calldata _mood) external pure returns (bytes memory);
    function getMoodById(uint256 moodId) external view returns (Mood memory);
    function getOwner(uint256 moodId) external view returns (address);
    function getMoodLength(uint256 moodId) external view returns (uint256);
    function getUserMoodLength(address user) external view returns (uint256);
    function getMoodDataByIndex(address user, uint256 i) external view returns (Mood memory);
    function getMoodOfHash(bytes32 moodHash) external view returns (string[] memory);
    function getMoodIdOfHash(bytes32 moodHash) external view returns (uint256);
    function getMoodUserCount(string[] memory mood) external view returns (uint256);
    function getMoodUserByIndex(string[] memory mood, uint256 index) external view returns (address);
}
