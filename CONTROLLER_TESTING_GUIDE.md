# Controller Testing Guide

This guide shows you how to test the Controller functions without going through the InterchainTokenService.

## Available Test Scripts

### 1. Data Encoding Test (`TestControllerDataEncoding.s.sol`)
This script shows you how to encode data for each Controller operation and provides the hex strings you can use as XRPL memos.

**Run with:**
```bash
forge script script/TestControllerDataEncoding.s.sol:TestControllerDataEncoding
```

### 2. Simple Calldata Test (`simple_calldata.sol`)
This script generates hex-encoded data for the `deposit_and_swap` operation specifically.

**Run with:**
```bash
forge script scripts/simple_calldata.sol:SimpleCalldata
```

## Controller Operations

The Controller supports these operations:

### 1. Open CDP
- **Operation**: `open_cdp`
- **Parameters**: `ilk` (collateral type)
- **Purpose**: Opens a new CDP for a user
- **Example**: Open CDP for USDC-A collateral

### 2. Deposit Collateral
- **Operation**: `deposit_collateral`
- **Parameters**: `ilk` (collateral type)
- **Purpose**: Deposits collateral into an existing CDP
- **Example**: Deposit USDC into USDC-A CDP

### 3. Draw DAI
- **Operation**: `draw_dai`
- **Parameters**: None (empty)
- **Purpose**: Draws DAI from an existing CDP
- **Example**: Draw 100 DAI from CDP

### 4. Repay DAI
- **Operation**: `repay_dai`
- **Parameters**: None (empty)
- **Purpose**: Repays DAI debt to an existing CDP
- **Example**: Repay 50 DAI to CDP

### 5. Withdraw Collateral
- **Operation**: `withdraw_collateral`
- **Parameters**: `ilk` (collateral type)
- **Purpose**: Withdraws collateral from an existing CDP
- **Example**: Withdraw USDC from USDC-A CDP

### 6. Close CDP
- **Operation**: `close_cdp`
- **Parameters**: None (empty)
- **Purpose**: Closes an existing CDP (repays all debt, withdraws all collateral)
- **Example**: Close CDP completely

### 7. Deposit and Swap
- **Operation**: `deposit_and_swap`
- **Parameters**: `ilk` (collateral type), `daiToDraw` (amount of DAI to draw)
- **Purpose**: Deposits collateral, draws DAI, swaps DAI to USDC via PSM
- **Example**: Deposit XRP, draw 1 DAI, swap to USDC

## How to Test Functions Directly

Since the Controller functions are internal and protected by the InterchainTokenService, you have a few options:

### Option 1: Use the Data Encoding Script
The `TestControllerDataEncoding.s.sol` script shows you exactly how to encode data for each operation. Use these hex strings as XRPL memos to trigger the functions.

### Option 2: Create a Test Contract
You can create a test contract that inherits from Controller and exposes the internal functions:

```solidity
contract TestableController is Controller {
    constructor(...) Controller(...) {}
    
    function testExecuteWithInterchainToken(...) external {
        _executeWithInterchainToken(...);
    }
}
```

### Option 3: Use Foundry Tests
Create proper Foundry tests that deploy the Controller and test each function:

```solidity
contract ControllerTest is Test {
    Controller controller;
    
    function setUp() public {
        // Deploy and configure controller
    }
    
    function testOpenCdp() public {
        // Test open CDP functionality
    }
}
```

## Data Format

Each operation follows this format:
```
abi.encode(operationHash, abi.encode(parameters))
```

Where:
- `operationHash` = `keccak256("operation_name")`
- `parameters` = encoded parameters specific to the operation

## Example Usage

For a `deposit_and_swap` operation with USDC-A collateral and 1 DAI to draw:

```solidity
bytes32 ilk = "USDC-A";
uint256 daiToDraw = 1 * 10**18;
bytes memory params = abi.encode(ilk, daiToDraw);
bytes memory data = abi.encode(OP_DEPOSIT_AND_SWAP, params);
```

The resulting hex string can be used as an XRPL memo to trigger the operation.

## Testing with Real Contracts

To test with real deployed contracts:

1. Deploy all dependencies (DSS, CDP Manager, PSM, etc.)
2. Deploy the Controller
3. Configure the Controller with proper addresses
4. Use the hex-encoded data as XRPL memos
5. Monitor events to verify operations

## Event Monitoring

The Controller emits events for each operation:
- `CdpOpened`
- `CollateralDeposited`
- `DaiDrawn`
- `DaiRepaid`
- `CollateralWithdrawn`
- `CdpClosed`
- `DepositAndSwap`

Monitor these events to verify that operations are working correctly.
