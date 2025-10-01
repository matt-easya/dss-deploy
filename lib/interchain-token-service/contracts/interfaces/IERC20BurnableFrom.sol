// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC20BurnableFrom Interface
 * @notice Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableFrom {
    /**
     * @notice Function to burn tokens.
     * @dev Requires the caller to have allowance for `amount` on `from`.
     * Can only be called by the minter address.
     * @param from The address that will have its tokens burnt.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address from, uint256 amount) external;
}
