// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InterchainTokenExecutable} from "interchain-token-service/contracts/executable/InterchainTokenExecutable.sol";
import {InterchainTokenService} from "interchain-token-service/contracts/InterchainTokenService.sol";
import {ERC20} from "interchain-token-service/contracts/interchain-token/ERC20.sol";
import {DssCdpManager} from "dss-cdp-manager/DssCdpManager.sol";
import {
    InvalidOp,
    InvalidTokenId,
    InvalidTokenAddress,
    InvalidSourceChain,
    InvalidCdpId,
    CdpNotOwned,
    InsufficientCollateral,
    InsufficientDebt,
    InvalidIlk,
    CdpNotSafe,
    InvalidAmount,
    InvalidDestination,
    UnauthorizedAccess,
    CdpAlreadyExists,
    InvalidCollateralType,
    TransferFailed
} from "./Errors.sol";

interface VatLike {
    function urns(bytes32, address) external view returns (uint, uint);
    function hope(address) external;
    function flux(bytes32, address, address, uint) external;
    function move(address, address, uint) external;
    function frob(bytes32, address, address, address, int, int) external;
    function fork(bytes32, address, address, int, int) external;
}

interface JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

interface DaiJoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

interface PsmLike {
    function buyGem(address, uint) external;
    function sellGem(address, uint) external;
}

contract Controller is InterchainTokenExecutable {
    // Events
    event CdpOpened(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        bytes32 ilk
    );
    event CollateralDeposited(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        uint256 amount
    );
    event DaiDrawn(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        uint256 amount
    );
    event DaiRepaid(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        uint256 amount
    );
    event CollateralWithdrawn(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        uint256 amount
    );
    event CdpClosed(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId
    );
    event DepositAndSwap(
        bytes indexed sourceAddress,
        bytes32 addressHash,
        uint256 cdpId,
        uint256 xrpAmount,
        uint256 daiAmount,
        uint256 usdcAmount
    );
    event DebugLog(
        bytes32 commandId,
        string sourceChain,
        bytes sourceAddress,
        bytes data,
        bytes32 tokenId,
        address token,
        uint256 amount,
        bytes32 addressHash
    );
    event OpLog(
        bytes32 data
    );
    // Constants
    string constant XRPL_AXELAR_CHAIN_ID = "xrpl";
    
    // Operation constants
    bytes32 constant OP_OPEN_CDP = keccak256("open_cdp");
    bytes32 constant OP_DEPOSIT_COLLATERAL = keccak256("deposit_collateral");
    bytes32 constant OP_DRAW_DAI = keccak256("draw_dai");
    bytes32 constant OP_REPAY_DAI = keccak256("repay_dai");
    bytes32 constant OP_WITHDRAW_COLLATERAL = keccak256("withdraw_collateral");
    bytes32 constant OP_CLOSE_CDP = keccak256("close_cdp");
    bytes32 constant OP_DEPOSIT_AND_SWAP = keccak256("deposit_and_swap");
    bytes32 constant OP_DEBUG_LOG = keccak256("debug_log");

    // State variables
    DssCdpManager public immutable cdpManager;
    VatLike public immutable vat;
    DaiJoinLike public immutable daiJoin;
    PsmLike public psm;
    address public usdcToken;
    
    // Mapping from address hash to CDP ID
    mapping(bytes32 => uint256) public userCdps;
    
    // Mapping from CDP ID to address hash (for reverse lookup)
    mapping(uint256 => bytes32) public cdpOwners;
    
    // Supported collateral types
    mapping(bytes32 => address) public collateralTokens; // ilk => token address
    mapping(bytes32 => address) public collateralJoins;  // ilk => join address
    mapping(address => bytes32) public tokenIlks;        // token => ilk
    
    // Token IDs for interchain transfers
    mapping(bytes32 => bytes32) public ilkTokenIds;      // ilk => token ID
    bytes32 public daiTokenId;
    address public daiToken;

    // Access control
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not-admin");
        _;
    }

    constructor(
        address _interchainTokenService,
        address _cdpManager,
        address _vat,
        address _daiJoin
    ) InterchainTokenExecutable(_interchainTokenService) {
        if (_cdpManager == address(0)) revert InvalidCdpId(0);
        if (_vat == address(0)) revert InvalidCdpId(0);
        if (_daiJoin == address(0)) revert InvalidCdpId(0);

        cdpManager = DssCdpManager(_cdpManager);
        vat = VatLike(_vat);
        daiJoin = DaiJoinLike(_daiJoin);
        admin = msg.sender;

        // Allow the controller to manage CDPs
        vat.hope(_cdpManager);
    }

    function _executeWithInterchainToken(
        bytes32 _commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal virtual override {
        // Validate source chain
        bytes32 addressHash = keccak256(sourceAddress);
        
        // Debug: Check data length and content
        // emit DebugLog(_commandId, sourceChain, sourceAddress, data, tokenId, token, amount, addressHash);
        
        // Data is double-encoded: abi.encode(abi.encode(op, params))
        // First unwrap the outer layer
        (bytes32 opcode, bytes memory params) = abi.decode(data, (bytes32, bytes));
        
        // Now decode the operation and parameters
        // (bytes32 op, bytes memory params) = abi.decode(innerData, (bytes32, bytes));
        
        emit OpLog(opcode);
        
        // // Handle the operation
        // if (op == OP_DEPOSIT_AND_SWAP) {
        //     _depositAndSwap(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_OPEN_CDP) {
        //     _openCdp(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_DEPOSIT_COLLATERAL) {
        //     _depositCollateral(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_DRAW_DAI) {
        //     _drawDai(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_REPAY_DAI) {
        //     _repayDai(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_WITHDRAW_COLLATERAL) {
        //     _withdrawCollateral(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else if (op == OP_CLOSE_CDP) {
        //     _closeCdp(addressHash, sourceAddress, params, tokenId, token, amount);
        // } else {
        //     revert InvalidOp(op);
        // }
    }

    function _openCdp(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        (bytes32 ilk) = abi.decode(params, (bytes32));
        
        // Validate token and ilk
        if (tokenIlks[token] != ilk) revert InvalidIlk(ilk);
        if (ilkTokenIds[ilk] != tokenId) revert InvalidTokenId(tokenId);
        
        // Check if user already has a CDP for this ilk
        if (userCdps[addressHash] != 0) revert CdpAlreadyExists(addressHash, userCdps[addressHash]);
        
        // Open new CDP
        uint256 cdpId = cdpManager.open(ilk, address(this));
        
        // Store mapping
        userCdps[addressHash] = cdpId;
        cdpOwners[cdpId] = addressHash;
        
        // Deposit collateral if amount > 0
        if (amount > 0) {
            _depositCollateralInternal(addressHash, cdpId, ilk, amount);
        }
        
        emit CdpOpened(sourceAddress, addressHash, cdpId, ilk);
    }

    function _depositCollateral(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        (bytes32 ilk) = abi.decode(params, (bytes32));
        
        // Validate token and ilk
        if (tokenIlks[token] != ilk) revert InvalidIlk(ilk);
        if (ilkTokenIds[ilk] != tokenId) revert InvalidTokenId(tokenId);
        
        uint256 cdpId = userCdps[addressHash];
        if (cdpId == 0) revert CdpNotOwned(addressHash, cdpId);
        
        _depositCollateralInternal(addressHash, cdpId, ilk, amount);
        
        emit CollateralDeposited(sourceAddress, addressHash, cdpId, amount);
    }

    function _depositCollateralInternal(
        bytes32 addressHash,
        uint256 cdpId,
        bytes32 ilk,
        uint256 amount
    ) internal {
        address join = collateralJoins[ilk];
        if (join == address(0)) revert InvalidIlk(ilk);
        
        // Transfer tokens to join contract
        address token = collateralTokens[ilk];
        if (!ERC20(token).transfer(join, amount)) {
            revert TransferFailed(token, address(this), join, amount);
        }
        
        // Join collateral into vat
        JoinLike(join).join(address(this), amount);
        
        // Add collateral to CDP
        cdpManager.frob(cdpId, int(amount), 0);
    }

    function _drawDai(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        // Validate DAI token
        if (tokenId != daiTokenId) revert InvalidTokenId(tokenId);
        
        uint256 cdpId = userCdps[addressHash];
        if (cdpId == 0) revert CdpNotOwned(addressHash, cdpId);
        
        // Draw DAI from CDP
        cdpManager.frob(cdpId, 0, int(amount));
        
        // Move DAI to this contract
        cdpManager.move(cdpId, address(this), amount);
        
        // Exit DAI from vat
        daiJoin.exit(address(this), amount);
        
        // Transfer DAI back to source chain
        _transferToSource(sourceAddress, token, amount);
        
        emit DaiDrawn(sourceAddress, addressHash, cdpId, amount);
    }

    function _repayDai(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        // Validate DAI token
        if (tokenId != daiTokenId) revert InvalidTokenId(tokenId);
        
        uint256 cdpId = userCdps[addressHash];
        if (cdpId == 0) revert CdpNotOwned(addressHash, cdpId);
        
        // Join DAI into vat
        daiJoin.join(address(this), amount);
        
        // Repay DAI debt
        cdpManager.frob(cdpId, 0, -int(amount));
        
        emit DaiRepaid(sourceAddress, addressHash, cdpId, amount);
    }

    function _withdrawCollateral(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        (bytes32 ilk) = abi.decode(params, (bytes32));
        
        // Validate token and ilk
        if (tokenIlks[token] != ilk) revert InvalidIlk(ilk);
        if (ilkTokenIds[ilk] != tokenId) revert InvalidTokenId(tokenId);
        
        uint256 cdpId = userCdps[addressHash];
        if (cdpId == 0) revert CdpNotOwned(addressHash, cdpId);
        
        // Check collateral balance
        (uint256 ink, uint256 art) = vat.urns(ilk, cdpManager.urns(cdpId));
        if (ink < amount) revert InsufficientCollateral(addressHash, cdpId, amount, ink);
        
        // Remove collateral from CDP
        cdpManager.frob(cdpId, -int(amount), 0);
        
        // Exit collateral from vat
        address join = collateralJoins[ilk];
        JoinLike(join).exit(address(this), amount);
        
        // Transfer collateral back to source chain
        _transferToSource(sourceAddress, token, amount);
        
        emit CollateralWithdrawn(sourceAddress, addressHash, cdpId, amount);
    }

    function _closeCdp(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        uint256 cdpId = userCdps[addressHash];
        if (cdpId == 0) revert CdpNotOwned(addressHash, cdpId);
        
        bytes32 ilk = cdpManager.ilks(cdpId);
        
        // Get current position
        (uint256 ink, uint256 art) = vat.urns(ilk, cdpManager.urns(cdpId));
        
        // If there's debt, it must be fully repaid
        if (art > 0) {
            if (tokenId != daiTokenId) revert InvalidTokenId(tokenId);
            
            // Join DAI to repay debt
            daiJoin.join(address(this), art);
            
            // Repay all debt
            cdpManager.frob(cdpId, 0, -int(art));
        }
        
        // Withdraw all collateral
        if (ink > 0) {
            // Remove all collateral from CDP
            cdpManager.frob(cdpId, -int(ink), 0);
            
            // Exit collateral from vat
            address join = collateralJoins[ilk];
            JoinLike(join).exit(address(this), ink);
            
            // Transfer collateral back to source chain
            address collateralToken = collateralTokens[ilk];
            _transferToSource(sourceAddress, collateralToken, ink);
        }
        
        // Clear mappings
        delete userCdps[addressHash];
        delete cdpOwners[cdpId];
        
        emit CdpClosed(sourceAddress, addressHash, cdpId);
    }

    function _transferToSource(
        bytes calldata sourceAddress,
        address token,
        uint256 amount
    ) internal {
        // Take gas from the relayer
        // bool success = ERC20(token).transferFrom(
        //     msg.sender,
        //     address(this),
        //     1 ether // 1 token for axelar gas
        // );
        
        // if (!success) {
        //     revert TransferFailed(token, msg.sender, address(this), 1 ether);
        // }
        
        // Get token ID for this token
        bytes32 tokenId = _getTokenId(token);
        
        // Transfer back to source chain
        InterchainTokenService(interchainTokenService).interchainTransfer(
            tokenId,
            XRPL_AXELAR_CHAIN_ID,
            sourceAddress,
            amount,
            "",
            1 ether // 1 token for gas
        );
    }

    function _depositAndSwap(
        bytes32 addressHash,
        bytes calldata sourceAddress,
        bytes memory params,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal {
        (bytes32 ilk, uint256 daiToDraw) = abi.decode(params, (bytes32, uint256));
        
        // Validate token and ilk
        if (tokenIlks[token] != ilk) revert InvalidIlk(ilk);
        if (ilkTokenIds[ilk] != tokenId) revert InvalidTokenId(tokenId);
        
        uint256 cdpId = userCdps[addressHash];
        bool isNewCdp = false;
        
        // Open CDP if it doesn't exist
        if (cdpId == 0) {
            cdpId = cdpManager.open(ilk, address(this));
            userCdps[addressHash] = cdpId;
            cdpOwners[cdpId] = addressHash;
            isNewCdp = true;
        }
        
        // Step 1: Deposit XRP collateral
        _depositCollateralInternal(addressHash, cdpId, ilk, amount);
        
        // Step 2: Draw DAI
        cdpManager.frob(cdpId, 0, int(daiToDraw));
        cdpManager.move(cdpId, address(this), daiToDraw);
        daiJoin.exit(address(this), daiToDraw);
        
        // Step 3: Swap DAI to USDC via PSM
        uint256 usdcAmount = _swapDaiToUsdc(daiToDraw);
        
        // Step 4: Transfer USDC back to source chain
        _transferToSource(sourceAddress, usdcToken, usdcAmount);
        
        emit DepositAndSwap(sourceAddress, addressHash, cdpId, amount, daiToDraw, usdcAmount);
        
        if (isNewCdp) {
            emit CdpOpened(sourceAddress, addressHash, cdpId, ilk);
        }
    }

    function _swapDaiToUsdc(uint256 daiAmount) internal returns (uint256) {
        // Approve PSM to spend DAI
        ERC20(daiToken).approve(address(psm), daiAmount);
        
        // Swap DAI to USDC via PSM
        psm.buyGem(address(this), daiAmount);
        
        // Get USDC balance
        uint256 usdcBalance = ERC20(usdcToken).balanceOf(address(this));
        
        return usdcBalance;
    }

    function _getTokenId(address token) internal view returns (bytes32) {
        if (token == daiToken) return daiTokenId; // DAI
        
        bytes32 ilk = tokenIlks[token];
        return ilkTokenIds[ilk];
    }

    // Admin functions
    function setCollateralConfig(
        bytes32 ilk,
        address token,
        address join,
        bytes32 tokenId
    ) external onlyAdmin {
        collateralTokens[ilk] = token;
        collateralJoins[ilk] = join;
        tokenIlks[token] = ilk;
        ilkTokenIds[ilk] = tokenId;
    }

    function setDaiTokenId(bytes32 _daiTokenId) external onlyAdmin {
        daiTokenId = _daiTokenId;
    }

    function setDaiToken(address _daiToken) external onlyAdmin {
        if (_daiToken == address(0)) revert InvalidCdpId(0);
        daiToken = _daiToken;
    }


    function setPsm(address _psm, address _usdcToken) external onlyAdmin {
        if (_psm == address(0)) revert InvalidCdpId(0);
        if (_usdcToken == address(0)) revert InvalidCdpId(0);
        psm = PsmLike(_psm);
        usdcToken = _usdcToken;
    }

    // View functions
    function getUserCdp(bytes32 addressHash) external view returns (uint256) {
        return userCdps[addressHash];
    }

    function getCdpOwner(uint256 cdpId) external view returns (bytes32) {
        return cdpOwners[cdpId];
    }

    function getCdpPosition(uint256 cdpId) external view returns (uint256 ink, uint256 art) {
        bytes32 ilk = cdpManager.ilks(cdpId);
        address urn = cdpManager.urns(cdpId);
        return vat.urns(ilk, urn);
    }

    function _debugLog(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount,
        bytes32 addressHash
    ) internal {
        emit DebugLog(commandId, sourceChain, sourceAddress, data, tokenId, token, amount, addressHash);
    }

    // Helper function for simple operation decode (like the working example)
    function decodeOperationOnly(bytes calldata data) external pure returns (bytes32 op) {
        return abi.decode(data, (bytes32));
    }

    // Helper function for complex decoding (needed for try-catch)
    function decodeOperationData(bytes calldata data) external pure returns (bytes32 op, bytes memory params) {
        return abi.decode(data, (bytes32, bytes));
    }

    // Alternative decode function to test different approaches
    function decodeOperationDataAlt(bytes calldata data) external pure returns (bytes32 op, bytes memory params) {
        // Try manual decoding
        require(data.length >= 64, "Data too short");
        
        // First 32 bytes is the operation
        assembly {
            op := calldataload(0x04)
        }
        
        // Next 32 bytes is offset to params
        uint256 paramsOffset;
        assembly {
            paramsOffset := calldataload(0x24)
        }
        
        // Get params length
        uint256 paramsLength;
        assembly {
            paramsLength := calldataload(add(0x04, paramsOffset))
        }
        
        // Extract params
        params = data[paramsOffset + 32:paramsOffset + 32 + paramsLength];
        
        return (op, params);
    }
}
