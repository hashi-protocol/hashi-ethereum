// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INFTLock {

    function withdraw(uint256 internalTokenId) external;
    function getUserNFTs() external view returns (
        uint256[] memory externalTokenIds,
        uint256[] memory internalTokenIds,
        address[] memory tokenContractAddresses);
}
