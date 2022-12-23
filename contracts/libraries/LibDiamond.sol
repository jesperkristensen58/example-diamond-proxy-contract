// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/******************************************************************************\
* Original Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Jesper Kristensen: modified to be simpler for demonstration purposes.
/******************************************************************************/

library LibDiamond {
    /// Storage slots of this diamond and its facets:
    // load the storage of the diamond contract at a specific location:
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    // each facet gets their own struct to store state into
    bytes32 constant NFT_STORAGE_POSITION = keccak256("diamond.nft.diamond.storage");
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.erc20.diamond.storage");

    struct FacetCut {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut _diamondCut);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    /// Core diamond state:

    // contract ownership:
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(_msgSender() == contractOwner(), "LibDiamond: Must be contract owner");
    }

    // The main function that is used to cut new facets into the diamond (aka add a new contract and its functions to the diamond)
    // Internal function version of diamondCut
    function diamondCut(FacetCut calldata _diamondCut)
    internal
    {
        address facetAddress = _diamondCut.facetAddress;
        bytes4[] memory functionSelectors = _diamondCut.functionSelectors;

        require(functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");

        DiamondStorage storage ds = diamondStorage();

        // where are we at in the selector array under this facet?
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0) { // no selectors have been registered under this facet ever: hence, the facet does not exist; add it:
            enforceHasContractCode(facetAddress, "LibDiamondCut: New facet has no code");
            // store facet address
            ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds.facetAddresses.length;
            ds.facetAddresses.push(facetAddress);
        }

        // add each new incoming function selector to this facet
        for (uint256 selectorIndex; selectorIndex < functionSelectors.length; selectorIndex++) {
            bytes4 selector = functionSelectors[selectorIndex];
            
            // ensure the facet does not already exist:
            address currentFacetAddressIfAny = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(currentFacetAddressIfAny == address(0), "LibDiamondCut: Can't add function that already exists");

            // ADD The function (selector) here:
            // map the selector to the position in the overall selector array and also map it to the facet address
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
            // we track the selectors in an array under the facet address
            ds.facetFunctionSelectors[facetAddress].functionSelectors.push(selector);

            selectorPosition++;
        }
        emit DiamondCut(_diamondCut);
    }

    /** ==================================================================
                            General Diamond Storage Space
    =====================================================================*/

    /**
     * @notice global storage for all facets
     */
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the diamond contract
        address contractOwner;
    }
    
    // access this storage via:
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }


    /** ==================================================================
                            NFT Storage Space
    =====================================================================*/

    /**
     * @notice NFT storage for the NFT facet
     */
    struct NFTStorage {
        mapping(uint256 => address) _owners;
        mapping(address => uint256) _balances;
        mapping(uint256 => address) _tokenApprovals;
    }
    
    // access the nft storage via:
    function nftStorage() internal pure returns (NFTStorage storage ds) {
        bytes32 position = NFT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /** ==================================================================
                            ERC20 Storage Space
    =====================================================================*/

    /**
     * @notice ERC20 storage for the ERC20 facet
     */
    struct ERC20Storage {
        uint256 _totalSupply;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => uint256)) _allowances;
    }
    
    // access the nft storage via:
    function erc20Storage() internal pure returns (ERC20Storage storage ds) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// HELPERS

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}