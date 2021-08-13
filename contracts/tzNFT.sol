//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract tzNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (address => mapping (uint256 => uint256)) internalIdsByAddress;
    mapping (address => uint256) totalWTokensByAddress;

    /** @dev Events
    *
    */
    event OwnershipRemoved(address from, uint256 tolenId);
    event OwnershipAssigned(address recipient, uint256 tokenId);

    constructor() ERC721("tzNFT", "NFT") {}

    function mintTzNFT(address recipient, string memory tokenURI)
    public
    onlyOwner
    returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        super._mint(recipient, newItemId);
        super._setTokenURI(newItemId, tokenURI);

        assignTokenOwnership(recipient, newItemId);

        return newItemId;
    }

    function burnTzNFT(uint256 tokenId) public {
        super._burn(tokenId);
        removeTokenOwnership(ownerOf(tokenId),tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        removeTokenOwnership(from, tokenId);
        assignTokenOwnership(to, tokenId);
    }

    function removeTokenOwnership(address from, uint256 tokenId) internal {
        uint256 totalTokens = totalWTokensByAddress[from];
        for (uint256 i; i < totalTokens; i++) {
            if (tokenId == internalIdsByAddress[from][i]) {
                delete internalIdsByAddress[from][i];
                break;
            }
        }
        totalWTokensByAddress[from]--;

        emit OwnershipRemoved(from, tokenId);
    }

    function assignTokenOwnership(address recipient, uint256 tokenId) internal {
        uint256 totalTokens = totalWTokensByAddress[recipient];
        internalIdsByAddress[recipient][totalTokens] = tokenId;
        totalWTokensByAddress[recipient]++;

        emit OwnershipAssigned(recipient, tokenId);
    }

    function getUserNFTs() external view returns (
        string[] memory tokenURIs,
        uint256[] memory tokenIds) {

        uint256 totalTokens = totalWTokensByAddress[msg.sender];
        tokenURIs = new string[](totalTokens);
        tokenIds = new uint[](totalTokens);

        for (uint i = 0; i < totalTokens; i++) {

            uint256 tokenId = internalIdsByAddress[msg.sender][i];
            tokenURIs[i] = tokenURI(tokenId);
            tokenIds[i] = tokenId;
        }

        return (tokenURIs, tokenIds);
    }
}
