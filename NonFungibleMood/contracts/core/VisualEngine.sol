// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.22;

import { IVisualEngine } from "../interface/IVisualEngine.sol";
import { IMoodBank, Mood } from "../interface/IMoodBank.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Personalized is IVisualEngine, Ownable(msg.sender) {
    using Strings for uint256;

    string public theme = "Personalized";
    string public network;
    IERC20 public moodToken;
    IMoodBank public moodBank;

    constructor(string memory networkName, address _moodbank, address _moodToken) {
        network = networkName;
        moodBank = IMoodBank(_moodbank);
        moodToken = IERC20(_moodToken);
    }

    function generateImage(string[] memory emojis) public pure returns (string memory) {
        string memory texts = generateTextElement(emojis);
        string memory svgImage = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" fill="none" viewBox="0 0 48 48">',
                '<defs><linearGradient id="a" x1="0%" y1="100%" x2="100%" y2="0%"><stop offset="0%" stop-color="red"/><stop offset="100%" stop-color="#2fa9e5"/></linearGradient><linearGradient id="b" x1="0%" y1="100%" x2="100%" y2="0%"><stop offset="0%" stop-color="#c839ee"/><stop offset="100%" stop-color="#f0aa23"/></linearGradient><linearGradient id="c" x1="0%" y1="100%" x2="100%" y2="0%"><stop offset="0%" stop-color="#a8ec31"/><stop offset="100%" stop-color="#ec1a8e"/></linearGradient></defs><path fill="url(#a)" d="M0 0h48v48H0z"><animate attributeName="fill-opacity" values="0;1;0" dur="1s" repeatCount="indefinite"/></path><path fill="url(#b)" d="M0 0h48v48H0z"><animate attributeName="fill-opacity" values="0.5;0;0.5" dur="2s" repeatCount="indefinite"/></path><path fill="url(#c)" d="M0 0h48v48H0z"><animate attributeName="fill-opacity" values="0.5;0;0.5" dur="1.5s" repeatCount="indefinite"/></path>',
                '<g transform="translate(2.5, 2.5) scale(0.9)">',
                texts,
                "</g>",
                "</svg>"
            )
        );

        string memory base64Image = string(
            abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svgImage)))
        );

        return base64Image;
    }

    function generateTextElement(string[] memory emojis) public pure returns (string memory) {
        uint256 gridSize = sqrt(emojis.length);
        uint256 cellWidth = (48 * 1000) / gridSize; // Keep precision by multiplying by 1000
        string memory result = "";

        for (uint256 i = 0; i < emojis.length; i++) {
            uint256 row = i / gridSize;
            uint256 col = i % gridSize;

            // Calculate x and y with decimals
            uint256 x = (col * cellWidth + cellWidth / 2);
            uint256 y = (row * cellWidth + cellWidth / 2);

            // Convert to string with 3 decimal places (manual formatting)
            string memory xStr = string.concat(Strings.toString(x / 1000), ".", Strings.toString((x % 1000) / 100));
            string memory yStr = string.concat(Strings.toString(y / 1000), ".", Strings.toString((y % 1000) / 100));

            result = string.concat(
                result,
                '<text x="',
                xStr,
                '" y="',
                yStr,
                '" fill="#bbb" dominant-baseline="central" font-size="',
                (cellWidth / 1300).toString(),
                '" text-anchor="middle">',
                emojis[i],
                "</text>"
            );
        }

        return result;
    }

    // Helper function to calculate the square root of a number
    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function generateMetadata(uint256 tokenId, address, uint256 moodId) public view returns (string memory) {
        Mood memory mood = moodBank.getMoodById(moodId);

        // generate image
        string memory image = generateImage(mood.emojis);
        string memory externalUrl = string(
            abi.encodePacked("https://degeneratives.art/id/", Strings.toString(tokenId), "?network=", network)
        );

        string memory metadata = string(
            abi.encodePacked(
                '{"name":"MOODART #',
                tokenId.toString(),
                '","description":"", "image": "',
                image,
                '","external_url": "',
                externalUrl,
                '","attributes": [{"trait_type": "MoodID", "value": "',
                moodId.toString(),
                '"},{"trait_type": "Theme", "value": "',
                theme,
                '"},{"trait_type": "Expansion Level", "value": "',
                mood.expansionLevel,
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    function generateEmojis(string[] memory emojis) public pure returns (string memory) {
        bytes memory result = "[";
        for (uint256 i = 0; i < emojis.length; i++) {
            result = abi.encodePacked(result, "'", (emojis[i]), "'");
            if (i < emojis.length - 1) {
                result = abi.encodePacked(result, ", ");
            }
        }
        result = abi.encodePacked(result, "]");
        return string(result);
    }

    function getPrice() external view returns (address, uint256) {
        return (address(moodToken), 0);
    }
}
