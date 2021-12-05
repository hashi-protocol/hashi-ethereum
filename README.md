# :hammer_and_wrench: EXPERIMENTAL VERSION :hammer_and_wrench:

Ethereum smart contracts of the Hashi protocol.
The oracle part has not been implemented yet. Therefore, this code is a Proof of Concept but is far from final protocol.

## BurnableERC721 (Wrapper) Contract

This contract is the Tezos wrapper contract of the protocol. Basically, it is a FA2 Contract with a _burn_ entrypoint, and a _isBurned_ view.

- `mint`: Mint a wrapped NFT on Ethereum. Takes a _recipient_ (address) and a _tokenURI_ (string) as parameters.
- `burn`: Burns the wrapped token. Take a _tokenId_ (uint256) as parameter.

## Locker Contract

This contract implements the locking protocol of Hashi.

- `lockToken` : Deposits and locks a token in the contract. Parameters: _token_, the NFT (_externalTokenId_, _tokenContractAddress_, _depositor_) that we want to lock.

- `unlockToken`: Deletes the NFT from lockedTokenByID, and add it to releasedIds. Requisite to withdraw. Take an _internalTokenId_ (uint256) as parameter.

- `withdraw`: Sends back on Ethereum a token that has been bridged on Tezos, after unlocking it. Take a _internalTokenId_ (uint256) as parameter.
