// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error InvalidOp(bytes32 op);
error InvalidTokenId(bytes32 tokenId);
error InvalidTokenAddress(address token);
error InvalidSourceChain(string sourceChain);
error InvalidCdpId(uint256 cdpId);
error CdpNotOwned(bytes32 addressHash, uint256 cdpId);
error InsufficientCollateral(bytes32 addressHash, uint256 cdpId, uint256 requested, uint256 available);
error InsufficientDebt(bytes32 addressHash, uint256 cdpId, uint256 requested, uint256 available);
error InvalidIlk(bytes32 ilk);
error CdpNotSafe(bytes32 addressHash, uint256 cdpId);
error InvalidAmount(uint256 amount);
error InvalidDestination(address destination);
error UnauthorizedAccess(address caller);
error CdpAlreadyExists(bytes32 addressHash, uint256 cdpId);
error InvalidCollateralType(bytes32 ilk);
error TransferFailed(address token, address from, address to, uint256 amount);
