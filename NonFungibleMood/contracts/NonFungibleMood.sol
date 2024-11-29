// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ONFT721 } from "@layerzerolabs/onft-evm/contracts/onft721/ONFT721.sol";
import { IVisualEngine } from "./interface/IVisualEngine.sol";
import { IMoodBank } from "./interface/IMoodBank.sol";
import { IFungibleMood } from "./interface/IFungibleMood.sol";

contract NonFungibleMood is ONFT721 {
    IFungibleMood public FM;
    IVisualEngine public VE;
    IMoodBank public MB;

    uint256 public immutable chainId;

    bool public connected;
    address public treasury;
    uint256 public tokenIds = 0;
    uint256 public totalSupply = 0;
    uint256 public nativeTokens = 0;

    mapping(uint256 tokenId => bool) public claimed;
    mapping(uint256 tokenId => uint256) public moodIds;
    mapping(uint256 tokenId => uint256) public expansionLevels;

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
        FM = IFungibleMood(_fungibleMood);
        connected = true;
    }

    function setupVisualEngine(address _visualEngine) external onlyOwner {
        VE = IVisualEngine(_visualEngine);
    }

    function setupMoodBank(address _moodBank) external onlyOwner {
        MB = IMoodBank(_moodBank);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /// PUBLIC FUNCTIONS ///

    function mint(bool _payNative, bytes calldata _moodData) public payable returns (uint256) {
        uint256 newTokenId = generateTokenId(tokenIds);
        (uint256 moodId, address receiver, bool tokenized) = premint(_moodData);
        require(receiver != address(0), "No receiver");
        require(!tokenized, "Tokenized");

        bool isPaid;

        if (_payNative) {
            require(msg.value >= price(nativeTokens), "Insufficient fund");
            (isPaid, ) = payable(treasury).call{ value: msg.value }("");
            claimReward(receiver, newTokenId);
            nativeTokens++;
        } else {
            IERC20(address(FM)).transferFrom(msg.sender, address(this), 1 ether);
            FM.burn(address(this), 1 ether);
            isPaid = true;
        }

        if (isPaid) {
            moodIds[newTokenId] = moodId;
            _mint(receiver, newTokenId);
            tokenIds++;
            totalSupply++;
        }

        return newTokenId;
    }

    function premint(bytes calldata _moodData) public returns (uint256, address, bool) {
        (uint256 moodId, address receiver, bool tokenized) = MB.addMood(_moodData);
        return (moodId, receiver, tokenized);
    }

    function price(uint256 supply) public pure returns (uint256) {
        return 1 ether * (supply ** 2);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory metadata = getMetadata(tokenId);
        return metadata;
    }

    function generateTokenId(uint256 _id) public view returns (uint256 result) {
        result = (chainId * 10 ** 11) + _id;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        string memory metadata = VE.generateMetadata(tokenId, ownerOf(tokenId), getMoodId(tokenId));
        return metadata;
    }

    function getMoodId(uint256 tokenId) public view returns (uint256) {
        return moodIds[tokenId];
    }

    function claimReward(address _receiver, uint256 _tokenId) public {
        require(!claimed[_tokenId], "Already claimed");
        claimed[_tokenId] = true;
        FM.claim(_receiver, 1 ether);
    }

    function burn(uint256 _tokenId) external {
        address currentOwner = ownerOf(_tokenId);
        _burn(_tokenId);
        totalSupply--;
        FM.claim(currentOwner, 1 ether);
    }
}
