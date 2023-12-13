// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @notice A contract for lazy minting of Fairos NFTs
contract LazyFairosNFT is ERC721, ERC721URIStorage, EIP712 {

    string private constant SIGNING_DOMAIN = "Voucher-Domain";
    string private constant SIGNATURE_VERSION = "1";
    address public minter;

    /// @notice Creates a new LazyFairosNFT contract
    /// @param _minter The address that will be able to mint new tokens
    constructor(address _minter)
        ERC721("LazyFairosNFT", "LFNFT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        minter = _minter;
    }

    /// @notice A voucher for a lazy minted NFT
    struct LazyFairosNFTVoucher {
        uint256 tokenId;
        uint256 price;
        string uri;
        address buyer;
        bytes signature;
    }


    /// @notice Recovers the signer's address from a voucher
    /// @param voucher The voucher to recover the signer from
    /// @return The address of the signer
    function recover(LazyFairosNFTVoucher calldata voucher) public view returns (address) {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("LazyFairosNFTVoucher(uint256 tokenId,uint256 price,string uri,address buyer)"),
        voucher.tokenId,
        voucher.price,
        keccak256(bytes(voucher.uri)),
        voucher.buyer
    )));
    address signer = ECDSA.recover(digest, voucher.signature);
    return signer;
    }

    /// @notice Mints a new NFT if the voucher is valid and the correct amount of ETH is sent
    /// @param voucher The voucher for the NFT
    function safeMint(LazyFairosNFTVoucher calldata voucher)
        public
        payable
    {
        require(minter == recover(voucher), "Wrong signature!");
        require(msg.value >= voucher.price, "Not enough ETH sent!");
        _safeMint(voucher.buyer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    }

    // The following functions are overrides required by Solidity.

    /// @notice Returns the URI for a given token ID
    /// @param tokenId The ID of the token to get the URI for
    /// @return The URI of the token
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Checks if the contract implements an interface given its interface ID
    /// @param interfaceId The ID of the interface to check
    /// @return True if the contract implements the interface, false otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}