//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// STEP-1 --------------------------------------------------
// set the NFT contract, using openzepplin. can be setuped with openzeppelin documentation.

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RealEstate is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

// In ETHDaddy app argument for constructer is defined in deployment script
// whereas in this code it is hard coded.
    constructor() ERC721("Real Estate", "REAL") {}

    function mint(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}


// EXPLANATION ---------------------------------------------------------------------------------------------------------------

/*
This Solidity smart contract is called "RealEstate" and is designed to be used as a Non-Fungible Token (NFT) contract. 
It inherits from several OpenZeppelin contracts to provide NFT functionality and extend its capabilities. Below is an explanation of the code:

This is a comment specifying the license under which the code is released. 
In this case, it uses the "Unlicense," which essentially means that the code is released into the public domain without any copyright restrictions.

Pragma Directive: This line specifies the version of the Solidity compiler that should be used. 
In this case, it's set to use Solidity version 0.8.0 or higher.

Import Statements: This contract imports various libraries and contracts from the OpenZeppelin library:

Counters.sol: This library provides a safe way to manage and manipulate counters, often used for generating unique token IDs.
ERC721.sol: This is the OpenZeppelin contract that implements the ERC-721 standard for NFTs.
ERC721URIStorage.sol: This contract extends ERC721 and adds support for token URIs, 
which are often used to associate metadata (e.g., images, descriptions) with NFT tokens.
Contract Declaration: The contract RealEstate is declared, and it inherits from ERC721URIStorage. 
This means that it's an ERC-721 compliant contract with URI storage capabilities for NFT metadata.

Using Counters for Token IDs: The line using Counters for Counters.Counter; imports and uses the Counters library for managing token IDs. 
It creates a private counter variable _tokenIds that will be used to generate unique token IDs.

Constructor: The constructor is called when the contract is deployed. 
It initializes the ERC721 contract with the name "Real Estate" and the symbol "REAL."

mint Function: This function allows users to mint (create) new NFTs. It takes a single argument tokenURI, 
which is a string representing the metadata URI associated with the NFT. Here's what the function does:

It increments the _tokenIds counter, generating a new unique token ID.
It mints a new NFT by calling _mint with the sender's address and the new token ID.
It sets the token's URI using _setTokenURI, associating the metadata URI with the token.
Finally, it returns the newly created token's ID.
totalSupply Function: This function allows anyone to check the total number of tokens that have been minted in this contract. 
It returns the current value of the _tokenIds counter, which represents the total supply of NFTs.

In summary, this Solidity contract provides a basic implementation for minting NFTs representing real estate properties. 
Users can mint new NFTs, each with a unique token ID and associated metadata URI, and the contract keeps track of the total supply of NFTs.
*/