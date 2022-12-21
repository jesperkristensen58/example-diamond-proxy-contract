/// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice The lobrary files supporting the NFT Facet of the Diamond.
 * The following are the ERC721 functions from the OZ implementation.
 * @author Jesper Kristensen - but copied from the OZ implementation and modified to be used as a facet
 */
library LibERC20 {
    /***************************************************************************************
               Library to support the ERC20 Facet (contracts/facets/ERC20Facet.sol)
    ****************************************************************************************/

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function erc20mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _erc20_beforeTokenTransfer(address(0), account, amount);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds._erc20_totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            ds._erc20_balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _erc20_afterTokenTransfer(address(0), account, amount);
    }

    function erc20balanceOf(address account) internal view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds._erc20_balances[account];   
    }

    function erc20transferFrom(address spender, address from, address to, uint256 amount) internal returns (bool) {
        _erc20_spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function erc20transfer(address to, uint256 amount) internal returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _erc20_beforeTokenTransfer(from, to, amount);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 fromBalance = ds._erc20_balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ds._erc20_balances[from] = fromBalance - amount;
            ds._erc20_balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _erc20_afterTokenTransfer(from, to, amount);
    }

    function erc20approve(address owner, address spender, uint256 amount) internal returns (bool) {
        _erc20_approve(owner, spender, amount);
        return true;
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _erc20_transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _erc20_beforeTokenTransfer(from, to, amount);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 fromBalance = ds._erc20_balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ds._erc20_balances[from] = fromBalance - amount;
            ds._erc20_balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _erc20_afterTokenTransfer(from, to, amount);
    }

    function _erc20_spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = _erc20allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _erc20_approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _erc20allowance(address owner, address spender) internal view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds._erc20_allowances[owner][spender];
    }

    function _erc20_approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds._erc20_allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _erc20_beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _erc20_afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}