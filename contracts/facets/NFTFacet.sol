// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.9;

import { LibNFT } from  "../libraries/LibNFT.sol";
import { LibERC20 } from  "../libraries/LibERC20.sol";

/**
 * @notice the NFT Facet contract which will be registered with the Diamond contract as its facet.
 * This contract is stateless and therefore leverages the LibNFT to store state.
 * It also relies on the ERC20 facet so uses that library as well for internal function access.
 * @author Jesper Kristensen
 */
contract NFTFacet {

    function mint(address to, uint256 tokenId) public {
        // call into the library functions to ensure the storage is updated correctly
        LibNFT.mint(to, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return LibNFT.ownerOf(tokenId);
    }
    
    function burn(uint256 tokenId) external {
       LibNFT.burn(tokenId);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return LibNFT.balanceOf(owner);
    }

    function transfer(address to, uint256 tokenId) external {
        LibNFT.transfer(msg.sender, to, tokenId);
    }

    function mintWithERC20(uint256 tokenId) external {
        // mint an NFT via the ERC20 token deployed on another facet

        // approve that this NFT facet uses the tokens minted elsewhere and on another facet:
        // the NFT pings the storage space of the erc20:
        LibERC20.erc20approve(msg.sender, address(this), LibNFT.COST);
        LibERC20.erc20transferFrom(address(this), msg.sender, address(this), LibNFT.COST);

        // now mint the NFT
        mint(_msgSender(), tokenId);
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }
}