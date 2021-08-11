// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./INFTLock.sol";

contract NFTLock is INFTLock, IERC721Receiver {

    struct NFT {
        uint externalTokenId;
        address tokenContractAddress;
        State state;
    }

    mapping (address => mapping (uint256 => NFT)) tokens;
    mapping (address => uint256) totalTokensByAddress;

    uint256 totalDepositedTokens;

    address private admin;


    /** Stages that every NFT gets trough.
      *   deposited - During this state only lock is allowed.
      *   locked - During this stage tezos wNFT mint is allowed.
      *   wrapMinted - At this stage Tezos wNFT was minted, the unlock is not allowed.
      *   wrapBurned - At this stage Tezos wNFT was burned, the unlock is now allowed.
      *   unlocked - This stage gives owner opportunity to withdraw its NFT.
    */
    enum State { deposited, locked, wrapMinted, wrapBurned, unlocked }

    /** @dev Events
    *
    */
    event TokenLocked(uint256 tokenId, address from);
    event TokenUnlocked(uint256 tokenId, address unlockerAddress);
    event NFTReceived(address contractAddress, uint256 externalTokenId, uint256 internalTokenId, address from);
    event NFTWithdrawn(uint256 tokenId, address to);

    /** @dev Modifiers
    *
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier isDeposited(uint256 internalTokenId) {
        NFT memory token = tokens[msg.sender][internalTokenId];

        require(internalTokenId <= totalTokensByAddress[msg.sender] &&
            ERC721(token.tokenContractAddress).ownerOf(token.externalTokenId) == address(this),
            "NFT Locker: Token must be deposited");
        _;
    }

    /** @dev Constructor
    *
    */
    constructor() {
        admin = msg.sender;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns(bytes4) {

        uint256 totalTokens = totalTokensByAddress[from];
        tokens[from][totalTokens] = NFT(tokenId, msg.sender, State.deposited);
        totalDepositedTokens++;
        totalTokensByAddress[from]++;


        emit NFTReceived(msg.sender, tokenId, totalTokens, from);

        return this.onERC721Received.selector;
    }

    function lockToken(uint256 internalTokenId) external override isDeposited(internalTokenId){

        NFT storage token = tokens[msg.sender][internalTokenId];

        require(token.state == State.locked, "NFT Locker: The token is already locked");

        token.state = State.locked;

        emit TokenLocked(internalTokenId, msg.sender);
    }

    function unlockToken(uint256 internalTokenId) external override isDeposited(internalTokenId) {

        NFT storage token = tokens[msg.sender][internalTokenId];

        require(token.state == State.wrapBurned || token.state == State.locked,
            "NFT Locker: Token must be locked and not present on tezos blockchain");

        token.state == State.unlocked;

        emit TokenUnlocked(internalTokenId, msg.sender);
    }

    function withdraw(uint256 internalTokenId) external override isDeposited(internalTokenId) {

        NFT storage token = tokens[msg.sender][internalTokenId];

        require(token.state == State.unlocked, "NFT Locker: Unlock you token before to withdraw");

        ERC721(token.tokenContractAddress).safeTransferFrom(address(this), msg.sender, token.externalTokenId);

        uint256 totalTokens = totalTokensByAddress[msg.sender];

        // switch NFT positions in order to optimize a gas
        if (internalTokenId != totalTokens - 1) {
            token = tokens[msg.sender][totalTokens - 1];
        }
        totalTokensByAddress[msg.sender]--;
        totalDepositedTokens--;

        emit NFTWithdrawn(internalTokenId, msg.sender);
    }

    function tokenWrapped(address NFTOwner, uint256 internalTokenId) external override onlyAdmin {

        NFT storage token = tokens[NFTOwner][internalTokenId];
        token.state = State.wrapMinted;
    }

    function tokenBurned(address oldNFTOwner, address newNFTOwner, uint256 internalTokenId) external override onlyAdmin {


        NFT storage token = tokens[oldNFTOwner][internalTokenId];

        if (oldNFTOwner != newNFTOwner) {

            uint256 totalTokens = totalTokensByAddress[oldNFTOwner];

            // remove token from an old owner
            if (internalTokenId != totalTokens - 1) {
                token = tokens[oldNFTOwner][totalTokens - 1];
            }
            totalTokensByAddress[oldNFTOwner]--;

            // add token to a new owner
            totalTokens = totalTokensByAddress[newNFTOwner];
            tokens[newNFTOwner][totalTokens] = token;
            totalTokensByAddress[newNFTOwner]++;
        }

        token.state = State.wrapBurned;
    }

    function getUserNFTs() public view returns (
        uint256[] memory externalTokenIds,
        uint256[] memory internalTokenIds,
        address[] memory tokenContractAddresses,
        State[] memory states) {

        uint256 totalTokens = totalTokensByAddress[msg.sender];

        externalTokenIds = new uint[](totalTokens);
        tokenContractAddresses = new address[](totalTokens);
        states = new State[](totalTokens);

        for (uint i = 0; i < totalTokens; i++) {

            NFT memory token = tokens[msg.sender][i];

            externalTokenIds[i] = token.externalTokenId;
            tokenContractAddresses[i] = token.tokenContractAddress;
            states[i] = token.state;

            // internalTokenId is the index of an array
            internalTokenIds[i] = i;
        }

        return (externalTokenIds, internalTokenIds, tokenContractAddresses, states);
    }
}
