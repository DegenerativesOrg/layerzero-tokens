// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { NonFungibleMood } from "../NonFungibleMood.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MoodMonday is Ownable(msg.sender), ReentrancyGuard {
    NonFungibleMood public NFM;

    mapping(address => bool) claimed;
    uint256 public rebatesIssued;
    uint256 public maxRebate = 1425 ether;

    constructor() {
        NFM = NonFungibleMood(0x63422EB4a0769323E64b99b227c014174D271baf);
    }

    receive() external payable {}

    function mint(bytes memory moodData) public payable nonReentrant returns (uint256) {
        require(!claimed[msg.sender], "Already claimed");
        uint256 mintPrice = NFM.price(NFM.pricedTokens());

        // Require the user to send the full mint price
        require(msg.value >= mintPrice, "Insufficient funds sent");

        uint256 balance = NFM.balanceOf(msg.sender);

        // Send the full mint price to NFM
        uint256 tokenId = NFM.mint{ value: mintPrice }(true, moodData);

        if (balance == 0) {
            // 100% rebate for new user
            payable(msg.sender).transfer(mintPrice);
        } else {
            // 50% rebate for existing user
            uint256 rebateAmount = mintPrice / 2;
            payable(msg.sender).transfer(rebateAmount);
        }

        claimed[msg.sender] = true;
        return tokenId;
    }

    function updateMaxRebate(uint256 value) external onlyOwner {
        maxRebate = value;
    }

    function recover() external onlyOwner {
        (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
        require(sent, "Failed to recover");
    }
}
