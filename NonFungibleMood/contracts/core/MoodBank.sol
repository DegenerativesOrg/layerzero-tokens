// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IMoodBank, Mood } from "../interface/IMoodBank.sol";

contract MoodBank is Ownable(msg.sender), IMoodBank {
    uint256 public totalMood;

    mapping(address => bool) public authorized;
    mapping(bytes32 => bool) public tokenized;
    mapping(bytes32 => uint256) public tokenizedBy;

    mapping(uint256 => address) public creators;
    mapping(address => Mood[]) public userMoods;
    mapping(address => uint256[]) public moodIds;
    mapping(bytes32 => address[]) public moodUsers;

    mapping(bytes32 => string[]) public hashToMood;
    mapping(bytes32 => uint256[]) public hashToIds;
    mapping(uint256 => bytes32) public idToHash;

    constructor() {}

    /// @notice Adds a new mood to the bank.
    /// @dev Decodes mood data from bytes and stores it.
    /// @param _moodData Bytes data containing encoded mood information (emojis, theme, colors, etc.).
    /// @return newMoodId The ID of the newly added mood.
    /// @return creator The address of the creator who added the mood.
    function addMood(bytes calldata _moodData, bool _tokenize) external payable returns (uint256, address, bool) {
        require(authorized[msg.sender], "Caller not authorized");

        Mood memory mood = decodeMood(_moodData);

        require(mood.creator != address(0), "Zero address");
        require(mood.emojis.length > 0, "No emojis");

        uint256 newMoodId = totalMood;

        userMoods[mood.creator].push(mood);
        creators[newMoodId] = mood.creator;

        // It's unclear what the purpose of moodIds is, as the mood ID can be derived from the
        // index in the userMoods array. If you need to keep it, make sure the logic is correct.
        moodIds[mood.creator].push(newMoodId);

        bytes32 moodHash = hash(mood.emojis); // Use the correct function name (hash instead of _hash)
        moodUsers[moodHash].push(mood.creator);
        idToHash[newMoodId] = moodHash;
        hashToIds[moodHash].push(newMoodId);

        bool alreadyTokenized;
        alreadyTokenized = tokenized[moodHash];

        if (_tokenize) {
            tokenize(moodHash, true);
            tokenizedBy[moodHash] = newMoodId;
        }

        totalMood++;
        return (newMoodId, mood.creator, alreadyTokenized);
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
            address creator
        ) = abi.decode(_moodData, (uint256, uint256, string[], address, string, string, uint8, address));

        return Mood(chainId, timestamp, emojis, themeAddress, bgColor, fontColor, expansionLevel, creator);
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
                _mood.creator
            );
    }

    function authorize(address addr, bool isAuthorized) external onlyOwner {
        authorized[addr] = isAuthorized;
    }

    function tokenize(bytes32 moodHash, bool isTokenized) public {
        require(authorized[msg.sender], "Caller not authorized");
        tokenized[moodHash] = isTokenized;
    }

    /// @notice Gets the mood data for a given mood ID.
    /// @param moodId The ID of the mood.
    /// @return The Mood struct corresponding to the given mood ID.
    function getMoodById(uint256 moodId) external view returns (Mood memory) {
        // Find the creator who owns this moodId
        address creator = creators[moodId];
        require(creator != address(0), "Invalid mood ID");

        Mood[] storage userMoodsArray = userMoods[creator];
        for (uint256 i = 0; i < userMoodsArray.length; i++) {
            if (i == moodId) {
                return userMoodsArray[i];
            }
        }
        revert("Mood not found"); // Revert if no matching mood is found
    }

    function getOwner(uint256 moodId) external view returns (address) {
        return creators[moodId];
    }

    function getMoodLength(uint256 moodId) external view returns (uint256) {
        address creator = creators[moodId];
        require(creator != address(0), "Invalid mood ID");
        Mood[] storage userMoodsArray = userMoods[creator];
        for (uint256 i = 0; i < userMoodsArray.length; i++) {
            if (i == moodId) {
                return userMoodsArray[i].emojis.length;
            }
        }
        revert("Mood not found");
    }

    function getUserMoodLength(address creator) external view returns (uint256) {
        return userMoods[creator].length;
    }

    function getMoodDataByIndex(address creator, uint256 i) external view returns (Mood memory) {
        require(i < userMoods[creator].length, "Index out of bounds"); // Add bounds check
        return userMoods[creator][i];
    }

    function getMoodOfHash(bytes32 moodHash) external view returns (string[] memory) {
        return hashToMood[moodHash];
    }

    function getMoodIdOfHash(bytes32 moodHash) external view returns (uint256[] memory) {
        return hashToIds[moodHash];
    }

    function getHashByMoodId(uint256 moodId) external view returns (bytes32) {
        return idToHash[moodId];
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
