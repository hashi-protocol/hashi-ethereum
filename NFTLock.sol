// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./INFTLock.sol";

contract NFTLock is INFTLock, IERC721Receiver {

    struct NFT {
        uint externalTokenId;
        address tokenContractAddress;
        address depositor;
    }

    mapping (uint256 => NFT) lockedTokenById;

    uint256[] releasedIds;

    uint256 totalLockedTokens;

    /** @dev Events
    *
    */
    event TokenLocked(uint256 tokenId, address from);
    event TokenUnlocked(uint256 tokenId, address unlockerAddress);
    event NFTReceived(address contractAddress, uint256 externalTokenId, address from);
    event NFTWithdrawn(uint256 tokenId, address to);

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns(bytes4) {

        emit NFTReceived(msg.sender, tokenId, from);

        NFT memory token = NFT(tokenId, msg.sender, from);
        lockToken(token);

        return this.onERC721Received.selector;
    }

    function lockToken(NFT memory token) internal {

        // find a released id or take a new one
        uint256 internalTokenId;
        if (releasedIds.length > 0) {
            internalTokenId = releasedIds[releasedIds.length - 1];
            delete releasedIds[releasedIds.length - 1];
        } else {
            internalTokenId = totalLockedTokens;
        }

        lockedTokenById[internalTokenId] = token;
        totalLockedTokens++;

        emit TokenLocked(internalTokenId, token.depositor);
    }

    function unlockToken(uint256 internalTokenId) internal {

        releasedIds.push(internalTokenId);
        delete lockedTokenById[internalTokenId];
        totalLockedTokens--;

        emit TokenUnlocked(internalTokenId, msg.sender);
    }

    function withdraw(uint256 internalTokenId) external override {

        NFT storage token = lockedTokenById[internalTokenId];
        address sendTo = token.depositor;

        if (isMintedOnTz(internalTokenId)) {

            address newNFTOwner;
            bool isBurned;

            (isBurned, newNFTOwner) = isBurnedOnTz(internalTokenId);
            require(isBurned, "NFT Locker: Burn your wrapped token before to unlock");
            sendTo = newNFTOwner;
        }

        uint256 externalTokenId = token.externalTokenId;
        ERC721(token.tokenContractAddress).safeTransferFrom(address(this), sendTo, externalTokenId);

        // delete NFT from the storage
        unlockToken(internalTokenId);

        emit NFTWithdrawn(internalTokenId, sendTo);
    }

    //it's a mock of a call to oracle function
    function isMintedOnTz(uint256 internalTokenId) internal pure returns (bool) {
        internalTokenId++;
        return true;
    }

    //it's a mock of a call to oracle function
    function isBurnedOnTz(uint256 internalTokenId) internal pure returns (bool, address) {
        internalTokenId++;
        return (true, address(0));
    }
}
