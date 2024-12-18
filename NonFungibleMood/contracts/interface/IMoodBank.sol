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
    address creator;
}

interface IMoodBank {
    function addMood(bytes calldata _moodData, bool _tokenize) external payable returns (uint256, address, bool);
    function decodeMood(bytes calldata _moodData) external pure returns (Mood memory);
    function tokenize(bytes32 moodHash, bool isTokenized) external;
    function isTokenized(bytes32 moodHash) external view returns (bool);
    function encodeMood(Mood calldata _mood) external pure returns (bytes memory);
    function getMoodById(uint256 moodId) external view returns (Mood memory);
    function getOwner(uint256 moodId) external view returns (address);
    function getMoodLength(uint256 moodId) external view returns (uint256);
    function getUserMoodLength(address user) external view returns (uint256);
    function getMoodDataByIndex(address user, uint256 i) external view returns (Mood memory);
    function getMoodOfHash(bytes32 moodHash) external view returns (string[] memory);
    function getMoodIdOfHash(bytes32 moodHash) external view returns (uint256[] memory);
    function getMoodUserCount(string[] memory mood) external view returns (uint256);
    function getHashByMoodId(uint256 moodId) external view returns (bytes32);
    function getMoodUserByIndex(string[] memory mood, uint256 index) external view returns (address);
}
