// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

interface IFeelnStorage {
    function bind(address wallet) external returns (bool);

    function post(
        string[] memory _emojis,
        string[] memory _image,
        string[] memory _notes
    ) external returns (bool);

    function uidWallet(address wallet) external view returns (bool);

    function destroy() external;

    function getWallets() external view returns (address[] memory);

    function getPrimaryWallet() external view returns (address);
}
