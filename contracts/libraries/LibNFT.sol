/// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice The lobrary files supporting the NFT (ERC721) Facet of the Diamond.
 * Note that we are not using separate data spaces for each facet - they all tap into the `libDiamond` global storage space.
 * The following are the ERC721 functions from the OZ implementation.
 * @author Jesper Kristensen - but copied from the OZ implementation and modified to be used as a facet
 */
library LibNFT {
    /***************************************************************************************
               Library to support the NFT Facet (contracts/facets/NFTFacet.sol)
    ****************************************************************************************/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // now define all the functions we want the NFT Facet to use:
    function ownerOf(uint256 tokenId) internal view returns (address) {
        LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();

        address owner = ds._owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");

        LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();
        return ds._balances[owner];
    }

    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");

        LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();
        require(ds._owners[tokenId] == address(0), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);
        
        unchecked {
            ds._balances[to] += 1;
        }

        ds._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete ds._tokenApprovals[tokenId];

        unchecked {
            ds._balances[from] -= 1;
            ds._balances[to] += 1;
        }
        ds._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    function burn(uint256 tokenId) internal {
        LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();

        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);

        // Clear approvals
        delete ds._tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            ds._balances[owner] -= 1;
        }
        delete ds._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal {
        if (batchSize > 1) {
            LibDiamond.NFTStorage storage ds = LibDiamond.nftStorage();

            if (from != address(0)) {
                ds._balances[from] -= batchSize;
            }
            if (to != address(0)) {
                ds._balances[to] += batchSize;
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal {}
}