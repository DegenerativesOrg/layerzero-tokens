// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ONFT721 } from "@layerzerolabs/onft-evm/contracts/onft721/ONFT721.sol";
import { IVisualEngine } from "./interface/IVisualEngine.sol";
import { IMoodBank, Mood } from "./interface/IMoodBank.sol";
import { IFungibleMood } from "./interface/IFungibleMood.sol";

contract NonFungibleMood is ONFT721 {
    IFungibleMood public FUNGIBLEMOOD;
    IVisualEngine public VISUALENGINE;
    IMoodBank public MOODBANK;

    uint256 public immutable chainId;

    bool public migrating = false;
    bool public connected = false;
    address public treasury;

    uint256 public tokenIds = 0; // token id generation
    uint256 public totalSupply = 0; // tracks token supply
    uint256 public pricedTokens = 0; // tracks priced supply

    mapping(uint256 tokenId => bool) public claimed;
    mapping(uint256 tokenId => uint256) public moodIds;

    constructor(
        address _lzEndpoint,
        address _delegate,
        uint256 _chainId
    ) ONFT721("Non-Fungible Mood", "NFM", _lzEndpoint, _delegate) {
        treasury = _delegate;
        chainId = _chainId;
    }

    /// CORE CONTRACTS ///

    function setupFungibleMood(address _fungibleMood) external onlyOwner {
        require(!connected, "Fungible Mood already connected"); // @note one time init
        FUNGIBLEMOOD = IFungibleMood(_fungibleMood);
        connected = true;
    }

    function setupVisualEngine(address _visualEngine) external onlyOwner {
        VISUALENGINE = IVisualEngine(_visualEngine);
    }

    function setupMoodBank(address _moodBank) external onlyOwner {
        MOODBANK = IMoodBank(_moodBank);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /// PUBLIC FUNCTIONS ///

    function mint(bool payNative, bytes calldata moodData) public payable returns (uint256) {
        uint256 newTokenId = generateTokenId(tokenIds);

        (uint256 moodId, address creator, bool alreadyTokenized) = MOODBANK.addMood(moodData, true);
        require(creator != address(0), "No creator");
        require(!alreadyTokenized, "Tokenized");

        if (payNative) {
            require(msg.value >= price(pricedTokens), "Insufficient fund");
        }

        bool isPaid = _process(creator, newTokenId, payNative);
        require(isPaid, "Payment failed");

        moodIds[newTokenId] = moodId;
        _mint(creator, newTokenId);
        tokenIds++;
        totalSupply++;

        return newTokenId;
    }

    function update(uint256 tokenId, uint256 moodId) public payable returns (uint256) {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        _untokenize(tokenId);

        Mood memory mood = MOODBANK.getMoodById(moodId);
        require(mood.creator == ownerOf(tokenId), "Not creator");

        require(!MOODBANK.isTokenized(MOODBANK.getHashByMoodId(moodId)), "Already tokenized");
        require(_process(mood.creator, tokenId, false), "Payment failed");

        bytes32 moodHash = MOODBANK.getHashByMoodId(moodId);
        MOODBANK.tokenize(moodHash, true);

        // update
        moodIds[tokenId] = moodId;

        return moodId;
    }

    function premint(bytes calldata moodData) public {
        MOODBANK.addMood(moodData, false);
    }

    function migrate(bytes calldata moodData) public payable onlyOwner {
        migrating = true;
        mint(true, moodData);
        migrating = false;
    }

    function price(uint256 supply) public pure returns (uint256) {
        return 1 ether + 10e12 * (supply ** 2);
        // return 0.005 ether + 10e12 * (supply ** 2); // eth/weth as native
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory metadata = getMetadata(tokenId);
        return metadata;
    }

    function generateTokenId(uint256 tokenId) public view returns (uint256 id) {
        id = (chainId * 10 ** 11) + tokenId;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        string memory metadata = VISUALENGINE.generateMetadata(tokenId, ownerOf(tokenId), getMoodId(tokenId));
        return metadata;
    }

    function getMoodId(uint256 tokenId) public view returns (uint256) {
        return moodIds[tokenId];
    }

    function claimReward(address _receiver, uint256 tokenId) public {
        require(!claimed[tokenId], "Already claimed");
        claimed[tokenId] = true;
        FUNGIBLEMOOD.claim(_receiver, 1 ether);
    }

    function burn(uint256 tokenId) external {
        address currentOwner = ownerOf(tokenId);

        require(msg.sender == currentOwner, "Unauthorized burn access");
        _burn(tokenId);
        totalSupply--;

        // drop 1 Fungible Mood
        FUNGIBLEMOOD.claim(currentOwner, 1 ether);
        _untokenize(tokenId);
    }

    function _untokenize(uint256 tokenId) internal {
        bytes32 moodHash = MOODBANK.getHashByMoodId(getMoodId(tokenId));
        MOODBANK.tokenize(moodHash, false);
    }

    function _process(address creator, uint256 tokenId, bool payNative) internal returns (bool) {
        bool isPaid;

        if (payNative) {
            (isPaid, ) = payable(treasury).call{ value: address(this).balance }("");
            if (!migrating) {
                claimReward(creator, tokenId);
            }
            pricedTokens++;
        } else {
            IERC20(address(FUNGIBLEMOOD)).transferFrom(msg.sender, address(this), 1 ether);
            FUNGIBLEMOOD.burn(address(this), 1 ether);
            isPaid = true;
        }

        return isPaid;
    }
}
