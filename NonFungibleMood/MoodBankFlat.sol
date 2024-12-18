// Sources flattened with hardhat v2.22.15 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.1.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.1.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interface/IMoodBank.sol

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/core/MoodBank.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.22;
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

    function tokenize(bytes32 moodHash, bool _tokenized) public {
        require(authorized[msg.sender], "Caller not authorized");
        tokenized[moodHash] = _tokenized;
    }

    function isTokenized(bytes32 moodHash) external view returns (bool) {
        return tokenized[moodHash];
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
