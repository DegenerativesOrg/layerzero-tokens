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

contract VisualEngine is IVisualEngine, Ownable(msg.sender) {
    using Strings for uint256;

    string public theme = "Personalized";
    string public network;
    IERC20 public FUNGIBLEMOOD;
    IMoodBank public MOODBANK;

    constructor(string memory networkName) {
        network = networkName;
    }

    function setupFungibleMood(address _fungibleMood) external onlyOwner {
        FUNGIBLEMOOD = IERC20(_fungibleMood);
    }

    function setupMoodBank(address _moodBank) external onlyOwner {
        MOODBANK = IMoodBank(_moodBank);
    }

    function generateImage(
        string[] memory emojis,
        string memory bgColor,
        string memory fontColor
    ) public pure returns (string memory) {
        string memory texts = generateTextElement(emojis, fontColor);
        string memory svgImage = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" fill="none" viewBox="0 0 48 48">',
                '<rect width="48" height="48" fill="',
                bgColor,
                '" />',
                texts,
                "</g>"
                "</svg>"
            )
        );

        string memory base64Image = string(
            abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svgImage)))
        );

        return base64Image;
    }

    function generateTextElement(string[] memory emojis, string memory fontColor) public pure returns (string memory) {
        uint256 gridSize = sqrt(emojis.length);
        uint256 cellWidth = (48 * 1000) / gridSize; // Keep precision by multiplying by 1000
        string memory result = string.concat(
            '<g transform="translate(2.5, 2.5) scale(0.9)" dominant-baseline="central" text-anchor="middle" font-family="Arial,sans-serif" font-size="',
            (cellWidth / 1300).toString(),
            '" fill="',
            fontColor,
            '">'
        );

        for (uint256 i = 0; i < emojis.length; i++) {
            uint256 row = i / gridSize;
            uint256 col = i % gridSize;

            // Calculate x and y with decimals
            uint256 x = (col * cellWidth + cellWidth / 2);
            uint256 y = (row * cellWidth + cellWidth / 2);

            // Convert to string with 3 decimal places (manual formatting)
            string memory xStr = string.concat(Strings.toString(x / 1000), ".", Strings.toString((x % 1000) / 100));
            string memory yStr = string.concat(Strings.toString(y / 1000), ".", Strings.toString((y % 1000) / 100));

            result = string.concat(result, '<text x="', xStr, '" y="', yStr, '">', emojis[i], "</text>");
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
        Mood memory mood = MOODBANK.getMoodById(moodId);

        // generate image
        string memory image = generateImage(mood.emojis, mood.bgColor, mood.fontColor);
        string memory traits = generateTraits(uint256(mood.expansionLevel), mood.bgColor, mood.fontColor);
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
                '","attributes": [{"trait_type": "Mood ID", "value": "',
                moodId.toString(),
                '"},{"trait_type": "Theme Name", "value": "',
                theme,
                '"},',
                traits,
                "]}"
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

    function generateTraits(
        uint256 expansionLevel,
        string memory bgColor,
        string memory fontColor
    ) public pure returns (string memory traits) {
        traits = string(
            abi.encodePacked(
                '{"trait_type": "Expansion Level", "value": "',
                uint256(expansionLevel).toString(),
                '"},{"trait_type": "Background Color", "value": "',
                bgColor,
                '"},{"trait_type": "Font Color", "value": "',
                fontColor,
                '"}'
            )
        );
    }

    function getPrice() external view returns (address, uint256) {
        return (address(FUNGIBLEMOOD), 0);
    }
}
