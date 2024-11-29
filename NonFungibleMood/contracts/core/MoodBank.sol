// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IMoodBank, Mood } from "../interface/IMoodBank.sol";

contract MoodBank is Ownable(msg.sender), IMoodBank {
    uint256 public totalMood;

    mapping(address => bool) public authorized;
    mapping(bytes32 => bool) public tokenized;

    mapping(uint256 => address) public owners;
    mapping(address => Mood[]) public userMoods;
    mapping(address => uint256[]) public moodIds;
    mapping(bytes32 => address[]) public moodUsers;

    mapping(bytes32 => string[]) public hashToMood;
    mapping(bytes32 => uint256) public hashToId;

    constructor() {}

    /// @notice Adds a new mood to the bank.
    /// @dev Decodes mood data from bytes and stores it.
    /// @param _moodData Bytes data containing encoded mood information (emojis, theme, colors, etc.).
    /// @return newMoodId The ID of the newly added mood.
    /// @return user The address of the user who added the mood.
    function addMood(bytes calldata _moodData) external payable returns (uint256, address, bool) {
        require(authorized[msg.sender], "Caller not authorized");

        Mood memory mood = decodeMood(_moodData);

        require(mood.user != address(0), "Zero address");
        require(mood.emojis.length > 0, "No emojis");

        uint256 newMoodId = totalMood;

        userMoods[mood.user].push(mood);
        owners[newMoodId] = mood.user;

        // It's unclear what the purpose of moodIds is, as the mood ID can be derived from the
        // index in the userMoods array. If you need to keep it, make sure the logic is correct.
        moodIds[mood.user].push(newMoodId);

        bytes32 moodHash = hash(mood.emojis); // Use the correct function name (hash instead of _hash)
        moodUsers[moodHash].push(mood.user);

        bool isTokenized;
        isTokenized = tokenized[moodHash];
        tokenized[moodHash] = true;

        totalMood++;
        return (newMoodId, mood.user, isTokenized);
    }

    /// @notice Decodes mood data from bytes.
    /// @param _moodData Bytes data containing encoded mood information.
    /// @return A Mood struct containing the decoded mood data.
    function decodeMood(bytes calldata _moodData) public pure returns (Mood memory) {
        (
            uint256 chainId,
            uint256 timestamp,
            string[] memory emojis,
            address themeAddress,
            string memory bgColor,
            string memory fontColor,
            uint8 expansionLevel,
            address user
        ) = abi.decode(_moodData, (uint256, uint256, string[], address, string, string, uint8, address));

        return Mood(chainId, timestamp, emojis, themeAddress, bgColor, fontColor, expansionLevel, user);
    }

    /// @notice Encodes mood data into bytes.
    /// @param _mood The Mood struct containing the mood data to encode.
    /// @return Bytes data containing the encoded mood information.
    function encodeMood(Mood calldata _mood) external pure returns (bytes memory) {
        return
            abi.encode(
                _mood.chainId,
                _mood.timestamp,
                _mood.emojis,
                _mood.themeAddress,
                _mood.bgColor,
                _mood.fontColor,
                _mood.expansionLevel,
                _mood.user
            );
    }

    function authorize(address addr, bool isAuthorized) external onlyOwner {
        authorized[addr] = isAuthorized;
    }

    /// @notice Gets the mood data for a given mood ID.
    /// @param moodId The ID of the mood.
    /// @return The Mood struct corresponding to the given mood ID.
    function getMoodById(uint256 moodId) external view returns (Mood memory) {
        // Find the user who owns this moodId
        address user = owners[moodId];
        require(user != address(0), "Invalid mood ID");

        Mood[] storage userMoodsArray = userMoods[user];
        for (uint256 i = 0; i < userMoodsArray.length; i++) {
            if (i == moodId) {
                return userMoodsArray[i];
            }
        }
        revert("Mood not found"); // Revert if no matching mood is found
    }

    function getOwner(uint256 moodId) external view returns (address) {
        return owners[moodId];
    }

    function getMoodLength(uint256 moodId) external view returns (uint256) {
        address user = owners[moodId];
        require(user != address(0), "Invalid mood ID");
        Mood[] storage userMoodsArray = userMoods[user];
        for (uint256 i = 0; i < userMoodsArray.length; i++) {
            if (i == moodId) {
                return userMoodsArray[i].emojis.length;
            }
        }
        revert("Mood not found");
    }

    function getUserMoodLength(address user) external view returns (uint256) {
        return userMoods[user].length;
    }

    function getMoodDataByIndex(address user, uint256 i) external view returns (Mood memory) {
        require(i < userMoods[user].length, "Index out of bounds"); // Add bounds check
        return userMoods[user][i];
    }

    function getMoodOfHash(bytes32 moodHash) external view returns (string[] memory) {
        return hashToMood[moodHash];
    }

    function getMoodIdOfHash(bytes32 moodHash) external view returns (uint256) {
        return hashToId[moodHash];
    }

    function getMoodUserCount(string[] memory mood) external view returns (uint256) {
        bytes32 moodHash = hash(mood);
        return moodUsers[moodHash].length;
    }

    function getMoodUserByIndex(string[] memory mood, uint256 index) external view returns (address) {
        bytes32 moodHash = hash(mood);
        return moodUsers[moodHash][index];
    }

    function hash(string[] memory characters) public pure returns (bytes32) {
        string memory chars;
        for (uint256 i = 0; i < characters.length; i++) {
            chars = string.concat(chars, characters[i]);
        }
        return keccak256(abi.encodePacked(chars));
    }
}
