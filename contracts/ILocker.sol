// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ILocker {
    function withdraw(uint256 internalTokenId) external;
}
